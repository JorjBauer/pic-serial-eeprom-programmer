;;; I2C routines.
;;;
;;; These macros/functions were originally written for the DS1307 with an 
;;; 8MHz clock. They subsequently went to a 20MHz clock and a ds1307, and then 
;;; were backported to a 4MHz clock and serial EEProms. With the latest 
;;; revision, they support clock stretching appropriately and should be 
;;; generic enough that I2CDELAY needs to be tuned for fast clocks (but 
;;; nothing else).
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
;;; It's not clear how much of a delay is req'd, but the long version of
;;; this delay is good enough to defeat the capacitance of two devices
;;; on the bus when using a 20MHz pic.
;;; The short version of this (two 'nop' calls) is sufficient for the serial 
;;; eeproms that I have.

I2CDELAY	MACRO
#if 0
	clrf	I2C_TIMER_1
	incfsz	I2C_TIMER_1, F
	goto	$-1
#else
	nop
;;	nop
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
	btfss	SCL	; wait until clock goes high [honor clock stretching]
	goto	$-1

	SET_BANK1
	bcf	SCLTRIS	; set back to an output
	SET_BANK0
	bcf	SCL	; and assert low

	decfsz	I2CCOUNT, F
	goto	I2C_w_loop

	; done writing 8 bits. Read the ACK bit, and return in Z for the caller.

	SET_BANK1
	bsf	SDATRIS	; set as an input (float high)
	bsf	SCLTRIS	; set as an input (float high)
	SET_BANK0
	btfss	SCL
	goto	$-1	; wait until it floats

	I2CDELAY

	bcf	OPTION_REG, Z	; clear Z (assume NAK)
	btfsc	SDA
	bsf	OPTION_REG, Z	; set Z (it's ACK)
	
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
	bsf	SDATRIS		; input (float high)
	SET_BANK0

	movlw	08h		; send 8 bits
	movwf	I2CCOUNT

	bcf	SCL		; clock data out
	SET_BANK1
	bcf	SCLTRIS		; set as output
	SET_BANK0

	bcf	STATUS, C	; clear carry
	clrf	I2CTMP		; clear return value (which we'll now read)

I2C_read_loop:
	rlf	I2CTMP, F	; shift result left, and shift on a 0 from C

	SET_BANK1
	bsf	SCLTRIS		; float high
	SET_BANK0
	; wait for SCL to go high (client may be bit-stretching, holding low)
	btfss  SCL
	goto   $-1
	; Might need a delay here for fast processors?

	; now read in the bit
	btfsc	SDA
	bsf	I2CTMP, 0		; if data out = 1, set bit

	bcf	SCL			; assert SCL = 0
	SET_BANK1
	bcf	SCLTRIS			; SCL is an output
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
	