/*
 * SaveBoatHitandMiss.asm
 *
 *  Created: 10-05-18 16:30:53
 *   Author: admin
 */ 

; ATTENTION POINTERS X,Y AND Z OCCUPIES THE REGISTERs 26-31 --> those registers cannot be used
; Register X: 26-27, Register Y: 28-29, Register Z:30-31

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init
.ORG 0x0020 ; a mettre en dehors pour juste assigner le Timer0OverflowInterrupt a l'adresse 20
RJMP Timer0OverflowInterrupt

;Program memory cannot be changed at runtime, while data memory can. So what we do is to define values at "initbuffer" label to which 

init:
;%%%% Set the click of the joystick as input %%%%%
CBI DDRB,2;Pin PB2 is an input
SBI PORTB,2; Enable the pull-up resistor
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%%% LEDS AS OUTPUT %%%%%%%%
SBI DDRC,2 ; pin PC2 is an output
SBI PORTC,2 ; output Vcc => LED1 is turned off! (car la LED est active low, cf schema)
SBI DDRC,3 ; pin PC3 is an output
SBI PORTC,3 ; output Vcc => LED1 is turned off! (car la LED est active low, cf schema)

;%%%%% JOYSTICK AS INPUT %%%%%%%%;
CBI DDRC,1 ;choose potentiometer along direction y
; joystick initialization
LDI R16, 0b11100111		; put ADC on, enables first conversion, enables auto trigger, put interrupt off, prescaler = 2
STS ADCSRA, R16
LDI R16, 0b00000000    ; free running mode
STS ADCSRB, R16
LDI R16, 0b01100001    ; selection ADC multiplexer and refernce voltage
STS ADMUX, R16
LDI R16, 0b00000000
STS PRR,R16
; result in ADCH

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
LDI R25,0xFF ; start value for TCNT
OUT TCNT0,R25 ; on utilise OUT car R0 est categorise comme un registre I/O

main: 

;%%%%%%%%%%%%%%%%%%%% KEYBOARD LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
LDI R23,0x0 ;reinitialization of column position
;LDI R24,0x0 ;initialization of row position

keyboard:
	;take info from the joystick
	LDS R19, ADCH ; R19 [0,255]   8 bits in upper reg of 10 bit ADC, drop two lsb

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

	;SBI PORTC,3
	;SBI PORTC,2

	;%%% erase the screen if no key is pressed %%%
/*	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02
	LDI R24,0x80;=128
	loop3:
	;LPM R20,Z+
	LDI R25,0b00000000
	ST Y+,R25
	DEC R24
	BRNE loop3*/
	;%%%%%%%%%%%%%%%%

	;%% Erase last bit LED when key released %%
	LDI ZL,0x00
	LDI ZH,0x04 ;last bit stored at data memory 0x0400
	LD R23,Z
	LDI ZL,0x00
	LDI ZH,0x02
	
	ADD ZL,R23
	BRCC nocarry1000
	LDI R23,0x01
	ADD ZH,R23 ;if there is a carry
	nocarry1000:
	LDI R23, 0b00000000
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	;%% Erase last middle bit LED when key released %%
	LDI ZL,0x00
	LDI ZH,0x05 ;last bit stored at data memory 0x0500
	LD R23,Z
	LDI ZL,0x00
	LDI ZH,0x02
	
	ADD ZL,R23
	BRCC nocarry1001
	LDI R23,0x01
	ADD ZH,R23 ;if there is a carry
	nocarry1001:
	LDI R23, 0b00000000
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	RJMP keyboard
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%% when key is pressed %%%%%
Pressed4:
LDI R23,0x1C ;(1+1+32-8)
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1C ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed8:
LDI R23,0x58 ;(11*8) put in hexa
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x58 ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed7:
LDI R23,0x1F
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1F ;because writeMiddleBit changed R23
CALL actionKey
RJMP main

CPressed:  
LDI R23,0x5C
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5C ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
BPressed:  
LDI R23,0x5B
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5B ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed0:  
LDI R23,0x18
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x18 ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
APressed: 
LDI R23,0x5A
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5A ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
DPressed:  
LDI R23,0x5D
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5D ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed3:
LDI R23,0x1B ;(1+1+32-8)
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1B ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed2:
LDI R23,0x1A ;(1+1+32-8)
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1A ;because writeMiddleBit changed R23
CALL actionKey
RJMP main

Pressed1:
LDI R23,0x19 ;(1+1+32-8)
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x19 ;because writeMiddleBit changed R23
CALL actionKey
RJMP main

/*LDI ZL,0x00
LDI ZH,0x04
ST Z,R23
CALL writeMiddleBit*/
/*LDI R23,0x1
CALL write5zeros*/


EPressed:  
LDI R23,0x5E
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5E ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed6:
LDI R23,0x1E ;
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1E ;because writeMiddleBit changed R23
CALL actionKey
RJMP main


Pressed5: 
LDI R23,0x1D ;=(5+1+32-8) put in hexa, to select the middle of the case
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x1D ;because writeMiddleBit changed R23
CALL actionKey
RJMP main


