        include         "processor_def.inc"

        include         "common.inc"
	include		"globals.inc"

;;; ************************************************************************
;;; *
;;; * Serial code, version 0.3: 1/24/2010
;;; *
;;; * This code assumes that the serial data is being buffered and inverted.
;;; * If the serial data is directly connected to an RS232 line (unbuffered),
;;; * then the sense of the RX and TX bits will be reverse (and the code
;;; * will need to be changed).
;;; *
;;; * EXTERNAL REQUIREMENTS:
;;; *
;;; * These symbols need to be defined.
;;; *   #define USART_HIGHSPEED <0|1>
;;; *   #define USART_BAUD_INITIALIZER <constant>
;;; *   #define USART_TX_TRIS PORTB, 2
;;; *	#define USART_RX_TRIS PORTB, 1
;;; *   #define USART_ECHO <0|1>
;;; *
;;; * The symbols USART_HIGHSPEED and USART_BAUD_INITIALIZER need to be
;;; * calculated per the PIC's documentation. For the 16f627 series,
;;; * here are the calculations:
;;; *
;;; *  high-speed: <constant> = ( (clock_speed_in_hertz) / (16 * baud rate) ) - 1
;;; *   example: 10MHz, 4800 baud is:
;;; *            (10000000 / (16 * 4800)) - 1 = 129.2 (use 129)
;;; *  low-speed:  <constant> = ( (clock_speed_in_hertz) / (64 * baud rate) ) - 1
;;; *   example: 10MHz, 4800 baud is:
;;; *            (10000000 / (64 * 4800)) - 1 = 31.5 (try 31 or 32)
;;; *
;;; * The symbols USART_TX_TRIS and USART_RX_TRIS are specific to the PIC
;;; * you're targeting. The TX and RX pins specified above are for the
;;; * 16f627 and family.
;;; *
;;; Define USART_ECHO as 1 if you want characters to software-loopback to the 
;;; sender immediately after being received. Good for testing.
;;; ************************************************************************

	GLOBAL	init_serial
	GLOBAL	putch_usart
	GLOBAL	putch_hex_usart
	GLOBAL	getch_usart
	GLOBAL	getch_usart_timeout
	
;;; ************************************************************************
	udata
serial_work_tmp	res	1
serial_timeout_0	res	1
serial_timeout_1	res	1
serial_timeout_2	res	1

#if USART_ECHO
echo_buf	res	1
#endif
	
;;; ************************************************************************
	code

init_serial:
	bsf	STATUS, RP0	; move to page 1

	;; The USART requires that bits [21] of TRISB are enabled, or you'll
	;; get unpredictable results from it. Some PICs won't work at all,
	;; and others will look like they're working but fail unpredictably.
	bsf	USART_TX_TRIS
	bsf	USART_RX_TRIS

#if USART_HIGHSPEED
	bsf     TXSTA, BRGH ; high-speed mode if 'bsf'; low-speed for 'bcf'
#else
	bcf     TXSTA, BRGH ; low-speed
