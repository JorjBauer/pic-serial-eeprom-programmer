	Processor	16f628
	Radix		DEC
	EXPAND

	include		"p16f628.inc"
	include		"common.inc"

	GLOBAL	delay_ms

;;; ************************************************************************
	udata
delay1	res	1
delay2	res	1
delay3	res	1
	
;;; ************************************************************************
	code
	
;;; ************************************************************************
;;; * delay_ms
;;; *
;;; * Input
;;; *	W:	contains number of milliseconds to delay
;;; *
;;; * This function is tuned for a 10MHz processor. Other speeds will
;;; * need to have the magic constants (0x04, 0xFB) tweaked.
;;; ************************************************************************

;;; Note 9/11/04: this is too slow by about 10%. Need to do the math to
;;; figure out why.
	
delay_ms:
	movwf	delay1
loop1:	
	movlw	0x04
	movwf	delay2
loop2:	
	movlw	0xFB
	movwf	delay3
loop3:
	decfsz	delay3, F
	goto	loop3

	decfsz	delay2, F
	goto	loop2

	decfsz	delay1, F
	goto	loop1

	return
	

	END
	