FPressed: 
LDI R23,0x5F
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x5F ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed9:
LDI R23,0x59 ;
CALL writeMiddleBit ;ATTENTION writeMiddleBit changes R23
LDI R23,0x59 ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/*noKeyboard: ;thus here X=0x200
LDI YL,0x00 ;pointer to values in the data memory
LDI YH,0x02
ADD YL,R23 ;add the value of R23 to X to change at its position
BRCC nocarry3
LDI R23,0x01
ADD YH,R23 ;if there is a carry
nocarry3:
LDI R23,0b00000100 ;reuse R23, no link with previous R23
ST Y,R23*/

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RJMP main

	Timer0OverflowInterrupt:
		PUSH R16
		IN R16,SREG
		PUSH R16


		SBI PORTB,4

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

		CBI PORTB,4
		SBI PORTB,4 ;
		;WAIT FOR 100US
		LDI R18,0xFF
/*		waitloop:
			NOP
			NOP
			NOP
			NOP
			NOP
			DEC R18
			BRNE waitloop*/

		CBI PORTB,4  ;put in the beginning of next interrupt to avoid making the loop of nops

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

		POP R16
		OUT SREG,R16
		POP R16
RETI


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%

actionKey: ;% ATTENTION REQUIRES R23 AS ARGUMENT, DIFFERENT FOR EACH KEY
	;%% Stores middle bit for erasing when key released %%
	LDI ZL,0x00
	LDI ZH,0x05
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	;take info from the joystick
	LDS R19, ADCH ; R19 [0,255]   8 bits in upper reg of 10 bit ADC, drop two lsb
	; %%%%% init thresholds %%%%%%%%
	LDI R25,0xC8	;upper one 200 
	LDI R24,0x4B	;lower one 75
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	CP R19, R25
	BRSH goTobiggerthanHthreshold
	CP R24, R19
	BRSH goTolowerthanLthreshold

	RJMP goToNotwrite

	goTobiggerthanHthreshold: 
	LDI R24, 0x10
	ADD R23, R24
	LDI ZL,0x00
	LDI ZH,0x03
	ST Z,R23
	CALL writeMiddleBit
	LD R23,Z
	;%% Stores for erasing when key released %%
	LDI ZL,0x00
	LDI ZH,0x04
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	;%% Erase other point if joystick goes in other direction %%
	SUBI R23,0x20
	CALL write5zeros
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	RJMP goToNotwrite

	goTolowerthanLthreshold:
	SUBI R23, 0x10
	LDI ZL,0x00
	LDI ZH,0x03
	ST Z,R23
	CALL writeMiddleBit
	LD R23,Z
	;%% Stores for erasing when key released %%
	LDI ZL,0x00
	LDI ZH,0x04
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	;%% Erase other point if joystick goes in other direction %%
	LDI R24, 0x20
	ADD R23, R24
	CALL write5zeros
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	goToNotwrite:
	;get value of PINB and fire action (click of the joystick)
	IN R0,PINB ;do R0 = PINB, whre R0 is a register
	BST R0,2; copy PB2 (bit 2 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC JoyPressed; BRTC = Branch if T flag is cleared
	RJMP nothing

	;%%%%%%%%%%%%%%%%% Check if a boat is hit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	JoyPressed:
		;check in init buffer if a boat is present a the position
		LDI ZL,0x00
		LDI ZH,0x03
		LD R23,Z
		LDI ZL, 0x00 ;we reuse Z here, it is different from previous line
		LDI ZH, 0x01
		ADD ZL,R23
		BRCC nocarry2F
		LDI R23,0x01
		ADD ZH,R23 ;if there is a carry

		nocarry2F:
		LD R23,Z	;put what is stocked in the adress 100+R23 in R23
		;look if the value is a 0b00011111 (prescence of a boat) or 0b00000000
		LDI R24, 0b00011111 ; signature of a boat
		CP R24, R23
		BREQ boatdetected
		RJMP missed
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	boatdetected:
		CBI PORTC,3
		CALL writeHitBoat
		RJMP nothing
	missed:	
		CALL writeMissedBoat
	nothing:
RET

writeHitBoat:
	LDI ZL, 0x00
	LDI ZH, 0x04
	LD R23, Z
	LDI R25, 0x8
	SUB R23, R25
	PUSH R23
	CALL write5bitsR23
	POP R23
	ADD R23, R25
	ADD R23, R25
	CALL write5bitsR23
RET

writeMissedBoat:
	LDI ZL, 0x00
	LDI ZH, 0x04
	LD R23, Z
	LDI R25, 0x8
	SUB R23, R25
	PUSH R23
	CALL writeMiss
	POP R23
	ADD R23, R25
	ADD R23, R25
	CALL writeMiss
RET

writeMiss:
	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry55
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry55:
	LDI R23,0b00010001 ;reuse R23, no link with previous R23
	ST Y,R23
RET

write5bitsR23:
	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry44
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry44:
	LDI R23,0b00011111 ;reuse R23, no link with previous R23
	ST Y,R23
RET

writeMiddleBit:
	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry3
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry3:
	LDI R23,0b00000100 ;reuse R23, no link with previous R23
	ST Y,R23
RET

write5zeros:
	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry4
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry4:
	LDI R23,0b00000000 ;reuse R23, no link with previous R23
	ST Y,R23
RET

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
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 
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
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
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


