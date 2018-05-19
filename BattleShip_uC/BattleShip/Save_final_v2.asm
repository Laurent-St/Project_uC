/*
 * Save_final_v2.asm
 *
 *  Created: 19-05-18 11:43:46
 *   Author: admin
 */ 

; WARNING POINTERS X,Y AND Z OCCUPIES THE REGISTERs 26-31 --> those registers cannot be used
; Register X: 26-27, Register Y: 28-29, Register Z:30-31

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init
.ORG 0x0012
RJMP Timer2OverflowInterrupt
.ORG 0x0020
RJMP Timer0OverflowInterrupt

;Program memory cannot be changed at runtime, while data memory can. So what we do is to define values at "initbuffer" label to which 

init:

;%%%%%%%%% Parameters of the game: number of hits to win and max number of tries before losing %%%%%%%%%%
.EQU NBRE_BOAT = 0x3
.EQU MAX_TRIES = 0x5
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%% INIT COUNTERS for boat hits and miss %%%%%
;number of boats
LDI ZL, 0x01
LDI ZH, 0x06
LDI R23, NBRE_BOAT
ST Z, R23
;initialize counter of hits of boats
LDI ZL, 0x02
LDI ZH, 0x06
LDI R23, 0x0
ST Z, R23
;initialize flag of hit
LDI ZL, 0x03
LDI ZH, 0x06
LDI R23, 0x0
ST Z, R23
;max number of allowed tries
LDI ZL, 0x04
LDI ZH, 0x06
LDI R23, MAX_TRIES
ST Z, R23
;initialize counter of tries
LDI ZL, 0x05
LDI ZH, 0x06
LDI R23, 0x0
ST Z, R23
;initialize flag of miss
LDI ZL, 0x06
LDI ZH, 0x06
LDI R23, 0x0
ST Z, R23

;%%%% FLAG for erasing the last bit %%%%%
LDI ZL, 0x00
LDI ZH, 0x07
LDI R23, 0x0
ST Z, R23
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


;%%%% Set the click of the joystick as input %%%%%
CBI DDRB,2;Pin PB2 is an input
SBI PORTB,2; Enable the pull-up resistor
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%%% LEDS AS OUTPUT %%%%%%%%
SBI DDRC,2 ; pin PC2 is an output
SBI PORTC,2 ; output Vcc => LED1 is turned off! (because LED active low)
SBI DDRC,3 ; pin PC3 is an output
SBI PORTC,3 ; output Vcc => LED1 is turned off!

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

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x01
;--> thus X=XH+XL=0x0100

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

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x02
;--> thus X=XH+XL=0x0200

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

IN R0,PINB ;do R0 = PINB
BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

BRTC ButtonLow2

ButtonHigh2:
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

;%%% ADDITION OF 2*64 to X, need carry addition because ADIW doesn't work because 64 is too high %%%%%
LDI R20,0x80;=2*64=2*(56+8) 
ADD XL,R20
BRCC nocarry
LDI R20,0x01
ADD XH,R20 ;if there is a carry
nocarry:

;%%%%%%%%%%%% INITIALIZE SPEAKER AS OUTPUT  %%%%%%%%%%%%%%%%%%
SBI DDRB,1 ; pin PB1 is an output
;%%%%%%%%%%%% INITIALIZE SPEAKER TO 0  %%%%%%%%%%%%%%%%%%
CBI PORTB,1 ; output low to put the speaker off

;%%%%%%%%%%%% INITIALIZE GLOBAL INTERRUPTS %%%%%%%%%%%%%%%%%%%%%
SEI ; dedicated instruction for general interrupts
;%%%%%%%%%%%% INITIALIZE PRESCALER OF TIMER2 %%%%%%%%%%%%%%%%%%%%%%
LDI R16, 0b00000100
STS TCCR2B, R16 ; prescaler = 256
;%%%%%%%%%%%% INITIALIZE INTERRUPTS FOR TIMER0 %%%%%%%%%%%%%%%%%%%%%
LDI R18, 0b00000001 ; specific interrupt for timer0
STS TIMSK0,R18
;%%%%%%%%%%%% INITIALIZE PRESCALER OF TIMER0 %%%%%%%%%%%%%%%%%%%%%%
LDI R25, 0b00000010
OUT TCCR0B, R25 ; prescaler = 8
;%%%%%%%%%%%% INITIALIZE TCNT OF TIMER0 %%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI R25,0xFF ; start value for TCNT
OUT TCNT0,R25 ; we use OUT because R0 is a I/O register

