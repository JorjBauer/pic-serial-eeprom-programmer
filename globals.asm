        include         "processor_def.inc"
	
	GLOBAL  arg1
	GLOBAL  arg2
	GLOBAL  temp2
	GLOBAL	temp3

	GLOBAL  bits
	
;;; ************************************************************************
;;; eat up the address space that's not in bank 0, so that nothing uses it.
;;; If we need it later we'll need to refactor a lot of code to appropriately
;;; select banks, so we don't want this used unless necessary...
.dummy1 udata   0x120
dummy1  res     48
.dummy2 udata   0xA0
dummy2  res     80

	
;;; ************************************************************************
;;; shared memory, accessible from all banks.
	udata_shr
arg1    res     1
arg2    res     1

temp2   res     1
temp3	res	1
	
bits	res     1

	END
	