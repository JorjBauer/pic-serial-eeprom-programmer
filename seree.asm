        include         "processor_def.inc"

	include		"common.inc"
	include		"globals.inc"
	include		"delay.inc"

	GLOBAL	seree_init
	GLOBAL	seree_write_byte
	GLOBAL	seree_read_byte
	GLOBAL	seree_read_next_byte
	
;;; ************************************************************************
	udata
count		res	1
ee_data		res	1
addr_high	res	1
addr_low	res	1
I2CCOUNT	res	1
I2CTMP		res	1
I2C_TIMER_1	res	1
	
;;; ************************************************************************
	code

#define SCL PORTB, 4
#define SDA PORTB, 5
#define SCLTRIS TRISB, 4
#define SDATRIS	TRISB, 5
	
	include		"i2c.inc"

seree_init:
	movlw   0xFA	; 500mS for I2C gear to stabilize
	call    delay_ms
	movlw   0xFA
	call    delay_ms
	return
	
;;; ************************************************************************
;;; * seree_write_byte
;;; *
;;; * Input:
;;; *   W	data to write
;;; *	arg1	high byte of address
;;; *	arg2	low byte of address
;;; *
;;; ************************************************************************

;;; * From the 24LC256 documentation, this is a section 6.1 "Byte Write".
;;; * Quote:
;;; *   Following the start condition from the master, the control
;;; *   code (four bits), the Chip Select (three bits) and the R/W bit
;;; *   (which is a logic low) are clocked onto the bug by the master
;;; *   transmitter. This indicates to the addressed slave receiver
;;; *   that the address high byte will follow after it has generated an
;;; *   Acknowledge bit during the ninth clock cycle. Therefore, the next
;;; *   byte transmitted by the master is the high-order byte of the word
;;; *   address and will be written into the Address Pointer of the 24XX256.
;;; *   The next byte is the Least Significant Address Byte. After receiving
;;; *   another Acknowledge signal from the 24XX256, the master device
;;; *   will transmit the data word to be written into the addressed memory
;;; *   location. This initiates the internal write cycle and during this
;;; *   time, the 24XX256 will not generate Acknowledge signals. If an
;;; *   attempt is made to write to the array with the WP pin held high, the
;;; *   device will acknowledge the command but no write cycle will occur,
;;; *   no data will be written, and the device will immediately accept a
;;; *   new command. After a byte Write command, the internal address counter
;;; *   will point to the address location following the one that was just
;;; *   written.
	
seree_write_byte:
	movwf	ee_data		; save W
	movfw	arg1
	movwf	addr_high
	movfw	arg2
	movwf	addr_low

_retry_write:	
	call	i2c_start
	movlw	0xA0		; %1010xxxy I2C device address (xxx == id)
	call	write_I2C
	btfsc	OPTION_REG, Z	; did it NAK?
	goto	_retry_write	; yes, NAK - loop
	movfw	addr_high
	call	write_I2C
	movfw	addr_low
	call	write_I2C
	movfw	ee_data
	call	write_I2C
	call	i2c_stop

	return

;;; ************************************************************************
;;; * seree_read_byte
;;; *
;;; * Input:
;;; *	W	high byte of address
;;; *	arg1	low byte of address
;;; *
;;; * Output:
;;; *   W	data read
;;; *
;;; ************************************************************************

;;; * From the 24LC256 documentation, this is a section 8.2, "Random Read".
;;; * Quote:

;;; *   Random read operations allow the master to access any memory
;;; *   location in a random manner. To perform this type of read
;;; *   operation, the word address must first be set. This is done by
;;; *   sending the word address to the 24XX256 as part of a write
;;; *   operation (R/W bit set to '0'). Once the word address is sent,
;;; *   the master generates a Start condition following the
;;; *   acknowledge. This terminates the write operation, but not
;;; *   before the internal Address Pointer is set. The master then
;;; *   issues the control byte again, but with the R/W bit set to a
;;; *   one. The 24XX256 will then issue an acknowledge and transmit
;;; *   the 8-bit data word. The master will not acknowledge the
;;; *   transfer, though it does generate a Stop condition, which
;;; *   causes the 24XX256 to discontinue transmission. After a random
;;; *   Read command, the internal address counter will point to the
;;; *   address location following the one that was just read.

	
seree_read_byte:

	movwf	addr_high
	movfw	arg1
	movwf	addr_low


_retry_read:	
	call	i2c_start
	movlw	0xA0		; %1010xxxy I2C address (xxx == id)
	call	write_I2C
	btfsc	OPTION_REG, Z	; did it NAK?
	goto	_retry_read	; yes, NAK - loop
	
	movfw	addr_high
	call	write_I2C
	movfw	addr_low
	call	write_I2C

seree_read_next_byte:
	call	i2c_start
	movlw	0xA1		; %1010xxy I2C address (xxx == id)
	call	write_I2C
	call	read_I2C
	movwf	ee_data
	call	nack		; acknowledge that we're done reading via NAK
	call	i2c_stop

	movfw	ee_data

	return

;;; Support functions for I2C
i2c_start:
	I2C_START
	return

i2c_stop:
	I2C_STOP
	return
	
	END