main: 

;%%%%%%%%%%%%%%%%%%%% KEYBOARD LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
LDI R23,0x0 ;reinitialization of column position

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
	SBI PORTD,4 ;write a one on the first row (starting from below)

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
	SBI PORTD,5 ;write a one on the second row (starting from below)

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
	SBI PORTD,6 ;write a one on the third row (starting from below)

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
	SBI PORTD,7 ;write a one on the 4th row (starting from below)

	;%%%%%%%% Erase last bit LED when key released, if flag is zero %%%%%%%
	LDI ZL,0x00
	LDI ZH,0x07 ;last bit stored at data memory 0x0400
	LD R23,Z
	LDI R25,0x0
	CP R23,R25
	BRNE donterasebit ;if flag is 1, dont erase

	LDI ZL,0x00
	LDI ZH,0x04 ;last bit stored at data memory 0x0400
	LD R23,Z


	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow11
	ButtonHigh11:
		LDI ZL,0x00 ;pointer to values in the data memory
		LDI ZH,0x01
		RJMP follow11
	ButtonLow11:
		LDI ZL,0x00 ;pointer to values in the data memory
		LDI ZH,0x02
	follow11:
	;LDI ZL,0x00
	;LDI ZH,0x02
	
	ADD ZL,R23
	BRCC nocarry1000
	LDI R23,0x01
	ADD ZH,R23 ;if there is a carry
	nocarry1000:
	LDI R23, 0b00000000
	ST Z,R23

	donterasebit:
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	;%% Erase last middle bit LED when key released %%
	LDI ZL,0x00
	LDI ZH,0x05 ;last bit stored at data memory 0x0500
	LD R23,Z

	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow10
	ButtonHigh10:
		LDI ZL,0x00 ;pointer to values in the data memory
		LDI ZH,0x01
		RJMP follow10
	ButtonLow10:
		LDI ZL,0x00 ;pointer to values in the data memory
		LDI ZH,0x02
	follow10:

	;LDI ZL,0x00
	;LDI ZH,0x02
	
	ADD ZL,R23
	BRCC nocarry1001
	LDI R23,0x01
	ADD ZH,R23 ;if there is a carry
	nocarry1001:
	LDI R23, 0b00000000
	ST Z,R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	;%% Reinitialize the flag of hit counting if no key pressed %%%%%%%
	LDI ZL,0x03
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25
	;%% Reinitialize the flag of miss counting if no key pressed %%%%%%%
	LDI ZL,0x06
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25

	;%% Disable Interrupt %%
	LDI R18, 0b00000000 ; specific interrupt for timer2
	STS TIMSK2,R18
	;%%%%%%%%%%%%%%%%%%%%%%%

	RJMP keyboard
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%% when key is pressed %%%%%
Pressed4:
LDI R23,0x1C
CALL writeMiddleBit ;WARNING writeMiddleBit changes R23
LDI R23,0x1C ;because writeMiddleBit changed R23
CALL actionKey
RJMP main
Pressed8:
LDI R23,0x58 ;(11*8) put in hexa
CALL writeMiddleBit
LDI R23,0x58
CALL actionKey
RJMP main
Pressed7:
LDI R23,0x1F
CALL writeMiddleBit 
LDI R23,0x1F
CALL actionKey
RJMP main

CPressed:  
LDI R23,0x5C
CALL writeMiddleBit
LDI R23,0x5C
CALL actionKey
RJMP main
BPressed:  
LDI R23,0x5B
CALL writeMiddleBit
LDI R23,0x5B
CALL actionKey
RJMP main
Pressed0:  
LDI R23,0x18
CALL writeMiddleBit
LDI R23,0x18
CALL actionKey
RJMP main
APressed: 
LDI R23,0x5A
CALL writeMiddleBit
LDI R23,0x5A
CALL actionKey
RJMP main
DPressed:  
LDI R23,0x5D
CALL writeMiddleBit
LDI R23,0x5D 
CALL actionKey
RJMP main
Pressed3:
LDI R23,0x1B
CALL writeMiddleBit
LDI R23,0x1B
CALL actionKey
RJMP main
Pressed2:
LDI R23,0x1A
CALL writeMiddleBit
LDI R23,0x1A
CALL actionKey
RJMP main

