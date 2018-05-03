
.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init

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

;%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
loop:
	
	;take info from the joystick
	LDS R21, ADCH ; R16 [0,255]   8 bits in upper reg of 10 bit ADC, drop two lsb

	;init thresholds
	LDI R22,0xC8	;upper one 200
	LDI R23,0x4B	;lower one 75

	CP R22, R21
	;BREQ biggerthanHthreshold
	BRLO biggerthanHthreshold

	CP R21, R23
	;BREQ lowerthanLthreshold
	BRLO lowerthanLthreshold

	SBI PORTC,3
	SBI PORTC,2

	RJMP loop

biggerthanHthreshold:
	CBI PORTC,3 ;put the lower LED on
	SBI PORTC,2
	RJMP loop

lowerthanLthreshold:
	CBI PORTC,2 ;put the up LED on
	SBI PORTC,3
	
	RJMP loop

	
