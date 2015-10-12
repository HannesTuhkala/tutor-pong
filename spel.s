	;
	; Spelet "Sänka Fartyg"
	; Labskelett att komplettera
	; Version 1.1
	
	; Programstrukturen är given. Några rutiner saknas.
	; Det som måste kompletteras är markerat med '***'
	
	; PIA:n skall anslutas/konfigureras enligt följande:
	
	; PIAA	b7-b6	A/D-omvandlare i X-led
	; 	  	b5-b4	A/D omvandlare i Y-led
	;	  	b3	 	Används inte
	;	  	b2-b0	Styr diodmatrisens multiplexingångar
	;
	; CA	b2		Signal till högtalare
	;		b1		Avbrottssignal för MUX-rutinen
	;
	; PIAB	b7		Används inte
	;		b6-b0	Diodmatrisens mönster
	;
	; CB	b2		Starta omvandling hos A/D omvandlare
	;		b1		Används inte
	
	; jump to program
	
	jmp		COLDSTART
	
	; game variables
	
	; define x- and y-coordinates of game area
	
	; movable cursor position
	
POSX	dc.b	0	; rightmost column (0..6)
POSY	dc.b	0	; middle row (0..4)

	; fixed target position
	
TPOSX	dc.b	0	; target position (0..6)
TPOSY	dc.b	0	; target position (0..4)

	; line shown for multiplexing

LINE	dc.b	0	; current line 0..4 shown on display

	; random number
	
RND		dc.b	0	; random number

COLDSTART
		***			 set stack pointer				***
		lea	$08000,a7
		***											***
		jsr	PIAINIT	; setup I/0
		jsr INSTALLINTS	; install and enable interrupts
		
TEST		
		JSR 	GAME
		JMP	TEST

		; short CB1 to GND for now unless
		; you really want interrupts
		
WARMSTART
	move.b	#0,POSX		; we always start from here
	move.b	#2,POSY		;
	jsr	RANDOMTARGET	; position target

UPDATEGAME
		JSR	VIDEOINIT	; clear it to draw a new frame
		move.b	POSY,d0
		and.l	#$000000ff,d0
		lea	$900,a0
		add.l	d0,a0
		move.b	POSX,d0
		bset	d0,(a0)
		RTS

GAME
	; sense joystick and update POSX, POSY
	jsr	JOYSTICK
	
	; update videomem with POSX, POSY and target
	JSR	VIDEOINIT	; clear it to draw a new frame
	move.b	POSY,d0
	and.l	#$000000ff,d0
	lea	$900,a0
	add.l	d0,a0
	move.b	POSX,d0
	bset	d0,(a0)
	
	; target position also
	
	move.b	TPOSY,d0
	and.l	#$7,d0
	lea	$900,a0
	add.l	d0,a0
	move.b	TPOSX,d0
	bset	d0,(a0)

	JMP CHECKHIT
	
GAMECONT

	; wait a bit
	move.l	#10000,d7
DLY
	sub.l	#1,d7
	bne		DLY
	RTS
	
	; analyze situation
	; we have a hit if POSX=TPOSX AND POSY=TPOSY
	
***		skriv rutinen som kollar om vi har träff		***
CHECKHIT	
		CMP.B	POSX,D0
		BNE	HITEND
		MOVE.B	TPOSY,D0
		CMP.B	POSY,D0
		BNE 	HITEND
		JSR	BEEPLOOP
		JMP	WARMSTART

HITEND		JMP GAMECONT
***		om inte träff börjar programmet om från game	***

	; we have a hit! Sound the alarm!
	;jsr	BEEP
	
	; and restart
	;jmp WARMSTART
	
	
	;
	; Joystick sensing routine
	; also sets X- and Y-coords
	;
JOYSTICK
***		starta en omvandling hos A/D-omvandlarna		***
	BCLR	#3,$10086
	
***									***

XCOORD
	move.b		$10080,d0	; read both A/D:s
	
***		skriv kod som ökar eller minskar POSX beroende	***
	BTST	#7,D0
	BEQ	CMPBX
	BTST	#6,D0
	BEQ	YCOORD
	SUBQ.B	#1,POSX

CMPBX
	BTST	#6,D0
	BNE	YCOORD
	ADD.B	#1,POSX

***		på insignalen från A/D-omvandlaren i X-led		***

YCOORD
	move.b		$10080,d0	; what was it now again?
	
***		skriv kod som ökar eller minskar POSY beroende	***
	BTST	#5,D0
	BEQ	CMPBY
	BTST	#4,D0
	BEQ	JOYEND
	ADD.B	#1,POSY
CMPBY
	BTST	#4,D0
	BNE	JOYEND
	SUBQ.B	#1,POSY
***		på insignalen från A/D-omvandlaren i Y-led		***

JOYEND
	jsr			LIMITS		; bounds check before leaving
	rts
	
	
	; LIMITS keeps us from falling off the edge of the world
	; Allowed: 	POSX 0..6
	;			POSY 0..4
