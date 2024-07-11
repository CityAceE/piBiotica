	include	"macros.s"
	include	"constants.s"

	format	binary as 'img'

	processor CPU32_V1 + CPU32_V2 + CPU32_V3 + CPU32_V4 + CPU32_V4T + CPU32_V6 + CPU32_V6T + CPU32_A + CPU32_E + CPU32_P

qemu		= 1
debug		= 1
fast		= 0	; 0 - Error Z80all error <adc = <-dc

    if qemu = 0
	org	0x00008000
    else
	org	0x00010000
    end if
	mov	sp, 0x00008000

iyi	equ	r0	; iy | i
mem	equ	r1	; mem
stlo	equ	r2	; stlo
pcff	equ	r3	; pc | ff
spfa	equ	r4	; sp | fa
bcfb	equ	r5	; bc | fb
defr	equ	r6	; de | fr
hlmp	equ	r7	; hl | mp
arvpref equ	r8	; ar | r7 halted_3 iff_2 im : prefix
ix	equ	r9	; ix

; Allow misaligned reads/writes and load a memory pointer
	mrc	p15, 0, r0, c1, c0, 0	; read control register
	orr	r0, r0, (1 shl 22)	; set the U bit (bit 22)
	mcr	p15, 0, r0, c1, c0, 0	; write control register

	ADRL	mem, MEMORY

; This is to set the video buffer to 352x264x4
	MOV32	r2, MBOXBASE
	add	r0, mem, ogetrev + 8
	mov	r4, 8
	bl	mbox
	ldr	r3, [mem, ogetrev + 20]
	cmp	r3, 4
	bcs	nrev1
nrev1:	mov	r4, 1
	add	r0, mem, ofbinfo + 1
	orr	r0, 0x40000000
	bl	mbox

; Zero the rows and pull up the columns (and the EAR port)
	MOV32	r0, GPBASE
	mov	r2, 001000001b	    ; configure speaker output
	str	r2, [r0, GPIO_GPFSEL0]
	mov	r2, 2
	str	r2, [r0, GPIO_GPPUD]
	WAIT	100
	ldr	r2, [filt]
	str	r2, [r0, GPIO_GPPUDCLK0]
	WAIT	100
	str	r12, [r0, GPIO_GPPUD]
	ldr	r3, [rows]
	str	r3, [r0, GPIO_GPCLR0]

; Set interrupts and timer
	ADRL	r0, irqhnd - 0x20   ;IRQ vector
	lsr	r0, 2
	orr	r0, 0xea000000
	str	r0, [r12, 0x18]

	MOV32	r0, STBASE
	ldr	r2, [r0, ST_CLO]
	add	r2, 0x100
	str	r2, [r0, ST_C1]
	MOV32	r0, INTBASE
	mov	r2, 0010b
	str	r2, [r0, INTENIRQ1]
	mov	r0, 0xd2	    ;IRQ mode, FIQ&IRQ disable
	msr	cpsr_c, r0
	mov	sp, 0x4000
	mov	r0, 0x53	    ;SVC mode, IRQ enable
    if qemu = 0
	msr	cpsr_c, r0
    end if

	bl	uart_init

; This is to create quick painting tables
	ldr	r6, [mem, opinrap]
	add	r6, 0x40000 + qemu * 0xc0000
	mov	r0, 255
gent1:	mov	r7, 255		    ; 256x256 table look up byte attribute + byte bitmap
gent2:	and	r3, r0, 7	    ; r3 = ink color
	tst	r0, 01000000b	    ; brightness activated?
	orrne	r3, 8		    ; transfer brightness to r3
	movs	r2, r0, lsl 25	    ; carry=flash
	mov	r2, r2, lsr 28	    ; r2 = background color
	add	r4, r7, 0x00008000  ; r4 = byte bitmap with marker bit in bit 15
	eorcs	r4, 0xff	    ; if there is flash I invert byte bitmap
    if qemu = 0
