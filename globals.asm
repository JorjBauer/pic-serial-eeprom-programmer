	Processor       16f627
	Radix           DEC
	EXPAND
	
	include         "p16f627.inc"
	
	GLOBAL  arg1
	GLOBAL  arg2
	GLOBAL  temp2
	GLOBAL	temp3

	GLOBAL  bits
	
;;; ; ************************************************************************
	udata
arg1    res     1
arg2    res     1

temp2   res     1
temp3	res	1
	
bits	res     1

	END
	