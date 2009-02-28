	Processor	16f627
	Radix		DEC
	EXPAND

	include		"p16f627.inc"
	include		"common.inc"
	include		"globals.inc"
	include		"delay.inc"

	GLOBAL	i2c_write_byte
	GLOBAL	i2c_read_byte

;;; ************************************************************************
	udata
count		res	1
ee_data		res	1
addr_high	res	1
addr_low	res	1
	
;;; ************************************************************************
	code
	
;;; ************************************************************************
;;; * i2c_on
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
i2c_on:
        ; wenn SDA und SCL beide High, dann SDA auf Low ziehen
        bsf     SCLo    ; failsave
        bsf     SDAo    ; failsave
        ;testen, ob der Bus frei ist
        btfsc   SCLi
        btfss   SDAi
        goto    i2c_on  ; Datenleitung frei?
        bcf     SDAo
        nop
        bcf     SCLo
        return

;;; ************************************************************************
;;; * wri2c
;;; *
;;; * Input:
;;; *   W	byte to write
;;; *
;;; * Destroys:	
;;; *   arg1, count
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
wri2c:
        ;schiebt das Byte aus W in den I2C
        ; MSB zuerst
        ; 78 Takte

        ; Takt unten, Daten unten
        ; Datenbyte in byte
        movwf   arg1
        movlw   8
        movwf   count  ; 8 Bits
WrI2cW1
        ; Datenleitung setzen
        bcf     SDAo
        rlf     arg1,f
        btfsc   STATUS,C       ; 0?
        bsf     SDAo    ; nein, 1
        nop
        bsf     SCLo    ; Taht high
WrI2cW2
        btfss   SCLi
        goto    WrI2cW2
        bcf     SCLo    ; Takt low
        decfsz  count,f        ; 8 Bits raus?
        goto    WrI2cW1 ; nein
	return
	
;;; ************************************************************************
;;; * i2c_tx
;;; *
;;; * Input:
;;; *   W	byte to write
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
i2c_tx:
	call	wri2c

	; ACK muﬂ nun empfangen werden
	; Takt ist low
	bsf     SDAo            ;Datenleitung loslassen
	bsf     SCLo            ; ACK Takt high
i2c_tx2
	btfss   SCLi
	goto    i2c_tx2
	nop
	bcf     SCLo            ; ja , Takt beenden
	bcf     SDAo
	return

;;; ************************************************************************
;;; * rdi2c
;;; *
;;; * Output:
;;; *   W	byte read
;;; *
;;; * Destroys:
;;; *   arg1, count
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
rdi2c:
        ;liest das Byte aus I2C nach W
        ; takt ist unten
        ; daten sind unten

        clrf    arg1
        movlw   8
        movwf   count
        bsf     SDAo            ;failsave
RdI2cW1
        nop
        bcf     STATUS, C
        btfsc   SDAi
        bsf     STATUS, C
        rlf     arg1,f
        bsf     SCLo            ; Takt high
RdI2cW2
        btfss   SCLi
        goto    RdI2cW2
        bcf     SCLo            ; Takt low
        decfsz  count,f         ; 8 Bits drinn?
        goto    RdI2cW1         ; nein

	nop

        movfw   arg1            ; ja fertig

	nop

	return	

;;; ************************************************************************
;;; * i2c_rx
;;; *
;;; * Output:
;;; *   W	byte read
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
i2c_rx:
	call	rdi2c
	
        ; Takt ist unten 
        ; kein ACK 
	bsf     SDAo 
	nop 
	bsf     SCLo
i2c_rx1 
	btfss   SCLi 
	goto    i2c_rx1 
	nop 
	bcf     SCLo
	bcf     SDAo 
	return

;;; ************************************************************************
;;; * i2c_off
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
i2c_off:	
	; SCL ist Low und SDA ist Low 
	nop 
	nop 
	bsf     SCLo
	nop 
	bsf     SDAo 
	return 

;;; ************************************************************************
;;; * i2c_reset
;;; *
;;; * Destroys:
;;; *   arg1
;;; *
;;; * VERIFIED OKAY -- jorj 9/11/04
;;; ************************************************************************
i2c_reset:
	bsf	SDAo
	bsf	SCLo
	nop
	movlw	9
	movwf	arg1
i2c_reset1
	nop
	bcf     SCLo
	nop
	nop
	nop
	nop
	nop
	bsf	SCLo
	nop
	decfsz	arg1, f
	goto	i2c_reset1
	nop

	call	i2c_on

	nop 
	bsf	SCLo 
	nop
	nop
	bcf	SCLo 
	nop

	goto	i2c_off

;;; ************************************************************************
;;; * i2c_write_byte
;;; *
;;; * Input:
;;; *   W	data to write
;;; *	arg1	high byte of address
;;; *	arg2	low byte of address
;;; *
;;; * mostly VERIFIED -- jorj 9/11/04 code is a little different but prolly ok
;;; ************************************************************************

i2c_write_byte:
	movwf	ee_data		; save W
	movfw	arg1
	movwf	addr_high
	movfw	arg2
	movwf	addr_low
	
	call	i2c_reset
	call	i2c_on
	
	movlw	0xA0
	call	i2c_tx

	movfw	addr_high
	call	i2c_tx

	movfw	addr_low
	call	i2c_tx

	movfw	ee_data
	call	i2c_tx

	call	i2c_off

	;; wait for clock line to come back up
	bsf	SCLo
i2c_write_loop:
	btfss	SCLo
	goto	i2c_write_loop

	;; short delay for things to stabilize
	movlw	0x03
	call	delay_ms

	return

;;; ************************************************************************
;;; * i2c_read_byte
;;; *
;;; * Input:
;;; *	W	high byte of address
;;; *	arg1	low byte of address
;;; *
;;; * Output:
;;; *   W	data read
;;; *
;;; * Mostly VERIFIED -- jorj 9/11/04 this is different, but might be okay
;;; ************************************************************************
i2c_read_byte:

	movwf	addr_high
	movfw	arg1
	movwf	addr_low

	nop
	nop
	nop
	nop
		
	call	i2c_reset
	call	i2c_on
	movlw	0xA0
	call	i2c_tx
	movfw	addr_high
	call	i2c_tx
	movfw	addr_low
	call	i2c_tx
	call	i2c_off

	call	i2c_on
	movlw	0xA1
	call	i2c_tx
	call	i2c_rx
	movwf	ee_data
	call	i2c_off

	movfw	ee_data

	;; wait for clock line to come back up
	bsf	SCLo
i2c_read_loop:
	btfss	SCLo
	goto	i2c_read_loop
	
	return
		
	END
