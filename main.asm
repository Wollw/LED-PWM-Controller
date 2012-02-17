;;
;;	Multicolor LED Controller
;;
;;	This is firmware for an attiny4/5/9/10 for causing a multicolor LED
;;	to change between two colors.  PB0 is connected to one pin of the LED
;;	and PB1 to the other.  PB0 is used as a PWM output which is controlled
;;	by the state of PB2.  When PB2 goes low the LED's color attached to
;;	PB0 fades out.  When PB2 goes high again the color fades back in.
;;
.NOLIST
.INCLUDE "include/defs.inc"
.LIST

.DEF	TEMP0	=	r16
.DEF	TEMP1	=	r17
.DEF	OCRVAL	=	r18

.EQU	PWM_MIN	=	0x02
.EQU	PWM_MAX	=	0xfe

.ORG	0x0000
	rjmp	RESET
.ORG	0x0004
	rjmp	TIM0_OVF
.ORG	0x0040

RESET:
	;; Setup the stack
	;;ldi		TEMP0,	high(RAMEND)
	;;out		SPH,	TEMP0
	;;ldi		TEMP0,	low(RAMEND)
	;;out		SPL,	TEMP0

	;; Clock prescaler of 256 to save power (?)
	ldi		TEMP0,	0xd8
	ldi		TEMP1,	0b1000
	out		CCP,	TEMP0
	out		CLKPSR,	TEMP1

	;; PB2 is our input used to check if we should
	;; fade the PWM color in or out
	ldi		TEMP0,	0b0100
	out		PUEB,	TEMP0

	;; PB0 and PB1 are outputs for the LED
	;; PB0 is controlled usign Fast PWM so we only turn PB1 on here
	ldi		TEMP0,	0b0011
	out		DDRB,	TEMP0
	ldi		TEMP0,	0b0010
	out		PORTB,	TEMP0

	;; 8-bit Fast PWM on OC0A so we can fade 
	ldi		TEMP1,	0b10000001
	ldi		TEMP0,	0b00001001
	out		TCCR0A,	TEMP1
	out		TCCR0B,	TEMP0

	;; interrupt on timer overflow
	;; which is when we update the PWM reference
	ldi		TEMP0,	0b001
	out		TIMSK0,	TEMP0

	;; Start Fast PWM with a low reference
	;; meaning it starts out close to off
	ldi		TEMP1,	0x00
	ldi		TEMP0,	PWM_MIN
	out		OCR0AH,	TEMP1
	out		OCR0AL,	TEMP0
	ldi		OCRVAL,	PWM_MIN

	sei
	rjmp	LOOP

;; Loop forever
LOOP:
	rjmp    LOOP


;; When timer overflows increment or decrement based on state of PB2.
;; We don't increment if we're at PWM_HIGH and don't decrement if 
;; we're at PWM_LOW.  If PB2 is high we try to increment, otherwise we
;; try to decrement.
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

;; Increment if we aren't at PWM_MAX already
INC_OCRVAL:
	cpi		OCRVAL,	PWM_MAX
	brsh	INC_OCRVAL_EXIT
	inc		OCRVAL
INC_OCRVAL_EXIT:
	rjmp	TIM0_OVF_EXIT

;; Decrement if we aren't at PWM_MIN already
DEC_OCRVAL:
	cpi		OCRVAL,	PWM_MIN
	brlo	DEC_OCRVAL_EXIT
	dec		OCRVAL
DEC_OCRVAL_EXIT:
	rjmp	TIM0_OVF_EXIT
