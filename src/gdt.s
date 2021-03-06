; GDT manipulation
gdtr dw 0 ; GDT entry count
	 dd 0 ; GDT entries location

global gdt_load
gdt_load:
	mov eax, [esp + 4]
	mov [gdtr + 2], eax
	mov ax, [esp + 8]
	mov [gdtr], ax
	lgdt [gdtr]
	ret

global gdt_reload_segments
gdt_reload_segments:
	; Reload CS segment
	jmp 0x08:reload_CS
reload_CS:
	; Reload data segment registers
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov ax, 0x18
	ltr ax
	ret