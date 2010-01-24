        include         "processor_def.inc"

	include		"common.inc"
	include		"globals.inc"

	include		"seree.inc"
	include		"serial.inc"
	include		"serbuf.inc"
	include		"piceeprom.inc"

	include		"delay.inc"
	include		"commands.inc"

	__CONFIG ( _BODEN_ON & _CP_OFF & _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_OFF & _INTRC_OSC_NOCLKOUT )
	;; _HS_OSC = 10MHz external ceramic resonator
	;; _INTRC_OSC_NOCLKOUT = 4MHz (nominal) internal oscillator
	
	;; 3FFF & 3FFF & 3FFF & 3FF7 & 3FFB & 3F7F & 3FDF & 3FEE
	
	
_ResetVector	set	0x00
_InitVector	set	0x04

;;; ************************************************************************
	udata
	
ptr	res	1		; memory pointer for welcome message

	udata_shr
save_w		res	1
save_status	res	1
save_pclath	res	1
save_fsr	res	1
	
;;; ************************************************************************
	code

	ORG	_ResetVector
	lgoto	Main

	ORG	_InitVector
	nop

	ORG	0x05
Interrupt:
;;; ; standard interrupt setup: save everything!
	movwf   save_w
	swapf   STATUS, W
	movwf   save_status
	bcf     STATUS, RP1
	bcf     STATUS, RP0
	movf    PCLATH, W
	movwf   save_pclath
	clrf    PCLATH
	movfw   FSR
	movwf   save_fsr
	
	SERBUF_INTERRUPT
	
;;;  clean up everything we saved...
	movfw   save_fsr
	movwf   FSR
	movf    save_pclath, W
	movwf   PCLATH
	swapf   save_status, W
	movwf   STATUS
	swapf   save_w, F
	swapf   save_w, W
	
	retfie

;;; ************************************************************************
;;; Lookup tables
;;; ************************************************************************

	org	0x40
welcome_msg2:
	addwf	PCL, F
	retlw	0x0A
	retlw	0x0D
	retlw	'>'
	retlw	'w'
	retlw	'X'
	retlw	'X'
	retlw	'Y'
	retlw	' '
	retlw	'w'
	retlw	'r'
	retlw	'i'
	retlw	't'
	retlw	'e'
	retlw	' '
	retlw	'v'
	retlw	'a'
	retlw	'l'
	retlw	'u'
	retlw	'e'
	retlw	' '
	retlw	'Y'
	retlw	' '
	retlw	'@'
	retlw	' '
	retlw	'a'
	retlw	'd'
	retlw	'd'
	retlw	'r'
	retlw	'e'
	retlw	's'
	retlw	's'
	retlw	' '
	retlw	'X'
	retlw	'X'
	retlw	0x0A
	retlw	0x0D
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	't'
	retlw	'u'
	retlw	'r'
	retlw	'n'
	retlw	's'
	retlw	' '
	retlw	'w'
	retlw	'1'
	retlw	' '
	retlw	'o'
	retlw	'n'
	retlw	' '
	retlw	's'
	retlw	'u'
	retlw	'c'
	retlw	'c'
	retlw	'e'
	retlw	's'
	retlw	's'
	retlw	0x0A
	retlw	0x0D
	retlw	'>'
	retlw	't'
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	'D'
	retlw	'E'
	retlw	'S'
	retlw	'T'
	retlw	'R'
	retlw	'U'
	retlw	'C'
	retlw	'T'
	retlw	'I'
	retlw	'V'
	retlw	'E'
	retlw	' '
	retlw	's'
	retlw	'e'
	retlw	'l'
	retlw	'f'
	retlw	'-'
	retlw	't'
	retlw	'e'
	retlw	's'
	retlw	't'
	retlw	0x0A
	retlw	0x0D
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	'e'
	retlw	'm'
	retlw	'i'
	retlw	't'
	retlw	's'
	retlw	' '
	retlw	'''
	retlw	'O'
	retlw	'K'
	retlw	'''
	retlw	' '
	retlw	'o'
	retlw	'n'
	retlw	' '
	retlw	's'
	retlw	'u'
	retlw	'c'
	retlw	'c'
	retlw	'e'
	retlw	's'
	retlw	's'
	retlw	' '
	retlw	'o'
	retlw	'r'
	retlw	' '
	retlw	'''
	retlw	'F'
	retlw	'A'
	retlw	'I'
	retlw	'L'
	retlw	'''
	retlw	' '
	retlw	'o'
	retlw	'n'
	retlw	' '
	retlw	'f'
	retlw	'a'
	retlw	'i'
	retlw	'l'
	retlw	'u'
	retlw	'r'
	retlw	'e'
	retlw	0x0A
	retlw	0x0D
	retlw	0x0A
	retlw	0x0D
	retlw	0

	org	0x100