#endif
	movlw   USART_BAUD_INITIALIZER ; constant for baud speed

	bcf	TXSTA, CSRC	; unimportant
	bcf	TXSTA, TX9	; 8-bit
	bsf	TXSTA, TXEN	; enable transmit
	bcf	TXSTA, SYNC	; async mode
	bcf	TXSTA, TX9D	; (unused, but we'll clear it anyway)
	
	bcf	STATUS, RP0	; back to page 0

	bcf	RCSTA, RX9	; 8-bit mode
	bcf	RCSTA, SREN	; unused (in async mode)
	bsf	RCSTA, CREN	; receive enabled
	bcf	RCSTA, FERR	; clear framing error bit
	bcf	RCSTA, RX9D	; unused

	bsf	RCSTA, SPEN	; serial port enabled

	movfw	RCREG		; flush 3-deep buffer
	movfw	RCREG
	movfw	RCREG

	movlw	0x00
	movwf	TXREG		; transmit dummy char to start transmitter

	return
	
;;; ************************************************************************
;;; * putch_usart
;;; *
;;; * put a character on the serial usart.
;;; *
;;; * Input:
;;; *    W	byte to send
;;; *
;;; * FIXME: assumes 'byte' is in page 0, same as SERIALTX
;;; ************************************************************************
putch_usart:
	;; Check TRMT: is *everything* empty?
	bsf	STATUS, RP0
putch_block:	
	btfss	TXSTA, TRMT
	goto	putch_block
	bcf	STATUS, RP0
	
	;; Check TXIF: is TXREG empty (but not necessarily TSR)?
	btfss	PIR1, TXIF
	goto	putch_usart

	;; All clear. Now transmit.
		
	movwf	TXREG
	
	return

;;; ************************************************************************
;;; * getch_usart
;;; *
;;; * Block until a character is available from the USART. When a char is
;;; * received, echo it back out the usart.
;;; ************************************************************************
getch_usart:
 	btfsc	RCSTA, OERR	; check for overrun
 	goto	overrun

	btfss	PIR1, RCIF	; make sure there's data to receive
	goto	getch_usart	; loop if not

retry:	
        movfw	RCREG		; grab the received character

	;; check for framing errors
	btfsc	RCSTA, FERR
	goto	retry
	
#if USART_ECHO
	movwf	echo_buf	; save a copy
	call	putch_usart	; send a copy back out
	movfw	echo_buf	; restore the saved copy
#endif
	return

overrun	bcf	RCSTA, CREN	; Clear overrun. Documented procedure: clear
	movfw	RCREG		; CREN, then flush the fifo by reading three
	movfw	RCREG		; bytes (the size of the backing store), and
	movfw	RCREG		; then re-enable CREN.
	bsf	RCSTA, CREN
	goto	getch_usart	; retry

;;; ; ************************************************************************
;;; ; * getch_usart_timeout
;;; ; *
;;; ; * Wait about a second for a character from the USART. When a char is
;;; ; * received, echo it back out the usart. If nothing is received before
;;; ; * the timeout, we return 0. So the caller can't expect 0 as a valid
;;; ; * return character...
;;; ; ************************************************************************

getch_usart_timeout:
	banksel serial_timeout_0
	clrf    serial_timeout_0
	clrf    serial_timeout_1
	clrf    serial_timeout_2
	banksel 0
getch_usart_timeout_loop:
	btfsc   RCSTA, OERR ; check for overrun
	goto    overrun_timeout

;;;  increment timeout timer. If we roll over, we're done.
	banksel serial_timeout_0
	incfsz  serial_timeout_0, F
	goto    getch_usart_timeout_loop1
	incfsz  serial_timeout_1, F
	goto    getch_usart_timeout_loop1
	incf    serial_timeout_2, F
	movfw   serial_timeout_2
	banksel 0
	xorlw   0x02	; somewhere around a half second @ 20MHz
	skpnz
	retlw   0x00	; failed to rx in the allotted time

getch_usart_timeout_loop1:
	banksel 0
	btfss   PIR1, RCIF ; make sure there's data to receive
	goto    getch_usart_timeout_loop ; loop if not
	
	movfw   RCREG	; grab the received character
	
;;;  check for framing errors
	btfsc   RCSTA, FERR
	goto    getch_usart_timeout_loop

#if USART_ECHO
	movwf   echo_buf ; save a copy
	call    putch_usart ; send a copy back out
	movfw   echo_buf    ; restore the saved copy
#endif
	return
overrun_timeout:
	bcf     RCSTA, CREN ; Clear overrun. Documented procedure: clear
	movfw   RCREG	    ; CREN, then flush the fifo by reading three
	movfw   RCREG	    ; bytes (the size of the backing store), and
	movfw   RCREG	    ; then re-enable CREN.
	bsf     RCSTA, CREN
	goto    getch_usart_timeout_loop ; retry
	
;;; ************************************************************************
;;; * putch_hex_usart
;;; *
;;; * put the byte's value, in hex, on the serial usart.
;;; *
;;; * Input:
;;; *
;;; *   W       byte to send
;;; *
;;; * FIXME: assumes 'byte' is in page 0, same as SERIALTX
;;; ************************************************************************

putch_hex_usart:
	banksel serial_work_tmp
	movwf   serial_work_tmp
	swapf   serial_work_tmp, W
	banksel 0
	andlw   0x0F	; grab low 4 bits of serial_work_tmp
	sublw   0x09	; Is it > 9?
	skpwgt		;   ... yes, so skip the next line
	goto    send_under9 ; If so, go to send_under9
	sublw   0x09	    ; undo what we did
	addlw   'A' - 10    ; make it ascii
	goto    send_hex
	
send_under9:
	sublw   0x09	; undo what we did
	addlw   '0'	; make it ascii
send_hex:
	call	putch_usart

	banksel serial_work_tmp
	movfw   serial_work_tmp
	banksel 0
	andlw   0x0F
	sublw   0x09
	skpwgt
	goto    send_under9_2
	sublw   0x09	; undo what we did
	addlw   'A' - 10 ; make it ascii
	goto    putch_usart

send_under9_2:
	sublw   0x09	; undo what we did
	addlw   '0'	; make it ascii
	goto    putch_usart
	
	
	END
