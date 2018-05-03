;
; TestBuffer_interrupt.asm: WORKING DISPLAY USING INTERRUPTS
;
; Created: 23-04-18 13:34:45
; Author : Laurent Storrer & Benjamin Wauthion
;

;PROBLEM: it seems that the reading of the data buffer doesn't work: the pointer is going to far or too short

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init
.ORG 0x0020 ; a mettre en dehors pour juste assigner le Timer0OverflowInterrupt a l'adresse 20
RJMP Timer0OverflowInterrupt

;Program memory cannot be changed at runtime, while data memory can. So what we do is to define values at "initbuffer" label to which 

init:
;%%%%%%%%%%%% INITIALIZE INTERRUPTS %%%%%%%%%%%%%%%%%%%%%
SEI ; dedicated instruction for general interrupts
LDI R18, 0b00000001 ; specific interrupt for timer0
STS TIMSK0,R18
;%%%%%%%%%%%% INITIALIZE PRESCALER %%%%%%%%%%%%%%%%%%%%%%
; CBI TCCR0B,WGM02 ; 0b000 ;initialize timer --> no need car deja a zero
LDI R16, 0b00000011
OUT TCCR0B, R16 ; prescaler = 64
;%%%%%%%%%%%% INITIALIZE TCNT %%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI R17,0xB8 ; start value for TCNT
OUT TCNT0,R17 ; on utilise OUT car R0 est categorise comme un registre I/O


;%%%%%%%%%%%%%%%%%%%%%%%%% POINTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI ZL,low(initbuffer<<1) ;pointer to values in the program memory
LDI ZH,high(initbuffer<<1)
; ARE THE SHIFTS OK ? Yes

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x01
;--> donc X=XH+XL=0x0100

;%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILL THE DATA MEMORY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI R16,0x80;=128
loop:
LPM R20,Z+
ST X+,R20
DEC R16
BRNE loop
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;Screen as output
SBI DDRB,3
SBI DDRB,4
SBI DDRB,5

;SBI PORTB,3
LDI R17,0x7 ;DON'T MODIFY R17 AFTER
LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x01

; because of the shift register, the first data that you input will be displayed the last, thus we begin by sending the last row of the data matrix
; and we decrement the counter
;ADIW X,0x40 ;=56

;%%% ADDITION OF 2*64 to X, need carry addition because ADIW doesn't work because 64 is too high %%%%%
LDI R20,0x80;=2*64=2*(56+8) !!!!CHANGED!!!
ADD XL,R20
BRCC nocarry
LDI R20,0x01
ADD XH,R20 ;if there is a carry
nocarry:


main: 
RJMP main

Timer0OverflowInterrupt:
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBIW X,0x8 ;substract immediate
		;SBI PORTB,3

		;%%%%%% COLUMNS %%%%%%%%%%%
		;correspond to first line of blocks
		LDI R16,0x8 ;compteur: 8  
		;ADIW X,0x1 ; to counteract the first pre-decrement --> not sure !!!NEW!!! 
		firstloop1:
			LD R21,-X ; attention PRE-decrement !!!NEW!!!
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop1 ;branch if R16 is 0

		;correspond to second line of blocks
		SBIW X,0x38	;56 in block term !!!NEW!!! : put SBIW and not ADIW
		LDI R16,0x8 ;compteur: 8  
		firstloop2:
			LD R21,-X
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop2 ;branch if R16 is 0


		LDI R16,0x8
		secondloop:
			CBI PORTB,3
			CP R16,R17
			BRNE not_equal

			SBI PORTB,3

			not_equal:
			SBI PORTB,5
			CBI PORTB,5
			DEC R16
			BRNE secondloop

		SBI PORTB,4 ;
		;WAIT FOR 100US
		LDI R18,0xFF
		waitloop:
			NOP
			NOP
			NOP
			NOP
			NOP
			DEC R18
			BRNE waitloop

		CBI PORTB,4 

		;%%% ADDITION OF 72 to X, car on fait +72 et -8 au début de l'itération suivante !!!NEW!!! %%%%%
		LDI R20,0x48;=2*64=2*(56+8) !!!!CHANGED!!!
		ADD XL,R20
		BRCC nocarry2
		LDI R20,0x01
		ADD XH,R20 ;if there is a carry
		nocarry2:
		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		DEC R17
		BRNE dontinitR17
		LDI R17,0x7
		LDI XL,0x00 ;pointer to values in the data memory
		LDI XH,0x01

		; because of the shift register, the first data that you input will be displayed the last, thus we begin by sending the last row of the data matrix
		; and we decrement the counter
		;ADIW X,0x40 ;=56

		;%%% ADDITION OF 2*64 to X, need carry addition because ADIW doesn't work because 64 is too high %%%%%
		LDI R20,0x80;=2*64=2*(56+8) !!!!CHANGED!!!
		ADD XL,R20
		BRCC dontinitR17
		LDI R20,0x01
		ADD XH,R20 ;if there is a carry
		dontinitR17:
RETI


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%
write5bits:
	LDI R22, 0x5
	loop_write5:
	BST R21,0
	CBI PORTB,3
	BRTC write_0	;0 into the T flag
	write_1:
		SBI PORTB,3
	write_0:
	SBI PORTB,5
	CBI PORTB,5

	LSR R21 ; logical shift register R21 to the right !!!NEW!!! -->pas sur

	DEC R22
	BRNE loop_write5
RET
;%%%%%%%%%%%%%%%%%% BUFFER STORED IN THE PROGRAM MEMORY: CANNOT BE CHANGED AT RUNTIME %%%%%%%%%%%%%%%%%%%%%
;Attention only the 5 LSB of each compartment will be used for the 5 columns
initbuffer:
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000 ;1 of the 2 rows that are only printed
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ;1 of the 2 rows that are only printed
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

;current error: the bits in the matrix are displayed but shifted on the left: for ex. 00011011 is displayed 00010111
; in fact the bit at position i is at position (i-1) on the left
; --> tout est décalé de un cran vers la gauche



