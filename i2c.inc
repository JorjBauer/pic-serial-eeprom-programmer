;;; I2C routines.
;;;
;;; These macros/functions (written for the ds1307) work on an 8MHz
;;; clock without problems. It's not clear whether they will have
;;; problems or not at a higher clock speed, but certainly they'll
;;; work slower without issues. See ds1307-i2c.asm for sample usage.
;;; -- Jorj, 3/12/2009
;;;
;;; These must be defined by the caller:
;;;   SCL <port>,<pin>
;;;   SDA <port>, <pin>
;;;   SCLTRIS <trisname>, <pin>
;;;   SDATRIS <trisname>, <pin>
;;; and these must be variables defined and allocated by the caller:
;;;   I2CTMP
;;;   I2CCOUNT
;;;   I2C_TIMER_1

;;; Note 6/2/2009: This code uses this macro to delay at critical times. 
;;; It's not clear how much of a delay is req'd, but this delay is good enough
;;; to defeat the capacitance of two devices on the bus when using a 20MHz
;;; pic. It's also not clear which calls to this must stay and which are 
;;; overkill. Some day, perform analysis and find out?

I2CDELAY	MACRO
#if 0
	clrf	I2C_TIMER_1
	incfsz	I2C_TIMER_1, F
	goto	$-1
#else
	nop
	nop
#endif
	ENDM

SET_BANK0       MACRO
        bcf     STATUS, RP0
        bcf     STATUS, RP1
        ENDM

SET_BANK1       MACRO
        bsf     STATUS, RP0
        bcf     STATUS, RP1
        ENDM

I2C_START       MACRO
	SET_BANK1
	bsf	SCLTRIS ; input. let it float high
	bsf	SDATRIS	; input. let it float high
	SET_BANK0
	btfsc	SCL	; bus is clear if SCL and SDA are both high.
	btfss	SDA
	goto	$-2	; ... one or the other is low; loop & wait.

	;; assert both SCL and SDA as low. Make outputs, then set value
	SET_BANK1
	bcf	SDATRIS
	SET_BANK0
	bcf	SDA

	I2CDELAY

	SET_BANK1
	bcf	SCLTRIS
	SET_BANK0
	bcf	SCL

        ENDM

I2C_STOP        MACRO           ;assumes SCL high on entry
        bcf     SDA
        ;;nop
        ;;nop
	I2CDELAY
        SET_BANK1
        bsf     SCLTRIS
        SET_BANK0
        bsf     SDA
        ENDM

;; --- Write the byte in W to I2C device ---
;; ---- assumes that SCL is asserted low ----
;; ---- assumes that SDA is asserted low ----
write_I2C:
	movwf	I2CTMP		;Save the data
;;
;; --- Do a I2C bus write of byte in 'I2CTMP' ---
;;
write_I2C_byte:
	movlw	08h		; send 8 bits
	movwf	I2CCOUNT

I2C_w_loop:
	bcf	SDA		; assume data out is low
	rlf	I2CTMP, F	; shift data left into C
	btfsc	STATUS, C
	bsf	SDA		; if data out (C) = 1, set bit

	I2CDELAY

	SET_BANK1
	bsf	SCLTRIS	; SCL is now an input (float high)
	SET_BANK0
	btfss	SCL	; wait until clock goes high
	goto	$-1

	SET_BANK1
	bcf	SCLTRIS	; set back to an output
	SET_BANK0
	bcf	SCL	; and assert low

	decfsz	I2CCOUNT, F
	goto	I2C_w_loop

	; done writing 8 bits. Wait for bus to agree with our state...
	SET_BANK1
	bsf	SDATRIS	; set as an input (float high)
	bsf	SCLTRIS	; set as an input (float high)
	SET_BANK0
	btfss	SCL
	goto	$-1	; wait until it floats

	I2CDELAY
	
	SET_BANK1
	bcf	SDATRIS	; set as an output
	bcf	SCLTRIS	; set as an output
	SET_BANK0
	bcf	SCL
	bcf	SDA

	return

	;; ---- Read I2C into W  ----
read_I2C:
	SET_BANK1
	bsf	SDATRIS
	SET_BANK0

	movlw	08h		; send 8 bits
	movwf	I2CCOUNT

	bcf	SCL		; clock data out
	SET_BANK1
	bcf	SCLTRIS
	SET_BANK0

	clrf	I2CTMP		; clear var
	rlf	I2CTMP, 1		; rotate carry in
	clrf	I2CTMP		; clear var again

I2C_read_loop:
	rlf	I2CTMP, 1

	SET_BANK1
	bsf	SCLTRIS
	SET_BANK0

	btfsc	SDA
	bsf	I2CTMP, 0		; if data out = 1, set bit

	bcf	SCL
	SET_BANK1
	bcf	SCLTRIS
	SET_BANK0
	decfsz	I2CCOUNT, 1
	goto	I2C_read_loop

	movf	I2CTMP, W
	return

;; ---- ACK read (assumes SCL=0 on entry) ----
ack:
	bcf		SDA

	SET_BANK1
	bcf	SDATRIS
	SET_BANK0

	I2CDELAY
	
	SET_BANK1
	bsf	SCLTRIS
	SET_BANK0
	;;nop
	I2CDELAY
	bcf	SCL
	SET_BANK1
	bcf	SCLTRIS
	SET_BANK0

	return

;; ---- NACK read (assumes SCL = 0 on entry) ----
nack:
	bsf	SDA

	SET_BANK1
	bcf	SDATRIS
	SET_BANK0

	I2CDELAY
	
	SET_BANK1
	bsf	SCLTRIS
	SET_BANK0

	I2CDELAY
	
	bcf	SCL
	SET_BANK1
	bcf	SCLTRIS
	SET_BANK0

	return
	