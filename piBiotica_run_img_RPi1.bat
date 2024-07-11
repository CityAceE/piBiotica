 @set file=piBiotica

"c:\Program Files\qemu\qemu-system-arm.exe" -M raspi1ap -serial null -serial stdio -kernel %file%.img

@pause 0	