	EXTERN	i2c_init

	;; i2c_write_byte: random access single-byte write
	;;    arg1: high byte addr
	;;    arg2: low byte addr
	;;    W: data to write
	EXTERN	i2c_write_byte

	;; i2c_read_byte: random access single-byte read
	;;    W: high byte of address
	;;    arg1: low byte of address
	;;    returns: W == byte read
	EXTERN	i2c_read_byte

	;; i2c_read_next_byte: read the byte after the previously read byte
	;;    returns: W == byte read
	EXTERN	i2c_read_next_byte
