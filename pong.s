LPOSY		DC.B	0			; left paddle (0..4)
RPOSY		DC.B	0			; right paddle (0..4)
BPOSX		DC.B	0			; Ball position column (0..6)
BPOSY		DC.B	0			; Ball position row (0..4)
DX			DC.B	1
DY			DC.B	1

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

INSTALLINTS:
		MOVE.L	#MUX,$68
		MOVE.L	#TICKBALL,$74
		
		AND.W	#$F8FF,SR

		RTS

MUX:
		CMP.B	#0,$10080
		
		CLR.B	$10082
		AND.B	#%11111000,$10080
		AND.L	#$F,D2
		OR.B	d2,$10080
		CMP.B	#4,D2
		BNE	ADDMUX
		CLR.L	D2
		JMP	MUXCONT
ADDMUX:
		ADD.B	#$01,D2
MUXCONT:
		AND.B	#%11111000,$10080
		OR.B	D2,$10080
		LEA	$0900,A1
		ADD.L	D2,A1
		
		MOVE.B	(A1),$10082
		
		RTE
TICKBALL:
		CMP.B	#0,$10082
		MOVE.B	DX,D5
		ADD.B	D5,BPOSX 
		MOVE.B	DY,D5
		ADD.B	D5,BPOSY
		CMP.B	#5,BPOSY
		BNE		NOYUBOUNCE
		MOVE.B	#4,BPOSY
		MOVE.B	#-1,DY
NOYUBOUNCE:
		CMP.B	#-1,BPOSY
		BNE		NOYLBOUNCE
		MOVE.B	#0,BPOSY
		MOVE.B	#1,DY
NOYRBOUNCE:
		CMP.B	#0,BPOSX
		BNE		NOXRBOUNCE
		MOVE.B	LPOSY,D5
		CMP.B	BPOSY,D5
		BLT		FAIL
		ADD.B	#1,D5
		CMP.B	BPOSY,D5
		BGT		FAIL
		MOVE.B	#1,BPOSX
		MOVE.B	#1,DX
		JMP		NOXRBOUNCE
FAIL:
		TRAP	#14
		;signal game over
NOXRBOUNCE:
		CMP.B	#6,BPOSX
		BNE		NOXLBOUNCE
		MOVE.B	RPOSY,D5
		CMP.B	BPOSY,D5
		BLT		FAIL
		ADD.B	#1,D5
		CMP.B	BPOSY,D5
		BGT		FAIL
		MOVE.B	#1,BPOSX
		MOVE.B	#1,DX
NOXLBOUNCE:
		RTE

VIDEOINIT:
		CLR.B	$900
		CLR.B	$901
		CLR.B	$902
		CLR.B	$903
		CLR.B	$904
		RTS

