; Загружаем регистры
	ADRL	r12, MEMORY
	mov	r2, r12
	add	r11, r12, 0x4000	; В r11 начало SNA

	; Устанавливаем бордюр
	ldrb	r3, [r11, 26]
	and	r3, r3, 0x7
    if qemu = 0
	ldr	r4, [c1111]
	mul	r3, r4, r3
    else
	; ADRL	r2, MEMORY
	add	r2, r3, lsl 1
	ldrh	r3, [r2, opalette]
	orr	r3, r3, lsl 16
    end if
	str	r3, [border]		; Border

	; Получаем SP
	ldr	spfa, [r11, 23-2]

	add	r12, spfa, lsr 16
	add	r12, 27
	ldr	pcff, [r12, -2]
	
	add	spfa, 0x00020000	; Корректировка SP

	ldrh	iyi, [r11, 15]		; IY
	lsl	iyi, 16
	ldrb	r12, [r11]		
	orr	iyi, r12, lsl 8		; I
	
	ldr	bcfb, [r11, 13-2]	; BC
	
	ldr	defr, [r11, 11-2 ]	; DE	
	
	ldrh	hlmp, [r11, 9]		; HL
	lsl	hlmp, 16
	orr	hlmp, pcff, lsr 16	; MP - копия PC
	
	ldr	ix, [r11, 17-2]  	; IX

	ADRL 	r12, c_
	ldrh	lr, [r11, 5]		
	strh	lr, [r12]		; BC'

	ldrh	lr, [r11, 3]		
	strh	lr, [r12, 2]		; DE'

	ldrh	lr, [r11, 1]		
	strh	lr, [r12, 6]		; HL'

	ldrh 	r12, [r11, 7]
	bl	af_disasm		; AF'

	bl	swap_af
	ldrh 	r12, [r11, 21]
	bl	af_disasm		; AF

	ldrb 	r12, [r11, 20]
	orr	arvpref, r12, lsl 16	; R

	ldrb 	r12, [r11, 25]
	orr	arvpref, r12, lsl 8	; IM
	
	ldrb 	r12, [r11, 19]
	tst	r12, 4
	orrne	arvpref, 0xC00		; IFF
	
	str	pcff, [mem, otmpr3]	; PC


; Перемещаем код на место
	add	r10, r11, 27
	mov 	r12, 0xc000 / 4
load_sna_01:	
	ldr	lr,[r10]
	str	lr,[r11]
	add	r10, 4
	add	r11, 4
	subs	r12, 1
	bne	load_sna_01

	b	sna_exit
	
af_disasm:
	; Раскидываем AF по регистрам (POP AF)
	rev16	r12, r12
	bic	arvpref, 0xff000000
	orr	arvpref, r12, lsl 24	; arvpref = AAxxxxxx
	
	uxtb	r12, r12, ror 8
	mvn	r10, r12
	and	r10, 0x00000040
	pkhtb	defr, defr, r10		; defr = xxxx0040 (ZERo flag)
	
	orr	r12, r12, lsl 8
	pkhtb	pcff, pcff, r12		; pcff = xxxxFFFF
	
	and	r10, r12, 0x00000004
	eor	r12, r10, lsl 5
	and	r12, 0xffffff7f
	eor	r12, r10, lsl 5
	pkhtb	bcfb, bcfb, r12		; bcfb = xxxxFF7F (7 бит = P/V)
	
	uxtb	r12, r12
	pkhtb	spfa, spfa, r12		; spfa = xxxx007F (7 бит = P/V)
	bx	lr
	
sna_exit:
	