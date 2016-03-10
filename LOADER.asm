org 0x100
jmp LABEL_START
	times 600 dw 0

LABEL_START:
mov ax,0xb800
mov es,ax
mov si,80*4
mov ah,0x0c
mov al,'G'
mov [es:si],ax
add si,2
mov al,'O'
mov [es:si],ax
add si,2
mov al,'O'
mov [es:si],ax
add si,2
mov al,'D'
mov [es:si],ax

jmp $



