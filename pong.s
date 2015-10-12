LPOSY		DC.B	0			; left paddle (0..4)
RPOSY		DC.B	0			; right paddle (0..4)
BPOSX		DC.B	0			; Ball position column (0..6)
BPOSY		DC.B	0			; Ball position row (0..4)

MULTPLEXLINE	DC.B	0

COLDSTART:	LEA	$08000, A7		; set stack pointer
		JSR	PIAINIT			; set up I/O

PIAINIT:	CLR.B	$10084			; clear CRA
		MOVE.B	$0F,$10080
		MOVE.B	$17,$10084

		CLR.B	$10086			; clear CRB
		MOVE.B	$FF,$10082
		MOVE.B	$16,$10086
