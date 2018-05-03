
;if 0 pressed we can choose go up or down with the joystick and fire with button 7 with 2 different noise

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init
.ORG 0x0020 ; a mettre en dehors pour juste assigner le Timer0OverflowInterrupt a l'adresse 20
RJMP Timer0OverflowInterrupt

init: 
;%%%%% JOYSTICK AS INPUT %%%%%%%%;
CBI DDRC,1

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

;%%%%% LEDS AS OUTPUT %%%%%%%%
SBI DDRC,2 ; pin PC2 is an output
SBI PORTC,2 ; output Vcc => LED1 is turned off! (car la LED est active low, cf schema)
SBI DDRC,3 ; pin PC3 is an output
SBI PORTC,3 ; output Vcc => LED1 is turned off! (car la LED est active low, cf schema)

;%%%%% BUZZER %%%%%%%
SBI DDRB,1 ; pin PB1 is an output
CBI PORTB,1 ; output low to put the speaker off

;%%%%%%%%%%%% INITIALIZE SPEAKER AS OUTPUT  %%%%%%%%%%%%%%%%%%
SBI DDRB,1 ; pin PB1 is an output
;%%%%%%%%%%%% INITIALIZE SPEAKER TO 0  %%%%%%%%%%%%%%%%%%
CBI PORTB,1 ; output low to put the speaker off
;%%%%%%%%%%%% INITIALIZE INTERRUPTS %%%%%%%%%%%%%%%%%%%%%
SEI ; dedicated instruction for general interrupts
LDI R18, 0b00000000 ; disable interrupt for timer0, will be change if key is pressed
STS TIMSK0,R18
;%%%%%%%%%%%% INITIALIZE PRESCALER %%%%%%%%%%%%%%%%%%%%%%
; CBI TCCR0B,WGM02 ; 0b000 ;initialize timer --> no need car deja a zero
LDI R16, 0b00000100
OUT TCCR0B, R16 ; prescaler = 256

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


;%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
loop:
;take info from the joystick
	LDS R19, ADCH ; R16 [0,255]   8 bits in upper reg of 10 bit ADC, drop two lsb

;init thresholds
LDI R22,0xC8	;upper one 200
LDI R23,0x4B	;lower one 75

;%%%%%% put all rows to 1 at the beginning %%%%%%%%%%
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

SBI PORTC,3 ;shut down the LED at the end of the loop
SBI PORTC,2
LDI R18, 0b0000000 ; disable interrupt for timer0
STS TIMSK0,R18

RJMP loop
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Pressed4: CBI PORTC,3 ;put the lower LED on
Pressed8: CBI PORTC,2 ;put the upper LED on
RJMP loop
Pressed7: CBI PORTC,3
CBI PORTC,2
RJMP loop

CPressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
BPressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop

;press 0 ==> play with joystick
Pressed0:
	CP R22, R19
	;BREQ biggerthanHthreshold
	BRLO biggerthanHthreshold

	CP R19, R23
	;BREQ lowerthanLthreshold
	BRLO lowerthanLthreshold

	SBI PORTC,3
	SBI PORTC,2
RJMP loop


APressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
DPressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed3: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed2: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed1: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
EPressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed6: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed5: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
FPressed: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop
Pressed9: LDI R18, 0b00000001 ; activate interrupt for timer 0
STS TIMSK0,R18
RJMP loop


Timer0OverflowInterrupt:  
SBI PINB,1; by writing a 1 to the pin it will toggle the actual value of the port
;LDI R16, 0b00000100
;OUT TCCR0B, R16
MOV R17,R20;0xB8 ; start value for TCNT
OUT TCNT0,R17 ; on utilise OUT car R0 est categorise comme un registre I/O
RETI


biggerthanHthreshold:	;Down is on
	CBI PORTC,3 ;put the lower LED on
	SBI PORTC,2
	
	CBI PORTD,7;write a zero on the 4th row
	nop
	SBIS PIND,3
	RJMP Pressed72hit

RJMP loop

lowerthanLthreshold:
	CBI PORTC,2 ;put the up LED on
	SBI PORTC,3
	
	CBI PORTD,7;write a zero on the 4th row
	nop
	SBIS PIND,3
	RJMP Pressed72nothit
RJMP loop

Pressed72hit: 
	LDI R18, 0b00000001 ; activate interrupt for timer 0
	LDI R20,0xB8
	STS TIMSK0,R18
RJMP loop

Pressed72nothit: 
	LDI R18, 0b00000001 ; activate interrupt for timer 0
	LDI R20,0xD8
	STS TIMSK0,R18
RJMP loop