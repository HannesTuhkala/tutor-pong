COLDSTART:	LEA		$7000, A7	;set stack pointer
			JSR		PIAINIT		;set up I/O

PIAINIT:	CLR.B	$10084
