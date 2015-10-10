global io_outb
io_outb:
	mov al, [esp+3]
	mov dx, [esp+2]
	out dx, al
	ret

global io_outw
io_outw:
	mov ax, [esp+4]
	mov dx, [esp+2]
	out dx, al
	ret

global io_outl
io_outl:
	mov eax, [esp+6]
	mov dx, [esp+2]
	out dx, al
	ret

global io_inb
io_inb:
	mov dx, [esp+2]
	in al, dx
	ret

global io_inw
io_inw:
	mov dx, [esp+2]
	in ax, dx
	ret

global io_inl
io_inl:
	mov dx, [esp+2]
	in eax, dx
	ret

global io_wait
io_wait:
	mov al, 0
	out 0x80, al