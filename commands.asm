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
;;; * R <low_size> <high_size> : Read <size> bytes in one burst.
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
	;; leave the result in 'W'

	call	i2c_read_byte	; W = i2c_read_byte(arg1[low], W[high])
	movwf	temp2

	movlw	'1'
	call	putch_usart	; print '1' for success
	movfw	temp2
	call	putch_usart	; print the data byte from the eeprom
	
	return

;;; ************************************************************************
;;; * handle_read_all
;;; *
;;; * called in response to a '>R' command. Read in the two bytes of size,
;;; * and print out that many bytes (starting at address 0). Note that sizes
;;; * of 0 or larger than the EEPROM are invalid, and will generate
;;; * unexpected (and undefined) results.
;;; *
;;; ************************************************************************

handle_read_all:
	movlw	'R'
	call	putch_usart

	call	getch_usart
	movwf	temp2		; low byte count
	call	getch_usart
	movwf	temp3		; high byte count

	;; read the first byte. It's special, as we have to set the address
	;; counter using a different call than the rest of the work we're
	;; about to perform.

	clrf	arg1
	movlw	0x00
	call	i2c_read_byte
	call	putch_usart

redo:	
	decfsz	temp2, F
	goto	readnext_1
	decfsz	temp3, F
	goto	readnext_1
	return

readnext_1:
	call	i2c_read_next_byte
	call	putch_usart
	goto	redo


	
handle_test:
	movlw	't'
	call	putch_usart

	movlw	0xFF
	movwf	temp3

keep_testing:	
	clrf	arg1
	movfw	temp3
	movwf	arg2
	call	i2c_write_byte	; address 0x00 0x(temp3) = temp3

	movfw	temp3
	movwf	arg1
	movlw	0x00
	call	i2c_read_byte	; address 0x00 0x(temp3)
	xorwf	temp3, W
	skpz
	goto	test_fail

	decfsz	temp3, F
	goto	keep_testing
	
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
	;; leave the value in 'W'

	call	i2c_write_byte	; i2c_write_byte( arg1[high], arg2[low], W )

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
	xorlw	'R'
	skpnz
	goto	handle_read_all


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
	