welcome_msg:
	addwf	PCL, F
	retlw	0x0A
	retlw	0x0D
	retlw	0x0A
	retlw	0x0D
	retlw	'S'
	retlw	'e'
	retlw	'r'
	retlw	'E'
	retlw	'E'
	retlw	' '
	retlw	'v'
	retlw	'1'
	retlw	'.'
	retlw	'2'
	retlw	0x0A
	retlw	0x0D
	retlw	'C'
	retlw	'o'
	retlw	'm'
	retlw	'm'
	retlw	'a'
	retlw	'n'
	retlw	'd'
	retlw	's'
	retlw	':'
	retlw	0x0A
	retlw	0x0D
	retlw	'>'
	retlw	'r'
	retlw	'X'
	retlw	'X'
	retlw	' '
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	'a'
	retlw	'd'
	retlw	' '
	retlw	'1'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	' '
	retlw	'@'
	retlw	' '
	retlw	'a'
	retlw	'd'
	retlw	'd'
	retlw	'r'
	retlw	'e'
	retlw	's'
	retlw	's'
	retlw	' '
	retlw	'X'
	retlw	'X'
	retlw	' '
	retlw	'('
	retlw	'2'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	's'
	retlw	','
	retlw	' '
	retlw	'l'
	retlw	'i'
	retlw	't'
	retlw	't'
	retlw	'l'
	retlw	'e'
	retlw	'-'
	retlw	'e'
	retlw	'n'
	retlw	'd'
	retlw	'i'
	retlw	'a'
	retlw	'n'
	retlw	')'
	retlw	0x0A
	retlw	0x0D
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	't'
	retlw	'u'
	retlw	'r'
	retlw	'n'
	retlw	's'
	retlw	' '
	retlw	'r'
	retlw	'1'
	retlw	'Y'
	retlw	' '
	retlw	'o'
	retlw	'n'
	retlw	' '
	retlw	's'
	retlw	'u'
	retlw	'c'
	retlw	'c'
	retlw	'e'
	retlw	's'
	retlw	's'
	retlw	' '
	retlw	'('
	retlw	'Y'
	retlw	' '
	retlw	'i'
	retlw	's'
	retlw	' '
	retlw	'b'
	retlw	'i'
	retlw	'n'
	retlw	'a'
	retlw	'r'
	retlw	'y'
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	's'
	retlw	'u'
	retlw	'l'
	retlw	't'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	')'
	retlw	0x0A
	retlw	0x0D
	retlw	'>'
	retlw	'R'
	retlw	'X'
	retlw	'X'
	retlw	' '
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	'a'
	retlw	'd'
	retlw	' '
	retlw	'X'
	retlw	'X'
	retlw	' '
	retlw	'('
	retlw	'2'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	's'
	retlw	','
	retlw	' '
	retlw	'l'
	retlw	'i'
	retlw	't'
	retlw	't'
	retlw	'l'
	retlw	'e'
	retlw	'-'
	retlw	'e'
	retlw	'n'
	retlw	'd'
	retlw	'i'
	retlw	'a'
	retlw	'n'
	retlw	')'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	's'
	retlw	','
	retlw	' '
	retlw	's'
	retlw	't'
	retlw	'a'
	retlw	'r'
	retlw	't'
	retlw	'i'
	retlw	'n'
	retlw	'g'
	retlw	' '
	retlw	'@'
	retlw	' '
	retlw	'a'
	retlw	'd'
	retlw	'd'
	retlw	'r'
	retlw	' '
	retlw	'0'
	retlw	0x0A
	retlw	0x0D
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	' '
	retlw	'r'
	retlw	'e'
	retlw	't'
	retlw	'u'
	retlw	'r'
	retlw	'n'
	retlw	's'
	retlw	' '
	retlw	'a'
	retlw	' '
	retlw	'd'
	retlw	'u'
	retlw	'm'
	retlw	'p'
	retlw	' '
	retlw	'o'
	retlw	'f'
	retlw	' '
	retlw	'a'
	retlw	'l'
	retlw	'l'
	retlw	' '
	retlw	'b'
	retlw	'y'
	retlw	't'
	retlw	'e'
	retlw	's'
	retlw	0
	
;;; ************************************************************************
;;; * Main
;;; *
;;; * Main program. Sets up registers, handles main loop.
;;; ************************************************************************

Main:
	clrf	INTCON		; turn off interrupts

	bcf	STATUS, RP1
	bsf	STATUS, RP0	; set up page 1 registers
	
	bsf	PCON, 3		; for INTOSC, set speed to 4 MHz. Benign
				; in any other mode.
	
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

	banksel	PORTA

	;; initialization of subsystems
	call	seree_init
	call	init_serial
	SERBUF_INIT	
	call	init_commands

	;; previous projects had problems with the first few serial chars
	;; always being garbled. Send something to get the serial timing
	;; set up properly. And it's a nice welcome message to remind the user
	;; how to use the device.

	clrf	ptr
repeat_welcome:
	movlw	HIGH(welcome_msg)
	movwf	PCLATH
	movfw	ptr
	call	welcome_msg
	addlw	0
	skpnz
	goto	done_welcome
	lcall	putch_usart_buffered
	incfsz	ptr, F
	goto	repeat_welcome
done_welcome:

	clrf	ptr
repeat_welcome2:
	movlw	HIGH(welcome_msg2)
	movwf	PCLATH
	movfw	ptr
	call	welcome_msg2
	addlw	0
	skpnz
	goto	done_welcome2
	lcall	putch_usart_buffered
	incfsz	ptr, F
	goto	repeat_welcome2
done_welcome2:	

	movlw	'G'
	lcall	putch_usart_buffered
	movlw	'o'
	lcall	putch_usart_buffered
	movlw	0x0A
	lcall	putch_usart_buffered
	movlw	0x0D
	lcall	putch_usart_buffered
	
main_loop:
	call	getch_usart_buffered	; Look for input from the serial port
	
	xorlw	'>'		; Is it the start of a command?
	skpz
	goto	main_loop	; No, so loop.

	call	command_handler	; Go handle the command
	goto	main_loop	; and loop again
	

	END
	