LIMITS
	move.b		POSX,d0		; get current (updated) X-coords
	bpl			LIM1		; too much to right?
	move.b		#0,POSX		; not any longer
LIM1
	cmp.b		#7,d0		; too much to left?
	bne			LIMY		; nope, check Y-coord
	move.b		#6,POSX		; stick to left border
LIMY
	move.b		POSY,d0		; get current (updated) Y-coord
	bpl			LIM2		; below arena?
	move.b		#0,POSY		; keep on arena
LIM2
	cmp.b		#5,d0		; above arena?
	bne			LIM_EXIT	; no.
	move.b		#4,POSY		; keep on arena
LIM_EXIT
	; both coords within bounds here
	rts						; done
	
	
	
	;
	; Interrupt routine for multiplexing
	; Installed as IRQA
	;
MUX
***		skriv rutin som handhar multiplexningen och			***
	CMP.B		#0,$10080
	cmp.b		#0,$10082	

	CLR.B		$10082	
	and.b		#%11111000,$10080
	;move.b		D2,$10080
	and.l		#$F,D2
	or.b		D2,$10080
	cmp.b		#4,D2
	bne		ADDMUX
	CLR.L		D2
	JMP		MUXCONT
ADDMUX
	add.b		#$01,D2
MUXCONT
	;and.l		#$F,d2	       	
	and.b		#%11111000,$10080
	or.b		d2,$10080
	lea		$0900,a1
	add.l		d2,a1

	move.b		(a1),$10082

***		utskriften till diodmatrisen					***
	add.b		#1,RND			; update random number
	rte
	
	;
	; Videoinit clears video mem
	;
VIDEOINIT
	clr.b		$900	; clear memory
	clr.b		$901	; .. ditto
	clr.b		$902	;
	clr.b		$903	;
	clr.b		$904	; done
	rts
	
	;
	; Simple (crude!) random generator for target
	;
RANDOMTARGET
	move.b		RND,d0 		; get random number
	AND.B		#%00000111,D0
	BTST		#2,D0
	BNE		NEXTX
	add.b		#3,D0
	;CMP.B		#4,D0
	;BEQ		NEXTX
	;SUB.B		#4,D0
NEXTX	
	cmp.b		#7,D0
	BNE		NEXTX2
	sub.b		#1,d0
NEXTX2
***	skriv kod som överför RND-värdet till önskat intervall	***
	move.b		d0,TPOSX	; TPOSX now in interval
	

	move.b		RND,d0		; get random number
	AND.B		#%00000111,D0
	BTST		#2,D0
	BEQ		NEXTY
	CMP.B		#4,D0
	BEQ		NEXTY
	SUB.B		#4,D0

NEXTY
*** skriv kod som överför RND-värdet till önskat intervall 	***
	move.b		d0,TPOSY	
	rts
	
	;
	; Init PIA
	;
PIAINIT
*** 			skriv kod som initierar PIA:n			***
	clr.b	$10084			; Nollstall CRA
	move.b	#$0F,$10080		; konfigurera PIAA (b7-4 = in, b3-0 = ut) b3 dont care
	move.b	#$37,$10084		; konfigurera CRA (cra1 = avbrott, cra2 = signal till högtalare, utgång)
	
	clr.b	$10086			; Nollstall CRB
	move.b	#$FF,$10082		; konfigurera PIAB (b7-0 = ut) b7 dont care
	move.b	#$36,$10086		; CRB slutvarde (crb1 = används ej, crb2 = utsignal startar a/d omvandlingen)
***														***
	rts
	
	;
	; Install and enable interrupts
	;
INSTALLINTS
***		skriv kod som installerar avbrotssrutinen och		***
	move.l	#MUX,$68	; VILKEN NIVÅ SKA MUXEN HA?
	move.l	#MUX,$74
	;	move.l	X			; Ska det vara någon mer?
	AND.W	#$F8FF,SR		; konfigurera SR till att tillåta avbrott

***		sänker processorns IPL så att avbrott accepteras	***
	rts

BEEPLOOP
	MOVE.L	#400,D4
BEEPLP2
	SUB.L	#1,D4
	BNE	BEEP
	and.b	#%11110111,$10080
	RTS

	
	;
	; Make a silly sound
	;
BEEP
***		skriv kod för en utsignal med lämplig frekvens som	***
	btst	#3,$10080
	bne	SETZERO
	bset	#3,$10080
	jsr 	BEEPDELAY
	JMP	BEEPLP2
SETZERO	and.b	#%11110111,$10080
	jsr 	BEEPDELAY
	JMP	BEEPLP2
BEEPDELAY
	MOVE.L	#76,D3
BDL2	SUB.L	#1,D3
	BNE	BDL2
	rts


***		ska markera träff									***
	jmp	BEEP
	;rts

LOOP
		JMP LOOP

		END

