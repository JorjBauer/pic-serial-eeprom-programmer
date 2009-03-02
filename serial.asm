        Processor       16f627
        Radix           DEC
        EXPAND

        include         "p16f627.inc"
        include         "common.inc"
	include		"globals.inc"
	include		"delay.inc"

#define ECHO 0
	
;;; ************************************************************************
;;; * This code assumes that the serial data is being buffered and inverted.
;;; * If the serial data is directly connected to an RS232 line (unbuffered),
;;; * then the sense of the RX and TX bits will be reverse (and the code
;;; * will need to be changed).
;;; *
;;; * This code also assumes that you're running a 10 MHz clock. If the
;;; * clock speed is different, you'll need to twiddle the magic constants
;;; * (0xAA) to delay the right amount of time between bits.
;;; *
;;; * Lastly, the bit-banging code is 4800 Baud, 8/N/1. The USART version is
;;; * 57600.
;;; ************************************************************************

	GLOBAL	init_serial
	GLOBAL	putch_usart
	GLOBAL	getch_usart
#if BITBANG_ENABLED
	GLOBAL	getch
	GLOBAL	getch_timeout
#endif
	
;;; ************************************************************************
	udata
loopcounter	res	1
byte		res	1
i		res	1

timeout		res	3
	
;;; ************************************************************************
	code

init_serial:
#if BITBANG_ENABLED
	bcf	bits, BIT_BITBANG_ACTIVITY
