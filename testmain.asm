        include         "processor_def.inc"

	include		"common.inc"
	include		"globals.inc"

	include		"seree.inc"
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
	movlw	0xFF		;debugging
	movwf	PORTA
	clrf	PORTB

	movlw 0xFF
loop:
	movwf	PORTA
	sublw	1
	goto loop
	

	END
	