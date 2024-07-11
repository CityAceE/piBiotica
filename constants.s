PERIPHERAL_BASE	= 0x20000000	; Peripheral Base Address Raspberry Pi 1 & Zero

; GPIO 14, 15 can be both used for mini UART
GPIO_BASE	= 0x200000	; GPIO Base Address
GPIO_GPFSEL0	= 0x00		; GPIO Function Select 0
GPIO_GPFSEL1	= 0x04		; GPIO Function Select 1
GPIO_GPSET0	= 0x1c		; GPIO Pin Output Set 0
GPIO_GPCLR0	= 0x28		; GPIO Pin Output Clear 0
GPIO_GPLEV0	= 0x34		; GPIO Pin Level 0
GPIO_GPPUD	= 0x94		; GPIO Pin Pull-up/down Enable
GPIO_GPPUDCLK0	= 0x98		; GPIO Pin Pull-up/down Enable Clock 0

AUX_ENABLES	= PERIPHERAL_BASE + GPIO_BASE + 0x15004 ; Auxiliary enables
AUX_MU_IO_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x15040 ; Mini UART I/O Data
AUX_MU_IER_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x15044 ; Mini UART Interrupt Enable
AUX_MU_IIR_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x15048 ; Mini UART Interrupt Identify
AUX_MU_LCR_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x1504c ; Mini UART Line Control
AUX_MU_MCR_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x15050 ; Mini UART Modem Control
AUX_MU_LSR_REG	= PERIPHERAL_BASE + GPIO_BASE + 0x15054 ; Mini UART Line Status
AUX_MU_CNTL_REG = PERIPHERAL_BASE + GPIO_BASE + 0x15060 ; Mini UART Extra Control
AUX_MU_BAUD_REG = PERIPHERAL_BASE + GPIO_BASE + 0x15068 ; Mini UART Baudrate

GPBASE		= PERIPHERAL_BASE + GPIO_BASE

MBOXBASE	= PERIPHERAL_BASE + MAIL_BASE
MAIL_BASE   	= 0xb880	; Mailbox Base Address
MAIL_READ   	= 0x00		; Mailbox Read Register
MAIL_STATUS 	= 0x18		; Mailbox Status Register
MAIL_WRITE  	= 0x20		; Mailbox Write Register

STBASE		= PERIPHERAL_BASE + 0x3000	; System timers base address
ST_CS		= 0x00				; System Timer Control/Status 
ST_CLO		= 0x04				; System Timer Counter Lower 32 bits 
ST_C1		= 0x10				; System Timer Compare 1 

INTBASE		= PERIPHERAL_BASE + 0xb000	; Interrupt register base address
INTENIRQ1	= 0x210				; Enable IRQs 1
