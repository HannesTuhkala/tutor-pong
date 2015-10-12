LPOSY		DC.B	0			; left paddle (0..4)
RPOSY		DC.B	0			; right paddle (0..4)
BPOSX		DC.B	0			; Ball position column (0..6)
BPOSY		DC.B	0			; Ball position row (0..4)

MULTPLEXLINE	DC.B	0

COLDSTART:	LEA	$08000, A7		; set stack pointer
		JSR	PIAINIT			; set up I/O
		JSR	INSTALLINTS		; install and enable interrupts

PIAINIT:	CLR.B	$10084			; clear CRA
		; 0..3 multiplex out
		; 4,5  left paddle (player 1)
		; 6,7  right paddle (player 2)
		MOVE.B	$0F,$10080		; 7..4 in, 3..0 out.
		MOVE.B	$17,$10084		; allow interrupts only on CA1

		CLR.B	$10086			; clear CRB
		MOVE.B	$FF,$10082		; 7..0 all out
		MOVE.B	$16,$10086		; do not allow any interrupts
