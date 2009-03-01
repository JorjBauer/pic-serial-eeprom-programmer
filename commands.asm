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
	call	getch_usart
	movwf	arg1
	call	getch_usart

	call	i2c_read_byte	; W = i2c_read_byte(arg1, W)
	movwf	temp1

	movlw	'1'
	call	putch_usart	; print '1' for success
	movwf	temp1
	call	putch_usart	; print the data byte from the eeprom
	
	return

;;; ************************************************************************
;;; * handle_write
;;; *
;;; * called in response to a '>w' command. Read in the two bytes of address,
;;; * and the one byte of data, and output a '0' or '1' for failure or
;;; * success.
;;; ************************************************************************

handle_write:
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
	movwf	temp1
	xorlw	'r'		; read command?
	skpz
	goto	not_read
	call	handle_read
	return

not_read:
	movfw	temp1
	xorlw	'w'		; write command?
	skpnz
	return			; no, so it's an unknown command. Bail.

	goto	handle_write
	
	END
	