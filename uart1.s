; Макросы
macro	uart_mem_write8 addr, val {
	MOV32	r11, addr
	mov	r12, val
	str	r12, [r11]
}

macro	uart_mem_write16 addr, val {
	MOV32	r11, addr
	mov	r12, val and 0x00ff
	add	r12, val and 0xff00
	str	r12, [r11]
}

macro	uart_mem_read addr {
	MOV32	r11, addr
	ldr	r11, [r11]
}

;-----------------------
; Инициализация UART1
uart_init:
	uart_mem_read PERIPHERAL_BASE + GPIO_BASE + GPIO_GPFSEL1
	bic	r12, r11, 0x3F000
	orr	r12, r12, 0x12000
	uart_mem_write8 PERIPHERAL_BASE + GPIO_BASE + GPIO_GPFSEL1, r12

	uart_mem_write8 PERIPHERAL_BASE + GPIO_BASE + GPIO_GPPUD, 0
	WAIT 150
	uart_mem_write8 PERIPHERAL_BASE + GPIO_BASE + GPIO_GPPUDCLK0, 0xC000
	WAIT 150
	uart_mem_write8 PERIPHERAL_BASE + GPIO_BASE + GPIO_GPPUDCLK0, 0

	uart_mem_write8 AUX_ENABLES, 1		; Enable mini UART. Then mini UART register can be accessed.
	uart_mem_write8 AUX_MU_CNTL_REG, 0	; Disable transmitter and receiver during configuration.
	uart_mem_write8 AUX_MU_IER_REG, 0	; Disable interrupt because currently you don’t need interrupt.
	uart_mem_write8 AUX_MU_LCR_REG, 3	; Set the data size to 8 bit.
	uart_mem_write8 AUX_MU_MCR_REG, 0	; Don’t need auto flow control.
	uart_mem_write16 AUX_MU_BAUD_REG, 270	; Set baud rate to 115200 (systemx clock freq/(8×(AUX_MU_BAUD+1))
	; uart_mem_write8 AUX_MU_IIR_REG, 6	; No FIFO (без этой стоки нет лишних символов вначале)
	uart_mem_write8 AUX_MU_CNTL_REG, 3	; Enable the transmitter and receiver.

	bx	lr
	
;-------------------------------
; Чтение байта в r4_ из UART1
uart1_read:
	MOV32	r12, AUX_MU_LSR_REG
uart1_read_01:
	ldrb	r11, [r12]
	tst	r11, 0x01
	beq	uart1_read_01
	MOV32	r12, AUX_MU_IO_REG
	ldrb	r11, [r12]
	bx	lr

;-------------------------------
; Запись байта из r11 в UART1
uart1_send:
	push	{lr}
	MOV32	r10, AUX_MU_LSR_REG
uart1_send_01:
	ldrb	lr, [r10]
	tst	lr, 0x20
	beq	uart1_send_01
	MOV32	r10, AUX_MU_IO_REG
	strb	r11, [r10]
	pop	{pc}