Pressed1:
LDI R23,0x19
CALL writeMiddleBit
LDI R23,0x19
CALL actionKey
RJMP main

EPressed:  
LDI R23,0x5E
CALL writeMiddleBit
LDI R23,0x5E
CALL actionKey
RJMP main
Pressed6:
LDI R23,0x1E ;
CALL writeMiddleBit 
LDI R23,0x1E
CALL actionKey
RJMP main


Pressed5: 
LDI R23,0x1D
CALL writeMiddleBit
LDI R23,0x1D
CALL actionKey
RJMP main

FPressed: 
LDI R23,0x5F
CALL writeMiddleBit
LDI R23,0x5F
CALL actionKey
RJMP main

Pressed9:
LDI R23,0x59 ;
CALL writeMiddleBit
LDI R23,0x59
CALL actionKey
RJMP main
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RJMP main

;%%%%%%%%%%%%%%%%%%%%%%%%%%% INTERRUPT TIMER2 FOR BUZZER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Timer2OverflowInterrupt:
		PUSH ZL
		PUSH ZH
		PUSH R23
		PUSH R25
		IN R25,SREG
		PUSH R25

		;%% Check if boat was hit or missed and choose one of the 2 frequencies %%%
		LDI ZL,0x00
		LDI ZH,0x08

		LD R23,Z
		LDI R25,0x1

		SBI PINB,1; by writing a 1 to the pin it will toggle the actual value of the port

		CP R23,R25
		BRNE missfreq
		LDI R23, 0xAA
		STS TCNT2,R23
		RJMP endinterrupt

		missfreq:
		LDI R23, 0xF
		STS TCNT2,R23

		endinterrupt:
		POP R25
		OUT SREG,R25
		POP R25
		POP R23
		POP ZH
		POP ZL
	RETI


;%%%%%%%%%%%%%%%%%%%%%%%%%%% INTERRUPT TIMER0 FOR DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Timer0OverflowInterrupt:
		PUSH R16
		IN R16,SREG
		PUSH R16
		PUSH R18

		SBI PORTB,4

		SBIW X,0x8 ;substract immediate

		;%%%%%% COLUMNS %%%%%%%%%%%
		;correspond to first line of blocks
		LDI R16,0x8 ;compteur: 8  
		firstloop1:
			LD R21,-X ; warning PRE-decrement
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop1 ;branch if R16 is 0

		;correspond to second line of blocks
		SBIW X,0x38	;56 in block term
		LDI R16,0x8 ;counter  
		firstloop2:
			LD R21,-X
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop2 ;branch if R16 is 0
		;%%%% ROWS %%%%%
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

		CBI PORTB,4

		LDI R18,0x5F
		waitloop: ;to increase brightness, wait a bit more time
			NOP
			NOP
			NOP
			DEC R18
			BRNE waitloop

		;%%% ADDITION OF 72 to X, because we do +72 and -8 at next iteration
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
		ButtonHigh:
			LDI XL,0x00 ;pointer to values in the data memory
			LDI XH,0x01
			RJMP followinitR17
		ButtonLow:
			LDI XL,0x00 ;pointer to values in the data memory
			LDI XH,0x02
		followinitR17:
		;%%% ADDITION OF 2*64 to X, need carry addition because ADIW doesn't work because 64 is too high %%%%%
		LDI R20,0x80;=2*64=2*(56+8)
		ADD XL,R20
		BRCC dontinitR17
		LDI R20,0x01
		ADD XH,R20 ;if there is a carry
		dontinitR17:

		;%% Reinitialize the counter %%
		LDI R20,0x0
		OUT TCNT0,R20
		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		POP R18

		POP R16
		OUT SREG,R16
		POP R16
RETI


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%

