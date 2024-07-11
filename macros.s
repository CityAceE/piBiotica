; Макросы

; adr для 64 кб
macro	ADRL 	reg, address {
	if address - $ > 0
		adr reg, address - ((address - $ - 4) and 0xffffff00)
		add reg, reg, (address - $) and 0xffffff00
	else
		adr reg, address + (($ - address  + 4) and 0xffffff00)
		sub reg, reg, ($ - address) and 0xffffff00
	end if
}

; mov для 32 бит
macro	MOV32	reg, value {
	ldr	reg, [pc]
	b	@f
	dw	value
@@:
}

macro	WAIT	count {
	mov	r12, count
@@:
	subs	r12, 1
	bne	@b
}
