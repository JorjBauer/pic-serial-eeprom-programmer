        Processor       16f627
        Radix           DEC
        EXPAND

;;; ************************************************************************
;;; * Command handler interface
;;; *
;;; * All commands are prefixed with a '>' character. The commands are:
;;; *
;;; * r <low_byte> <high_byte> : Read one byte of data from the serial EEPROM,
;;; *                            at the specified address. Print a '0' or '1'
;;; *                            to denote failure or success, followed by
;;; *                            the data byte itself.
;;; *
;;; * w <low_byte> <high_byte> <data> : write the byte <data> to the given
;;; *                                   address on the serial EEPROM. Will
;;; *                                   print a '0' or '1' to denote failure
;;; *                                   or success.
;;; *
;;; * t : test mode. Writes/reads (destructively). Prints "OK" or "FAIL".
;;; *
;;; ************************************************************************
	
        include         "p16f627.inc"
        include         "common.inc"
        include         "globals.inc"
	include		"i2c.inc"
	include		"serial.inc"

	GLOBAL	command_handler
	GLOBAL	init_commands

	code
	
;;; ************************************************************************
;;; * init_commands
;;; *
;;; * called once to initialize the state of the command handler.
;;; *
;;; ************************************************************************

init_commands:
	return

;;; ************************************************************************
;;; * handle_read
;;; *
;;; * called in response to a '>r' command. Read in the two bytes of address,
;;; * and print a '0' or '1' for failure/success, followed by the byte of
;;; * data read. The byte of data is arbitrary upon failure.
;;; *
;;; ************************************************************************

handle_read:
	movlw	'r'
	call	putch_usart
	
	call	getch_usart
	movwf	arg1
	call	getch_usart

	call	i2c_read_byte	; W = i2c_read_byte(arg1, W)
	movwf	temp2

	movlw	'1'
	call	putch_usart	; print '1' for success
	movwf	temp2
	call	putch_usart	; print the data byte from the eeprom
	
	return

handle_test:
	movlw	't'
	call	putch_usart

	clrf	arg1		; address low
	movlw	0x00		; address high
	call	i2c_read_byte
	movwf	temp2		; hang on to this one for later
	
	clrf	arg1		; address high
	clrf	arg2		; address low
	movlw	0x00		; data
	call	i2c_write_byte

	clrf	arg1		; address low
	movlw	0x00		; address high
	call	i2c_read_byte
	xorlw	0x00		; == 0x00?
	skpz
	goto test_fail

	clrf	arg1		; address high
	clrf	arg2		; address low
	movlw	0xFF		; data
	call	i2c_write_byte

	clrf	arg1		; address low
	movlw	0x00		; address high
	call	i2c_read_byte
	xorlw	0xFF		; == 0xFF?
	skpz
	goto test_fail

	;; put back the data we saw when we started. Note that this only
	;; happens if we saw success; if the self-test failed, we may have
	;; just corrupted memory location 0. Which is probably okay, given
	;; that we failed the self-test anyway!
	clrf	arg1		; address high
	clrf	arg2		; address low
	movfw	temp2		; data (saved from before)
	call	i2c_write_byte
	
test_ok:	
	movlw	'O'
	call	putch_usart
	movlw	'K'
	call	putch_usart
	return
test_fail:	
	movlw	'F'
	call	putch_usart
	movlw	'A'
	call	putch_usart
	movlw	'I'
	call	putch_usart
	movlw	'L'
	call	putch_usart
	return
	
;;; ************************************************************************
;;; * handle_write
;;; *
;;; * called in response to a '>w' command. Read in the two bytes of address,
;;; * and the one byte of data, and output a '0' or '1' for failure or
;;; * success.
;;; ************************************************************************

handle_write:
	movlw	'w'
	call	putch_usart

	
	call	getch_usart
	movwf	arg2
	call	getch_usart
	movwf	arg1
	call	getch_usart

	call	i2c_write_byte	; i2c_write_byte( arg1, arg2, W )

	movlw	'1'		; echo '1' for success
	call	putch_usart

	return
	
;;; ************************************************************************
;;; * command_handler
;;; *
;;; * called after we receive a '>' character.
;;; *
;;; ************************************************************************

command_handler:
	call	getch_usart	; see if it's a read or write command
	movwf	temp2
	xorlw	'r'		; read command?
	skpnz
	goto	handle_read

	movfw	temp2
	xorlw	'w'		; write command?
	skpnz
	goto	handle_write

	movfw	temp2
	xorlw	't'		; test command?
	skpnz
	goto	handle_test

	return			; no, so it's an unknown command. Bail.

	END
	