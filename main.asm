.NOLIST
.INCLUDE "include/defs.inc"
.LIST

.DEF	TEMP0	=	r16
.DEF	TEMP1	=	r17
.DEF	OCRVAL	=	r19
.DEF	DIR		=	r18

.ORG	0x0000
	rjmp	RESET
.ORG	0x0004
	rjmp	TIM0_OVF
.ORG	0x0040

RESET:
	;; Setup the stack
	ldi		TEMP0,	high(RAMEND)
	out		SPH,	TEMP0
	ldi		TEMP0,	low(RAMEND)
	out		SPL,	TEMP0

	;; Clock prescaler of 256
	ldi		TEMP0,	0xd8
	ldi		TEMP1,	0b1000
	out		CCP,	TEMP0
	out		CLKPSR,	TEMP1


	;; PB2 is our input
	ldi		TEMP0,	0b0100
	;out		PUEB,	TEMP0

	;; PB0 and PB1 are outputs
	ldi		TEMP0,	0b0011
	out		DDRB,	TEMP0
	;; PB1 is always on
	ldi		TEMP0,	0b0010
	out		PORTB,	TEMP0

	;; Turn Pin Change Interrupts on for PB1
	ldi		TEMP0,	0b0001
	out		PCICR,	TEMP0
	ldi		TEMP0,	0b0100
	out		PCMSK,	TEMP0

	;; 8-bit Fast PWM on OC0A
	ldi		TEMP1,	0b10000001
	ldi		TEMP0,	0b00001001
	out		TCCR0A,	TEMP1
	out		TCCR0B,	TEMP0

	ldi		TEMP1,	0x00
	ldi		TEMP0,	0x10
	out		OCR0AH,	TEMP1
	out		OCR0AL,	TEMP0

	;; interrupt on timer overflow
	ldi		TEMP0,	0b001
	out		TIMSK0,	TEMP0

	ldi		DIR,	0x00
	ldi		OCRVAL,	0x20


	sei
	rjmp	LOOP

LOOP:
	rjmp    LOOP

TIM0_OVF:
	cli

	ldi		TEMP1,	0x00
	
	sbic	PINB,	2
	rjmp	INC_OCRVAL
	rjmp	DEC_OCRVAL

TIM0_OVF_EXIT:
	out		OCR0AH,	TEMP1
	out		OCR0AL,	OCRVAL
	sei
	reti


INC_OCRVAL:
	cpi		OCRVAL,	0xfe
	brsh	INC_OCRVAL_EXIT
	inc		OCRVAL
INC_OCRVAL_EXIT:
	rjmp	TIM0_OVF_EXIT

DEC_OCRVAL:
	cpi		OCRVAL,	0x02
	brlo	DEC_OCRVAL_EXIT
	dec		OCRVAL
DEC_OCRVAL_EXIT:
	rjmp	TIM0_OVF_EXIT