gent3:	tst	r4, 0x02	    ; read bit 1 from the bitmap and set it to flag zero
	mov	r5, r5, lsl 4	    ; nibble scroll
	addeq	r5, r2		    ; write background color in nibble
	addne	r5, r3		    ; write ink color in nibble
	tst	r4, 0x01	    ; read bit 0 from the bitmap and set it to flag zero
	mov	r5, r5, lsl 4	    ; nibble scroll
	addeq	r5, r2		    ; write background color in nibble
	addne	r5, r3		    ; write ink color in nibble
	mov	r4, r4, lsr 2	    ; shift the bitmap byte 2 bits to the right
	tst	r4, 0x0000ff00	    ; repeat 4 times checking the marker bit
	bne	gent3
	str	r5, [r6, -4]!	    ; write the 32 bits (8 pixels) calculated in table
    else
	add	r5, mem, opalette
	lsl	r2, 1
	ldrh	r2, [r5, r2]
	ldr	r3, [r5, r3, lsl 1]
	orr	r2, r3, lsl 16
gent3:	tst	r4, 0x01	    ; read bit 0 from the bitmap and set it to flag zero
	moveq	r5, r2
	movne	r5, r2, lsr 16
	strh	r5, [r6, -2]!	    ; write calculated pixel in table
	lsr	r4, 1		    ; shift the bitmap byte 1 bit to the right
	tst	r4, 0x0000ff00	    ; repeat 8 times checking the marker bit
	bne	gent3
    end if
	subs	r7, 1		    ; close the loop 256x256 times
	bpl	gent2
	subs	r0, 1
	bpl	gent1
	str	r6, [mem, opinrap]  ; save the table pointer (I've gone backwards) in opinrap

	include	"sna_loader.s"

; This renders the image

render: mov	r2, 0
drawr:	cmp	r2, 264
	bcs	alli
	tst	r2, 0x1f
	tsteq	r2, 0x100
	bne	noscan
	MOV32 	r11, table
	MOV32	r12, GPBASE
	add	r10, r11, r2, lsr 5
	ldr	r3, [r12, GPIO_GPLEV0]
	and	lr, r3, 0011100000000000000000000000b
	tst	r3, 100000000b
	orrne	lr, 0100000000000000000000000000b
	tst	r3, 010000000b
	orrne	lr, 1000000000000000000000000000b
	lsr	lr, 23
	strb	lr, [r10, 8]
	ldrb	r10, [r11, -1]	    ; last row
gf1:	add	r12, 4
	subs	r10, 10
	bcs	gf1
	sub	r10, r10, lsl 2
	add	r10, 2
	mov	r3, 111b
	ldr	lr, [r12, -4]
	bic	lr, r3, ror r10
	str	lr, [r12, -4]
	ldrb	r10, [r11, r2, lsr 5]
	strb	r10, [r11, -1]	    ; last row
	MOV32	r12, GPBASE
gf2:	add	r12, 4
	subs	r10, 10
	bcs	gf2
	sub	r10, r10, lsl 2
	add	r10, 2
	ldr	lr, [r12, -4]
	bic	lr, r3, ror r10
	mov	r3, 0x001
	orr	lr, r3, ror r10
	str	lr, [r12, -4]
noscan: mov	r3, 0
	ldr	r10, [mem, opoint]
	mov	r11, 176 + 528 * qemu
	smlabb	r10, r11, r2, r10
drawp:	sub	r11, r3, 6
	cmp	r11, 32
	bcs	aqui
	sub	r12, r2, 36
	cmp	r12, 192
	bcs	aqui
	and	lr, r12, 11111000b
	orr	lr, r11, lr, lsl 2
	add	lr, 0x5800
	ldrb	lr, [mem, lr]
	add	r11, r12, lsl 5
	eor	r11, r12, lsl 2
	bic	r11, 0000011100000b
	eor	r11, r12, lsl 2
	eor	r11, r12, lsl 8
	bic	r11, 0011100000000b
	eor	r11, r12, lsl 8
	add	r11, 0x4000
	ldrb	r11, [mem, r11]
	tst	lr, 0x80
	tstne	iyi, 0x80
	eorne	lr, 0x80
	add	r11, r11, lr, lsl 8
	ldr	r12, [mem, opinrap]
    if qemu = 0
	ldr	r11, [r12, r11, lsl 2]
aqui:	ldrcs	r11, [border]
    else
	add	r12, r11, lsl 4
	ldr	r11, [r12], 4
	str	r11, [r10], 4
	ldr	r11, [r12], 4
	str	r11, [r10], 4
	ldr	r11, [r12], 4
	str	r11, [r10], 4
	ldr	r11, [r12], 4
	b	faqui
aqui:	ldr	r11, [border]
	str	r11, [r10], 4
	str	r11, [r10], 4
	str	r11, [r10], 4
    end if
faqui:	str	r11, [r10], 4
	add	r3, 1
	cmp	r3, 44
	bne	drawp
alli:	add	lr, mem, otmpr2
	swp	r2, r2, [lr]
	add	lr, 4
	swp	r3, r3, [lr]

;==============================	
; bp:
	; bl	 regs
; hook:	b	hook	
;==============================

	bl	execute
	add	stlo, 224
again:	ldr	lr, [flag]
	subs	lr, 2
    if qemu = 0
	bne	again
    end if 
	str	lr, [flag]
	add	lr, mem, otmpr2
	swp	r2, r2, [lr]
	add	lr, 4
	swp	r3, r3, [lr]
	add	r2, 1

	cmp	r2, 312
	bne	drawr

	mov	r11, 4
	uadd8	iyi, iyi, r11
	add	lr, mem, otmpr2
	swp	r2, r2, [lr]
	add	lr, 4
	swp	r3, r3, [lr]
	tst	arvpref, 0x00000400
	beq	exec5
	bic	arvpref, 0x00000400
	tst	arvpref, 0x00000800
	bicne	arvpref, 0x00000800
	addne	pcff, 0x00010000
	mov	r11, pcff, lsr 16
	sub	spfa, 0x00020000
	mov	r10, spfa, lsr 16
	strh	r11, [mem, r10]
	mov	r11, 0x00010000
	uadd8	arvpref, arvpref, r11
	movs	r11, arvpref, lsl 22
	beq	exec3
	bmi	exec4
	sub	stlo, 1
exec3:	mov	r11, 0x00380000
	pkhbt	pcff, pcff, r11
	sub	stlo, 12
	b	exec5
exec4:	and	r11, iyi, 0x0000ff00
	orr	r11, 0x000000ff
	ldrh	r10, [mem, r11]
	pkhbt	pcff, pcff, r10, lsl 16
	sub	stlo, 19
exec5:	add	lr, mem, otmpr2
	swp	r2, r2, [lr]
	add	lr, 4
	swp	r3, r3, [lr]
	b	render

irqhnd: push	{r0, r1}
	MOV32	r0, STBASE
	mov	r1, 0010b
	str	r1, [flag]
	str	r1, [r0, ST_CS]
	ldr	r1, [r0, ST_CLO]
	add	r1, 64
	str	r1, [r0, ST_C1]
	pop	{r0, r1}
	subs	pc, lr, 4

	include "debugger.s"

; pool of constants

flag:	dw	0
		; 7654321098765432109876543210
rows:	dw	001000011001100000111000010101b
lastrw: db	17				; Нигде не используется?
table:	db	10, 9, 11, 22, 27, 4, 15, 17	    ;15->18
keys:	db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
filt:	dw	001011111001100000111110011101b
	align	4

in_:	tst	r0, 1
	movne	r0, 0xff
	bxne	lr
	lsr	r1, r0, 8
	mov	r0, 0x1f
    if qemu = 0
	MOV32	r11, keys
	orr	r1, 0x100
in1:	ldrb	r2, [r11], 1
	lsrs	r1, 1
	andcc	r0, r2
	bne	in1
	MOV32	r2, GPBASE
	ldr	r1, [r2, GPIO_GPLEV0]
	orr	r1, 10100b
    end if
	and	r1, 11100b
	orr	r0, r1, lsl 3
	bx	lr

out:	tst	r0, 1
	bxne	lr
	and	r3, r1, 0x7
    if qemu = 0
	ldr	r2, [c1111]
	mul	r3, r2, r3
    else
	ADRL	r2, MEMORY
	add	r2, r3, lsl 1
	ldrh	r3, [r2, opalette]
	orr	r3, r3, lsl 16
    end if
	str	r3, [border]
	MOV32	r2, GPBASE
	mov	r3, 0101b
	tst	r1, 0x10
	strne	r3, [r2, GPIO_GPSET0]
	streq	r3, [r2, GPIO_GPCLR0]
	bx	lr
    if qemu = 0
c1111:	dw	0x11111111
border: dw	0x77777777
    else
border: dw	10111101111101111011110111110111b
    end if

mbox:	ldr	r3, [r2, MAIL_STATUS]
	tst	r3, 0x80000000
	bne	mbox
	str	r0, [r2, MAIL_WRITE]
mbox1:	ldr	r3, [r2, MAIL_STATUS]
	tst	r3, 0x40000000
	bne	mbox1
	ldr	r3, [r2, MAIL_READ]
	and	r3, 0x0000000f
	cmp	r3, r4
	bne	mbox1
	bx	lr

	include	"z80.s"
	
	include	"uart1.s"

	align	16

getrev: dw	7 * 4
	dw	0
	dw	0x00010002
	dw	4
	dw	0
	dw	0
	dw	0
	dw	0

fbinfo: dw	1024 - 672 * qemu   ; 0 Width
	dw	768 - 504 * qemu    ; 4 Height
	dw	352		    ; 8 vWidth
	dw	264		    ; 12 vHeight
	dw	0		    ; 16 GPU - Pitch
	dw	4 + 12 * qemu	    ; 20 Bit Depth
	dw	0		    ; 24 X
	dw	0		    ; 28 Y
point:	dw	0		    ; 32 GPU - Pointer
	dw	0		    ; 36 GPU - Size

	      ; rrrrrggggggbbbbb
palette:dh	0000000000000000b
	dh	0000000000010111b
	dh	1011100000000000b
	dh	1011100000010111b
	dh	0000010111100000b
	dh	0000010111110111b
	dh	1011110111100000b
	dh	1011110111110111b
	dh	0000000000000000b
	dh	0000000000011111b
	dh	1111100000000000b
	dh	1111100000011111b
	dh	0000011111100000b
	dh	0000011111111111b
	dh	1111111111100000b
	dh	1111111111111111b

pinrap: dw	MEMORY + 0x10026
tmpr2:	dw	224
tmpr3:	dw	0
	db	0, 0, 0
a_:	db	0
fa_:	dh	0
fb_:	dh	0
ff_:	dh	0
fr_:	dh	0
c_:	db	0
b_:	db	0
e_:	db	0
d_:	db	0
dummy1: dh	0
l_:	db	0
h_:	db	0

oc_		= -8		; -8
off_		= oc_ - 4	; -12
ofa_		= off_ - 4	; -16
oa_		= ofa_ - 1	; -17
otmpr3		= oa_ - 7	; -24
otmpr2		= otmpr3 - 4	; -28
opinrap		= otmpr2 - 4	; -32
opalette	= opinrap - 32	; -64
opoint		= opalette - 8	; -72
ofbinfo		= opoint - 32	; -104
ogetrev		= ofbinfo - 32	; -136

MEMORY:
	file	"48.rom"
	
	; file	"./SNA/Cybernoid 1.sna"
	; file	"./SNA/Action Reflex.sna"
	; file	"./SNA/Action.sna"
	; file	"./SNA/Freddy.sna"
	file	"./SNA/Manic Miner.sna"
	; file	"./SNA/test.sna"
	; file	"./SNA/ZXEmulSnap48.Sna"
	; file	"./SNA/SAI_COMB.SNA"		; Reset
	; file	"./SNA/Vectrom.sna"		; Border effect
	; file	"./SNA/ZFCR.SNA"
	; file	"./SNA/ZXEmulSnap48.Sna"	; Cybernoid
	; file	"./SNA/ENDURORA.SNA"
	; file	"./SNA/FARLGT.SNA"
	; file	"./SNA/zexall.sna"
	; file	"./SNA/zexdoc.sna"
	; file	"./SNA/BACKTOSK.SNA"

	; GPIO23  D0
	; GPIO24  D1
	; GPIO25  D2
	; GPIO8	  D3
	; GPIO7	  D4

	; GPIO18  A15
	; GPIO4	  A14
	; GPIO17  A8
	; GPIO27  A13
	; GPIO22  A12
	; GPIO10  A9
	; GPIO9	  A10
	; GPIO11  A11

	; GPIO3	  EAR
	; GPIO2	  SPEAKER