actionKey: ;% ATTENTION REQUIRES R23 AS ARGUMENT, DIFFERENT FOR EACH KEY
	
	;IN R0,PINB ;do R0 = PINB
	;BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

	;BRTC player2key ;if switch is LOW

	;RJMP player1key ; if switch is HIGH

	;player2key:

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
	;% Remove flag for erasing %%%%
	LDI ZL,0x00
	LDI ZH,0x07
	LDI R25,0x0
	ST Z,R25
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

	PUSH R23

	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow44
	ButtonHigh44:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x01
		RJMP follow44
	ButtonLow44:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x02
	follow44:
	LD R23,Y
	LDI R25,0b00000100
	CP R23,R25
	BRNE donteraseboat
	CALL write5zeros
	
	donteraseboat:
	POP R23
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	RJMP goToNotwrite

	goTolowerthanLthreshold:
	;% Remove flag for erasing %%%%
	LDI ZL,0x00
	LDI ZH,0x07
	LDI R25,0x0
	ST Z,R25
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

	PUSH R23

	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow442
	ButtonHigh442:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x01
		RJMP follow442
	ButtonLow442:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x02
	follow442:
	LD R23,Y
	LDI R25,0b00000100
	CP R23,R25
	BRNE donteraseboat2
	CALL write5zeros
	
	donteraseboat2:
	POP R23


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
		IN R0,PINB ;do R0 = PINB
		BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

		BRTC Player2Playing

		Player1PlacingBoats: 
			CALL writeHitBoat
			;% Put flag to avoid erasing %%% 
			LDI ZL,0x00
			LDI ZH,0x07
			LDI R25,0x1
			ST Z,R25
			;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RJMP nothing

		Player2Playing:

		CBI PORTC,2
		CBI PORTC,3
		;check in init buffer if a boat is present a the position
		LDI ZL,0x00
		LDI ZH,0x03
		LD R23,Z
		LDI ZL, 0x00 ;we reuse Z here, it is different from previous line
		LDI ZH, 0x01
		ADD ZL,R23

		SBI PORTC,2
		SBI PORTC,3

		BRCC nocarry2F
		LDI R23,0x01
		ADD ZH,R23 ;if there is a carry

		nocarry2F:
		LD R23,Z	;put what is stocked in the adress 100+R23 in R23
		;look if the value is a 0b00011111 (presence of a boat) or 0b00000000
		LDI R24, 0b00011111 ; signature of a boat
		CP R24, R23
		BREQ boatdetected
		RJMP missed
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	boatdetected:

		LDI R18, 0b00000001 ; specific interrupt for timer2
		STS TIMSK2,R18

		LDI ZL, 0x00
		LDI ZH, 0x08
		LDI R18, 0x1
		ST Z,R18

		CALL writeHitBoat
		;check if flag of hit counter is 0
		LDI ZL,0x03
		LDI ZH,0x06
		LD R24,Z
		LDI R25,0x0
		CP R24,R25
		BRNE nothing ;if flag is not 0, don't increment the counter

		;%% Put flag to 1 and Increment counter %%

		;% Put flag to avoid erasing %%% 
		LDI ZL,0x00
		LDI ZH,0x07
		LDI R25,0x1
		ST Z,R25
		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		LDI ZL,0x03
		LDI ZH,0x06
		LDI R25,0x1
		ST Z,R25
		LDI ZL,0x02
		LDI ZH,0x06
		LD R24,Z
		LDI R25,0x1
		ADD R24,R25
		ST Z,R24
		LDI ZL,0x01
		LDI ZH,0x06
		LD R25,Z
		CP R24,R25
		BREQ victory
		
		RJMP nothing
	missed:
		
		LDI R18, 0b00000001 ; specific interrupt for timer2
		STS TIMSK2,R18

		LDI ZL, 0x00
		LDI ZH, 0x08
		LDI R18, 0x2
		ST Z,R18

		CALL writeMissedBoat
		;check if flag of hit counter is 0
		LDI ZL,0x06
		LDI ZH,0x06
		LD R24,Z
		LDI R25,0x0
		CP R24,R25
		BRNE nothing ;if flag is not 0, don't increment the counter

		;%% Put flag to 1 and Increment counter %%
		LDI ZL,0x06
		LDI ZH,0x06
		LDI R25,0x1
		ST Z,R25
		LDI ZL,0x05
		LDI ZH,0x06
		LD R24,Z
		LDI R25,0x1
		ADD R24,R25
		ST Z,R24
		LDI ZL,0x04
		LDI ZH,0x06
		LD R25,Z
		CP R24,R25
		BREQ GameOver
		RJMP nothing
	nothing:
RET

;%%%%%%%%%%%%%%%%%%%%%%%%%%% Victory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
victory:

;%%% LOADING VICOTRY PATTERN AT 0x0200
LDI ZL,low(victorybuffer<<1) ;pointer to values in the program memory
LDI ZH,high(victorybuffer<<1)
; ARE THE SHIFTS OK ? Yes

