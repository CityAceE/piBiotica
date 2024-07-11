if debug = 1

regs:	push	{r0, r12, lr}
	push	{r0}
	push	{r0}

	adr	r10, regs_txt

	add	r10, 3
	mov	r0, pcff, lsr 16
	bl	hexh			; PC

	add	r10, 4
	mov	r0, spfa, lsr 16
	bl	hexh			; SP

	add	r10, 5
	mov	r0, ix, lsr 16
	bl	hexh			; IX
	
	add	r10, 4
	pop	{r0}
	lsr	r0, 16
	bl	hexh			; IY

	add	r10, 5
	mov	r0, hlmp, lsr 16
	bl	hexh			; HL

	add	r10, 4
	ADRL 	r0, l_
	ldrh	r0, [r0]
	bl	hexh			; HL`

	add	r10, 5
	mov	r0, defr, lsr 16 
	bl	hexh			; DE

	add	r10, 4
	ADRL 	r0, e_
	ldrh	r0, [r0]
	bl	hexh			; DE'

	add	r10, 5
	mov	r0, bcfb, lsr 16
	bl	hexh			; BC

	add	r10, 4
	ADRL 	r0, c_
	ldrh	r0, [r0]
	bl	hexh			; BC'

	add	r10, 5
	mov	r0, arvpref, lsr 16
	bl	af_assemble
	bl	hexh			; AF

	add	r10, 4
	bl	swap_af
	bl	af_assemble
	bl	hexh			; AF'
	bl	swap_af

	add	r10, 5
	pop	{r12}
	and	r12, 0xff00
	mov	r0, arvpref, lsr 16
	and	r0, 0xff
	orr	r0, r12
	bl	hexh			; IR

	add	r10, 4
	mov	r0, arvpref, lsr 8
	and	r0, 11b
	bl	hexb			; IM

	add	r10, 7
	mov	r0, arvpref, lsr 10
	and	r0, 1b
	bl	hexb			; IFF1

	add	r10, 6
	mov	r0, arvpref, lsr 11
	and	r0, 1b
	bl	hexb			; IFF2

	bl	string_otput

	pop	{r0, r12, pc}

; Собирает AF в R0 (аналог PUSH AF)
af_assemble:
	push	{r10, lr}
	
	; Собираем флаговый регистр (из команды PUSH AF)
	and	lr, arvpref, 0xff000000
	; lr = AA000000
	
	and	r11, pcff, 0x000000a8
	orr	r11, lr, r11, lsl 16
	; r11 = AA(S 5 3)0000
	
	movs	lr, pcff, lsr 9
	orrcs	r11, 0x00010000
	; r11 = AA(+C)0000

	movs	lr, bcfb, lsr 10
	orrcs	r11, 0x00020000
	; r11 = AA(+N)0000

	movs	lr, defr, lsl 16
	orreq	r11, 0x00400000
	; r11 = AA(+Z)0000
	
	eor	lr, defr, spfa
	eor	r10, bcfb, bcfb, lsr 8
	eor	lr, r10
	movs	lr, lr, lsr 5
	orrcs	r11, 0x00100000
	; r11 = AA(+H)0000
	
	tst	spfa, 0x00000100
	beq	over51
	ADRL	r0, cb34
	ldr	lr, [r0]
	eor	r10, defr, defr, lsr 4
	tst	lr, lr, ror r10
	orrmi	r11, 0x00040000
	; r11 = AA(+P/V)0000
	
	b	over52
over51:	eor	lr, spfa, defr
	eor	r10, bcfb, defr
	and	lr, r10
	movs	lr, lr, lsr 8
	orrcs	r11, 0x00040000
	; r11 = AA(+P/V)0000

over52:	
	mov	r0, r11, lsr 16
	
	pop	{r10, pc}
end if


; Аналог команды EX AF,AF'
swap_af:
	push 	{r11, lr}
	mov	lr, arvpref, lsr 24	; Внизу LR - регистр A
	
	add	r11, mem, oa_		; В r11 - _oa
	swpb	lr, lr, [r11]		; Обмениваем _oa и того, чтобы было A
	
	; В _oa - текущее значение A
	; Внизу LR - то, что было в _oa 
	
	bic	arvpref, 0xff000000	; Очищаем всё, кроме верха
	orr	arvpref, lr, lsl 24	; Ставим A содержимое LR на место
	
	; На этом обмен A и A' завершён
	
	; Переходим к обмену F и F'
	
	pkhbt	r11, spfa, bcfb, lsl 16 ; В r11 - fbfa
	add	lr, mem, ofa_		; В LR - адрес ofa_
	swp	r11, r11, [lr]		; Обмениваем
	pkhtb	spfa, spfa, r11		; Раскидываем обменянные fa и fb
	pkhtb	bcfb, bcfb, r11, asr 16	; по  нужным местам

	pkhbt	r11, pcff, defr, lsl 16	; В r11 - frff
	add	lr, mem, off_		; В LR - адрес off_
	swp	r11, r11, [lr]		; Обмениваем
	pkhtb	pcff, pcff, r11		; Раскидываем обменянные fа и fr
	pkhtb	defr, defr, r11, asr 16	; по  нужным местам
	
	pop	{r11, pc}

if debug = 1
hexb:	push	{r11, r12, lr}
	mov	r11, r0, ror 8
	mov	r12, 2
	b	hexh1

hexs:	push	{r11, r12, lr}
	mov	r11, r0
	mov	r12, 8
	b	hexh1

hexh:	push	{r11, r12, lr}
	mov	r11, r0, ror 16
	mov	r12, 4
	
hexh1:	mov	r11, r11, ror 28
	and	r0, r11, 0x0f
	cmp	r0, 10
	addcs	r0, 7
	add	r0, 0x30
	
	strb	r0, [r10]
	add	r10, 1
	subs	r12, 1
	bne	hexh1

	pop	{r11, r12, pc}

string_otput:
	push	{lr}
	adr	r12, regs_txt
string_otput_02:
	ldrb	r11, [r12]
	cmp	r11, 0
	beq	string_otput_01

	bl	uart1_send

	add	r12, 1
	b	string_otput_02
	
string_otput_01:
	pop	{pc}
    
regs_txt:    
	db	"PC 0000 SP 0000", 10, 13
	db	"IX 0000 IY 0000", 10, 13
	db	"HL 0000 HL'0000", 10, 13
	db	"DE 0000 DE'0000", 10, 13
	db	"BC 0000 BC'0000", 10, 13
	db	"AF 0000 AF'0000", 10, 13
	db	"IR 0000 IM 00", 10,13
	db	"IFF1 00 IFF2 00", 10, 13
	db	27, "M", 27, "M", 27, "M", 27, "M", 27, "M", 27, "M", 27, "M", 27, "M"
	db	0
	align	4

end if	