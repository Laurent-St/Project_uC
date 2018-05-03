;%%%%%%%%%%%%%%%%%%%%%
;SAVE MAIN 28/04
;%%%%%%%%%%%%%%%%%%%%
;
; TestBuffer.asm
;
; Created: 23-04-18 13:34:45
; Author : Laurent Storrer & Benjamin Wauthion
;

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init

;Program memory cannot be changed at runtime, while data memory can. So what we do is to define values at "initbuffer" label to which 

init:
;%%%%%%%%%%%%%%%%%%%%%%%%% POINTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LDI ZL,low(initbuffer<<1) ;pointer to values in the program memory
LDI ZH,high(initbuffer<<1)

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

main: 
LDI R17,0x7 ;DON'T MODIFY R17 AFTER

LDI XL,0x00 ;pointer to values in the data memory
LDI XH,0x01

; because of the shift register, the first data that you input will be displayed the last, thus we begin by sending the last row of the data matrix
; and we decrement the counter
;ADIW X,0x40 ;=56

;%%% ADDITION OF 64 to X, need carry addition because ADIW doesn't work because 64 is too high %%%%%
LDI R20,0x40;=64=56+8
ADD XL,R20
BRCC nocarry
LDI R20,0x01
ADD XH,R20 ;if there is a carry
nocarry:
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	rowloop:
		SBIW X,0x8 ;substract immediate
		;SBI PORTB,3

		;%%%%%% COLUMNS %%%%%%%%%%%
		;correspond to first line of blocks
		LDI R16,0x8 ;compteur: 8  
		firstloop1: 
			LD R21,X+
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop1 ;branch if R16 is 0

		;correspond to second line of blocks
		ADIW X,0x38	;56 in block term
		LDI R16,0x8 ;compteur: 8  
		firstloop2:
			LD R21,X+
			CALL write5bits
			DEC R16 ;decrement counter
		BRNE firstloop2 ;branch if R16 is 0


		LDI R16,0x7
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
			DEC R18
			BRNE waitloop

		CBI PORTB,4 

		DEC R17
		BRNE rowloop

	RJMP main


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
	DEC R22
	BRNE loop_write5
RET
;%%%%%%%%%%%%%%%%%% BUFFER STORED IN THE PROGRAM MEMORY: CANNOT BE CHANGED AT RUNTIME %%%%%%%%%%%%%%%%%%%%%
;Attention only the 5 LSB of each compartment will be used for the 5 columns
initbuffer:
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000

.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000
.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000