LDI YL,0x00 ;pointer to values in the data memory
LDI YH,0x02

;%%fill the data memory %%
LDI R25,0x80;=128
loopvictory:
LPM R20,Z+
ST Y+,R20
DEC R25
BRNE loopvictory

;% check if reset of the game
checkreset:
IN R0,PINB ;do R0 = PINB
BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

BRTC ButtonLowVictory

ButtonHighVictory:
	
	;%%% RELOADING STARTING PATTERN AT 0x0200 (player2)
	LDI ZL,low(playerbuffer<<1) ;pointer to values in the program memory
	LDI ZH,high(playerbuffer<<1)

	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02

	;%%fill the data memory %%
	LDI R25,0x80;=128
	loopvictoryreset:
	LPM R20,Z+
	ST Y+,R20
	DEC R25
	BRNE loopvictoryreset

	;%%% RELOADING STARTING PATTERN AT 0x0100 (player1)
	LDI ZL,low(initbuffer<<1) ;pointer to values in the program memory
	LDI ZH,high(initbuffer<<1)

	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x01

	;%%fill the data memory %%
	LDI R25,0x80;=128
	loopvictoryreset2:
	LPM R20,Z+
	ST Y+,R20
	DEC R25
	BRNE loopvictoryreset2

	;%% Reinitialize the hit counter %%%%%%%
	LDI ZL,0x02
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25
	;%% Reinitialize the miss counter %%%%%%%
	LDI ZL,0x05
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25

	RJMP main

ButtonLowVictory:
	RJMP checkreset

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù


;%%%%%%%%%%%%%%%%%%%%%%%%%%% GameOver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GameOver:
;%%% LOADING GAME OVER PATTERN AT 0x0200
LDI ZL,low(gameoverbuffer<<1) ;pointer to values in the program memory
LDI ZH,high(gameoverbuffer<<1)

LDI YL,0x00 ;pointer to values in the data memory
LDI YH,0x02

;%%fill the data memory %%
LDI R25,0x80;=128
loopGameOver:
LPM R20,Z+
ST Y+,R20
DEC R25
BRNE loopGameOver

;% check if reset of the game
checkreset2:
IN R0,PINB ;do R0 = PINB
BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)

BRTC ButtonLow3

ButtonHigh3: 
	;%%% reloading starting pattern for player2
	LDI ZL,low(playerbuffer<<1) ;pointer to values in the program memory
	LDI ZH,high(playerbuffer<<1)

	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x02

	;%%fill the data memory %%
	LDI R25,0x80;=128
	loopgameoverreset:
	LPM R20,Z+
	ST Y+,R20
	DEC R25
	BRNE loopgameoverreset

	;%%% reloading starting pattern for player1
	LDI ZL,low(initbuffer<<1) ;pointer to values in the program memory
	LDI ZH,high(initbuffer<<1)

	LDI YL,0x00 ;pointer to values in the data memory
	LDI YH,0x01

	;%%fill the data memory %%
	LDI R25,0x80;=128
	loopgameoverreset2:
	LPM R20,Z+
	ST Y+,R20
	DEC R25
	BRNE loopgameoverreset2


	;%% Reinitialize the miss counter %%%%%%%
	LDI ZL,0x05
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25
	;%% Reinitialize the hit counter %%%%%%%
	LDI ZL,0x02
	LDI ZH,0x06
	LDI R25,0x0
	ST Z,R25

	RJMP main

ButtonLow3:
	RJMP checkreset2

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

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

	PUSH R23
	CALL write5bitsR23
	POP R23

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
	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow5
	ButtonHigh5:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x01
		RJMP follow5
	ButtonLow5:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x02
	follow5:

	;LDI YL,0x00 ;pointer to values in the data memory
	;LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry44
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry44:
	LDI R23,0b00011111 ;reuse R23, no link with previous R23
	ST Y,R23
RET

writeMiddleBit:
	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow24
	ButtonHigh24:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x01
		RJMP follow24
	ButtonLow24:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x02
	follow24:

	;LDI YL,0x00 ;pointer to values in the data memory
	;LDI YH,0x02
	ADD YL,R23 ;add the value of R23 to X to change at its position
	BRCC nocarry3
	LDI R23,0x01
	ADD YH,R23 ;if there is a carry
	nocarry3:
	LDI R23,0b00000100 ;reuse R23, no link with previous R23
	ST Y,R23
