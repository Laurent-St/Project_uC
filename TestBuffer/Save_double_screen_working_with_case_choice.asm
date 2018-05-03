;
; TestBuffer SAVE with working double diplay (2 buffers) and choice of the case with keyboard
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

;%%%%%%%%%%%% PIN PB0 (switch) INITIALIZATION %%%%%%%%%%
CBI DDRB,0;Pin PB0 is an input
SBI PORTB,0; Enable the pull-up resistor


;%%%%% KEYBOARD INITIALIZATION %%%%%%
CBI DDRD,0 ;set columns as inputs
CBI DDRD,1
CBI DDRD,2
CBI DDRD,3

SBI DDRD,4 ;set rows as outputs
SBI DDRD,5
SBI DDRD,6
SBI DDRD,7

SBI PORTD,0 ;enable pull-up resistors on inputs (cannot do it on inputs)
SBI PORTD,1
SBI PORTD,2
SBI PORTD,3

;%%%%%%%%%%%%%%%%%%%%%%%%% POINTER FOR 1ST BUFFER: : LOADED STARTING AT DATA ADDRESS 0x0100 %%%%%%%%
LDI ZL,low(initbuffer<<1) ;pointer to values in the program memory
LDI ZH,high(initbuffer<<1)
; ARE THE SHIFTS OK ? Yes

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x01
;--> donc X=XH+XL=0x0100

;%%fill the data memory %%
LDI R16,0x80;=128
loop:
LPM R20,Z+
ST X+,R20
DEC R16
BRNE loop
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%%%%%%%%%%%%%%%%%%%%%%%%%% SECOND BUFFER: LOADED STARTING AT DATA ADDRESS 0x0200 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI ZL,low(playerbuffer<<1) ;pointer to values in the program memory
LDI ZH,high(playerbuffer<<1)
; ARE THE SHIFTS OK ? Yes

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x02
;--> donc X=XH+XL=0x0200

;%%fill the data memory %%
LDI R16,0x80;=128
loop2:
LPM R20,Z+
ST X+,R20
DEC R16
BRNE loop2
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

;Screen as output
SBI DDRB,3
SBI DDRB,4
SBI DDRB,5

;SBI PORTB,3

IN R0,PINB ;do R0 = PINB
BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

BRTC ButtonLow2

ButtonHigh2: ; TO DO ONLY AT THE BEGINNING OF THE GAME
	LDI XL,0x00 ;pointer to values in the data memory
	LDI XH,0x01
	RJMP follow

ButtonLow2:
	LDI XL,0x00 ;pointer to values in the data memory
	LDI XH,0x02

follow:

LDI R17,0x7 ;DON'T MODIFY R17 AFTER, it is the counter of the line

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

;%%%%%%%%%%%% INITIALIZE INTERRUPTS %%%%%%%%%%%%%%%%%%%%%
SEI ; dedicated instruction for general interrupts
LDI R18, 0b00000001 ; specific interrupt for timer0
STS TIMSK0,R18
;%%%%%%%%%%%% INITIALIZE PRESCALER %%%%%%%%%%%%%%%%%%%%%%
; CBI TCCR0B,WGM02 ; 0b000 ;initialize timer --> no need car deja a zero
LDI R25, 0b00000010
OUT TCCR0B, R25 ; prescaler = 64
;%%%%%%%%%%%% INITIALIZE TCNT %%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI R25,0xB8 ; start value for TCNT
OUT TCNT0,R25 ; on utilise OUT car R0 est categorise comme un registre I/O

main: 

;%%%%%%%%%%%%%%%%%%%% KEYBOARD LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
LDI R23,0x0 ;initialization of column position
LDI R24,0x0 ;initialization of row position