#endif
	
	bsf	STATUS, RP0	; move to page 1

	;; Desired baud rate = Fosc / (64 * (X + 1))
	;; e.g. 4800 = 10000000 / (64 * (X + 1))
	;;      2083.333 = 64X + 64
	;;      2019.333 = 64X
	;;      X = 31.55 (use 32)
	;; e.g. 57600 = 10000000 / (64 * (X + 1))
	;;      173.61111111111111111111 = 64X + 64
	;; 	109.61111111111111111111 = 64X
	;; 	X = 1.7126 (too much error)
	;; Others @ 10MHz:
	;;    4800: 31.55 (verified, 32 works)
	;;    9600: 15.28 (use 15; not tested)
	;;    19200: 7.14 (use 7; works)
	;;    38400: 3.07 (tried 3; not stable)
	;;    57600: 1.7126 (not tested, seems unlikely to work)
	
	movlw	0x07		; 'X', per above comments, to set baud rate
	movwf	SPBRG

	bcf	TXSTA, CSRC	; unimportant
	bcf	TXSTA, TX9	; 8-bit
	bsf	TXSTA, TXEN	; enable transmit
	bcf	TXSTA, SYNC	; async mode
	bcf	TXSTA, BRGH	; low-speed serial mode
	bcf	TXSTA, TX9D	; (unused, but we'll clear it anyway)
	
	bcf	STATUS, RP0	; back to page 0

	bcf	RCSTA, RX9	; 8-bit mode
	bcf	RCSTA, SREN	; unused (in async mode)
	bsf	RCSTA, CREN	; receive enabled
	bcf	RCSTA, FERR	; clear framing error bit
	bcf	RCSTA, RX9D	; unused

	bsf	RCSTA, SPEN	; serial port enabled

	;; Short delay for startup...
	movlw	0xFA
	call	delay_ms
	
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
	btfss	PIR1, TXIF
	goto	putch_usart	; wait for transmitter interrupt flag

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
#if BITBANG_ENABLED
	;; Test the bitbang interface. If the SERIALRX line is clear, then
	;; we've got activity and should note that for future reference.
	btfss	SERIALRX
	bsf	bits, BIT_BITBANG_ACTIVITY
#endif
	btfsc	RCSTA, OERR	; check for overrun
	goto	overrun

	btfss	PIR1, RCIF	; make sure there's data to receive
	goto	getch_usart	; loop if not

        movfw	RCREG		; grab the received character
#if ECHO
	movwf	serial_temp1	; save a copy
	call	putch_usart	; send a copy back out
	movfw	serial_temp1	; restore the saved copy
#endif
	return

overrun	bcf	RCSTA, CREN	; Clear overrun. Documented procedure: clear
	movfw	RCREG		; CREN, then flush the fifo by reading three
	movfw	RCREG		; bytes (the size of the backing store), and
	movfw	RCREG		; then re-enable CREN.
	bsf	RCSTA, CREN
	goto	getch_usart	; retry

;;; ************************************************************************
;;; * getch
;;; *
;;; * bit-banging receiver. Blocks until the char is received.
;;; *
;;; * Output:
;;; *    W	byte received
;;; *
;;; * Destroys:
;;; *    loopcounter, byte, i, arg1
;;; ************************************************************************

#if BITBANG_ENABLED

getch:
	goto	getch_loop_start

getch_loop:
	clrwdt
getch_loop_start:
	btfsc	SERIALRX
	goto	getch_loop

	nop
	CLRF	i
	MOVLW	0x14
	MOVWF	loopcounter
getch_wait1:			; initial delay; get past start bit
	DECFSZ	loopcounter, F
	goto	getch_wait1

	movlw	0x08
	movwf	byte
getch_get_bit:
	clrwdt
	movlw	0xAA
	movwf	loopcounter
	
getch_wait:
	decfsz	loopcounter, F	; this delay is 509 cycles, ~ .00020306 seconds
	goto	getch_wait
	
	bcf	STATUS, C
	nop
	RRF	i, F
	btfsc	SERIALRX
	bsf	i, 7
	nop
	DECFSZ	byte, F
	goto	getch_get_bit

getch_stopbit_loop:
	nop
	nop
	btfss	SERIALRX
	goto	getch_stopbit_loop

gotresult:	
	movfw	i		; move result into W
	bcf	bits, BIT_BITBANG_ACTIVITY ; turn off activity flag
	bcf	STATUS, C	; no error, so clear the carry and return
	bcf	STATUS, DC	; no framing error, so clear that too
	return

#endif

;;; ************************************************************************
;;; * getch_timeout
;;; *
;;; * bit-banging receiver. Does NOT block; will return with carry set
;;; * and 0 in W if nothing is received in about 6 seconds.
;;; *
;;; * Output:
;;; *    W	byte received
;;; *	 Carry set on failure
;;; *	 DC set on framing error
;;; *
;;; * Destroys:
;;; *    loopcounter, byte, i, arg1
;;; ************************************************************************

#if BITBANG_ENABLED

getch_timeout:
	bcf	bits, BIT_BITBANG_ACTIVITY ; clear the activity bit
	
	;; set up 3-byte timeout timer to provide about a 7-second wait.
	clrf	timeout+2
	clrf	timeout+1
	movlw	0xE0
	movwf	timeout+0
	goto	L07E1

L07E0:	clrwdt
L07E1:	bsf	STATUS, C	; assume error condition.
	bcf	STATUS, DC	; DC only set on framing error.
	
	btfss	SERIALRX
	goto	getbits

	incfsz	timeout+2, F	; incfsz does not affect any status registers
	goto	L07E0		; (not even Z!), so the state of the STATUS
	incfsz	timeout+1, F	; register that we set will carry through.
	goto	L07E0
	incfsz	timeout+0, F
	goto	L07E0
	retlw	0x00		; timeout (about 6.7 seconds). Carry still set.

getbits:
	nop
	CLRF	i
	MOVLW	0x14
	MOVWF	loopcounter
getch_t_wait1:			; initial delay; get past start bit
	DECFSZ	loopcounter, F
	goto	getch_t_wait1

	;; now check to see that the start bit is still there. We
	;; delayed about .0000252 seconds (which is about 1/10 of a bit at
	;; 4800 baud), so we should be in the window where it's still on.
	;; If it's not on, then we have a framing error; to keep our timer
	;; running, we'll just jump back into the timer loop above and wait
	;; for the start bit again.
	btfsc	SERIALRX
	goto	L07E0
	
	
	movlw	0x08
	movwf	byte
	
L07EC:
	clrwdt
	movlw	0xAA
	movwf	loopcounter
	
getch_t_wait:
	decfsz	loopcounter, F	; this delay is 509 cycles, ~ .00020306 seconds
	goto	getch_t_wait
	
	bcf	STATUS, C	; total delay of 3 + 169 * 3 + 2 + 9 cycles
	nop			; that's .0002084 seconds, which is damn
	RRF	i, F		; close to 1/4800 (.000208333) between label
	btfsc	SERIALRX	; L07EC and getch_t_get_stopbit
	bsf	i, 7
	nop
	DECFSZ	byte, F
	goto	L07EC

	;; look for the stop bit. If we don't find it by the time the
	;; stop bit should have arrived (that is, .000208333 seconds),
	;; then it's a framing error; return 0.
	;; The timing for this is 3 + 6 * 84 + 5 cycles. That's slightly
	;; longer than one bit-time for 4800 baud.

	;; Can't get this routine working! Going to try to remove this
	;; stopbit test in order to see if that makes a difference. In
	;; theory, this should be a benign change, since the only case where
	;; we get this far is when we have something seeming to be a pulse,
	;; followed by something looking like a start bit... (FIXME)

	;; That didn't do anything. Putting this back now, along with a
	;; loop around the start bit detection. Should time out after ~7 secs.

getch_t_get_stopbit:
	bsf	STATUS, C	; assume error condition
	bsf	STATUS, DC	; (and it will be a framing error)
	movlw	0x55
	movwf	loopcounter
getch_t_stopbit_loop:
	nop
	nop
	decf	loopcounter, F
	skpnz
	goto	L07E0		;	retlw	0x00
	btfss	SERIALRX
	goto	getch_t_stopbit_loop

	goto	gotresult	; same as the blocking version from here on
#endif
	
			
	END