RET

write5zeros: ;takes R23 as argument
	IN R0,PINB ;do R0 = PINB
	BST R0,0; copy PB0 (bit 0 of PINB) to the T flag (the T of BST refers to flag T)
	BRTC ButtonLow4
	ButtonHigh4:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x01
		RJMP follow4
	ButtonLow4:
		LDI YL,0x00 ;pointer to values in the data memory
		LDI YH,0x02
	follow4:
	;LDI YL,0x00 ;pointer to values in the data memory
	;LDI YH,0x02
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

;%%%%%%%%%%%%%%%%%%%%% Victory Matrix %%%%%%%%%%%%%%%%%%%%%%%%%
victorybuffer:
.db 0b00000000, 0b00011110, 0b00011111, 0b00011111, 0b00010001, 0b00011111, 0b00010001, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00010001, 0b00010001, 0b00000100, 0b00010001, 0b00000000
.db 0b00000000, 0b00010010, 0b00010000, 0b00011111, 0b00010001, 0b00000100, 0b00010001, 0b00000000 
.db 0b00000000, 0b00011110, 0b00011111, 0b00010001, 0b00010001, 0b00000100, 0b00011111, 0b00000000
.db 0b00000000, 0b00010010, 0b00010000, 0b00010001, 0b00010001, 0b00000100, 0b00000100, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00010001, 0b00010001, 0b00000100, 0b00000100, 0b00000000
.db 0b00000000, 0b00011110, 0b00011111, 0b00010001, 0b00011111, 0b00000100, 0b00000100, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

.db 0b00000000, 0b00011111, 0b00011111, 0b00000000, 0b00000000, 0b00010001, 0b00011111, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00000000, 0b00000000, 0b00010001, 0b00010000, 0b00000000
.db 0b00000000, 0b00010001, 0b00011111, 0b00000000, 0b00000000, 0b00010001, 0b00010000, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00000000, 0b00000000, 0b00011111, 0b00010000, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00000000, 0b00000000, 0b00010000, 0b00010000, 0b00000000
.db 0b00000000, 0b00010001, 0b00010000, 0b00000000, 0b00000000, 0b00010000, 0b00010000, 0b00000000
.db 0b00000000, 0b00011111, 0b00010000, 0b00000000, 0b00000000, 0b00010000, 0b00011111, 0b00000000 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

;%%%%%%%%%%%%%%%%%%%%% Fail Matrix %%%%%%%%%%%%%%%%%%%%%%%%%
gameoverbuffer:
.db 0b00011111, 0b00011111, 0b00011011, 0b00011110, 0b00001111, 0b00010001, 0b00011110, 0b00011110
.db 0b00010000, 0b00010001, 0b00010101, 0b00010000, 0b00001001, 0b00010001, 0b00010000, 0b00010010
.db 0b00010000, 0b00011111, 0b00010101, 0b00010000, 0b00001001, 0b00010001, 0b00010000, 0b00011110
.db 0b00010000, 0b00010001, 0b00010001, 0b00011110, 0b00001001, 0b00010001, 0b00011110, 0b00011000
.db 0b00010110, 0b00010001, 0b00010001, 0b00010000, 0b00001001, 0b00010001, 0b00010000, 0b00010100
.db 0b00010010, 0b00010001, 0b00010001, 0b00010000, 0b00001001, 0b00001010, 0b00010000, 0b00010010
.db 0b00011110, 0b00010001, 0b00010001, 0b00011110, 0b00001111, 0b00000100, 0b00011110, 0b00010001 
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 ; "fake column", not to display

.db 0b00000000, 0b00000011, 0b00011110, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000100, 0b00000001, 0b00011111, 0b00011111, 0b00011111, 0b00011110, 0b00000000
.db 0b00000000, 0b00000100, 0b00000001, 0b00000000, 0b00000000, 0b00000100, 0b00000001, 0b00000000
.db 0b00000000, 0b00000111, 0b00011111, 0b00000000, 0b00000000, 0b00000111, 0b00011111, 0b00000000
.db 0b00000000, 0b00000100, 0b00000001, 0b00000000, 0b00000000, 0b00000100, 0b00000001, 0b00000000
.db 0b00000000, 0b00000100, 0b00000001, 0b00011111, 0b00011111, 0b00011111, 0b00011110, 0b00000000
.db 0b00000000, 0b00000011, 0b00011110, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 