keyboard:
;%%%%%% put all rows to 1 at the beginning %%%%%%%%%%
	SBI PORTB,4

	SBI PORTD,4 
	SBI PORTD,5 
	SBI PORTD,6 
	SBI PORTD,7 

	CBI PORTD,4 ;write a zero on the first row (starting from below)
	nop
	SBIS PIND,0
	RJMP CPressed
	SBIS PIND,1
	RJMP BPressed
	SBIS PIND,2
	RJMP Pressed0
	SBIS PIND,3
	RJMP APressed
	SBI PORTD,4 ;write a zero on the first row (starting from below)

	CBI PORTD,5;write a zero on the second row
	nop
	SBIS PIND,0
	RJMP DPressed
	SBIS PIND,1
	RJMP Pressed3
	SBIS PIND,2
	RJMP Pressed2
	SBIS PIND,3
	RJMP Pressed1
	SBI PORTD,5 ;write a zero on the first row (starting from below)

	CBI PORTD,6;write a zero on the third row
	nop
	SBIS PIND,0
	RJMP EPressed
	SBIS PIND,1
	RJMP Pressed6
	SBIS PIND,2
	RJMP Pressed5
	SBIS PIND,3
	RJMP Pressed4
	SBI PORTD,6 ;write a zero on the first row (starting from below)

	CBI PORTD,7;write a zero on the 4th row
	nop
	SBIS PIND,0
	RJMP FPressed
	SBIS PIND,1
	RJMP Pressed9
	SBIS PIND,2
	RJMP Pressed8
	SBIS PIND,3
	RJMP Pressed7
	SBI PORTD,7 ;write a zero on the first row (starting from below)

	RJMP keyboard
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%% when key is pressed %%%%%
Pressed4: LDI R23,0x4
RJMP noKeyboard
Pressed8: LDI R23,0x40 ;=64 put in hexa=0x40, to go on the next line of cases
RJMP noKeyboard
Pressed7: LDI R23,0x7
RJMP noKeyboard

CPressed: LDI R23,0x44 ;=64+4 put in hexa=0x44, to go on the next line of cases + 4 case
RJMP noKeyboard
BPressed: LDI R23,0x43 ;=64+3 put in hexa=0x43, to go on the next line of cases + 3 case
RJMP noKeyboard
Pressed0: LDI R23, 0x0
RJMP noKeyboard
APressed: LDI R23,0x42 ;=64+2 put in hexa=0x42, to go on the next line of cases + 2 case
RJMP noKeyboard
DPressed: LDI R23,0x45 ;=64+5 put in hexa=0x45, to go on the next line of cases + 5 case
RJMP noKeyboard
Pressed3: LDI R23,0x3
RJMP noKeyboard
Pressed2: LDI R23,0x2
RJMP noKeyboard
Pressed1: LDI R23,0x1
RJMP noKeyboard
EPressed: LDI R23,0x46 ;=64+6 put in hexa=0x46, to go on the next line of cases + 6 case
RJMP noKeyboard
Pressed6: LDI R23,0x6
RJMP noKeyboard
Pressed5: LDI R23,0x5
RJMP noKeyboard
FPressed: LDI R23,0x47 ;=64+7 put in hexa=0x47, to go on the next line of cases + 7 case
RJMP noKeyboard
Pressed9: LDI R23,0x41 ;=64+1 put in hexa=0x41, to go on the next line of cases + 1 case
RJMP noKeyboard
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

noKeyboard: ;thus here X=0x200
LDI YL,0x00 ;pointer to values in the data memory
LDI YH,0x02
ADD YL,R23 ;add the value of R23 to X to change at its position
BRCC nocarry3
LDI R23,0x01
ADD YH,R23 ;if there is a carry
nocarry3:
LDI R23,0b00000100 ;reuse R23, no link with previous R23
ST Y,R23


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RJMP main

	Timer0OverflowInterrupt:
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

		IN R0,PINB ;do R0 = PINB
		BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
		BRTC ButtonLow
		ButtonHigh: ; TO DO ONLY AT THE BEGINNING OF THE GAME
			LDI XL,0x00 ;pointer to values in the data memory
			LDI XH,0x01
			RJMP followinitR17
		ButtonLow:
			LDI XL,0x00 ;pointer to values in the data memory
			LDI XH,0x02
		followinitR17:
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
;%%%%%%%%%%%%%%%%%% BUFFERS STORED IN THE PROGRAM MEMORY: CANNOT BE CHANGED AT RUNTIME %%%%%%%%%%%%%%%%%%%%%
;Attention only the 5 LSB of each compartment will be used for the 5 columns

;%%%%%%%%%%%%%%%%%%%%%%%%%%% BUFFER TO STORE THE SHIPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initbuffer:
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00011111 ; "fake column", not to display


;%%%%%%%%%%%%%%%%%%%%% Second buffer for the players to try to shoot %%%%%%%%%%%%%%%%%%%%%%%%%
playerbuffer:
.db 0b00000000, 0b00011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display


