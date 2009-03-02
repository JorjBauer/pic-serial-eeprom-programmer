	Processor	16f627
	Radix		DEC
	EXPAND

	include		"p16f627.inc"
	include		"common.inc"
	include		"globals.inc"

	include		"i2c.inc"
	include		"serial.inc"
	include		"piceeprom.inc"

	include		"delay.inc"
	include		"commands.inc"

	__CONFIG ( _BODEN_ON & _CP_OFF & _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_OFF & _HS_OSC )

	;; 3FFF & 3FFF & 3FFF & 3FF7 & 3FFB & 3F7F & 3FDF & 3FEE
	
	
_ResetVector	set	0x00
_InitVector	set	0x04

;;; ************************************************************************
	udata

;;; ************************************************************************
	code

	ORG	_ResetVector
	goto	Main

	ORG	_InitVector
	retfie

;;; ************************************************************************
;;; * Main
;;; *
;;; * Main program. Sets up registers, handles main loop.
;;; ************************************************************************

Main:
	clrwdt
	clrf	INTCON		; turn off interrupts

	bcf	STATUS, RP1
	bsf	STATUS, RP0	; set up page 1 registers
	bsf	OPTION_REG, NOT_RBPU
	movlw	TRISA_DATA	; set up input/output pins appropriately
	movwf	TRISA
	movlw	TRISB_DATA
	movwf	TRISB

	bcf	STATUS, RP0	; set up the page 0 registers
	movlw	0x07
	movwf	CMCON
	clrf	PORTA
	clrf	PORTB

	bcf	STATUS, IRP	; indirect addressing to page 0/1, not 2/3

	;; fixme: move this to the i2c init routine
	movlw	0xFA		; 500mS for I2C gear to stabilize
	call	delay_ms
	movlw	0xFA
	call	delay_ms

	banksel	PORTA

	;; initialization of subsystems
	call	init_commands
	call	init_serial

	;; previous projects had problems with the first few serial chars
	;; always being garbled. Send something to get the serial timing
	;; set up properly.
	movlw	0x0A
	call	putch_usart
	movlw	0x0D
	call	putch_usart
	movlw	0x0A
	call	putch_usart
	movlw	0x0D
	call	putch_usart
	movlw	'H'
	call	putch_usart
	movlw	'i'
	call	putch_usart
	movlw	0x0A
	call	putch_usart
	movlw	0x0D
	call	putch_usart
	movlw	0x0A
	call	putch_usart
	movlw	0x0D
	call	putch_usart

main_loop:
	call	getch_usart	; Look for input from the serial port
	
	xorlw	'>'		; Is it the start of a command?
	skpz
	goto	main_loop	; No, so loop.

	call	command_handler	; Go handle the command
	goto	main_loop	; and loop again
	

	END
	