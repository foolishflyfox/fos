%include "pm.inc"

org 0x100

;第一个页表开始位置
PageDirBase0 equ 0x200000	;2M
PageTblBase0 equ 0x201000	;2M + 4K
;第二个页表开始位置
PageDirBase1 equ 0x210000	;2M+64K
PageTblBase1 equ 0x211000	;2M+64K+4K

[SECTION .entry]
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax

;获取可用内存大小
mov ebx,0
mov di,_MemChkBuf
_loop:
	mov eax,0xE820
	mov ecx,24
	mov edx,0x534D4150
	int 0x15
	jc LABEL_MEM_CHK_FAIL
	add di,24
	inc dword [_dwMCRNumber]
	cmp ebx,0
	jne _loop
	jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov dword [_dwMCRNumber],0
LABEL_MEM_CHK_OK:
	mov di,_MemChkBuf
	;计算总共的可用内存
	mov ecx,[_dwMCRNumber]
@1:
	mov eax,[ds:di+16]
	cmp eax,1
	jnz @1_end
	mov eax,[ds:di]
	add eax,[ds:di+8]
	cmp eax,[_dwMemSize]
	jng @1_end
	mov [_dwMemSize],eax
@1_end:
	add di,24
	loop @1
;[ds:_dwMemSize] 存放可用内存大小0x01ff0000=32M

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_S32_START
mov [LABEL_DESC_S32+2],ax
shr eax,16
mov [LABEL_DESC_S32+4],al
mov [LABEL_DESC_S32+7],ah

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_STACK_START
mov [LABEL_DESC_STACK+2],ax
shr eax,16
mov [LABEL_DESC_STACK+4],al
mov [LABEL_DESC_STACK+7],ah

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_DATA_START
mov [LABEL_DESC_DATA+2],ax
shr eax,16
mov [LABEL_DESC_DATA+4],al
mov [LABEL_DESC_DATA+7],ah

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_GDT
mov [LABEL_GDT_PTR+2],eax

lgdt [LABEL_GDT_PTR]

in al,0x92
or al,2
out 0x92,al

cli

mov eax,cr0
or al,1
mov cr0,eax

jmp dword SelectorS32:0

[SECTION .s32]
[BITS 32]
LABEL_S32_START:
	mov ax,SelectorStack
	mov ss,ax
	mov sp,SegStackLen

	mov ax,SelectorVideo
	mov gs,ax
	mov [gs:0],byte 'V'
	mov [gs:1],byte 0x0C
	call LABEL_TEST_STACK
	mov [gs:4],byte 'V'
	mov [gs:5],byte 0x0C
	jmp $

LABEL_TEST_STACK:
	mov [gs:2],byte 'V'
	mov [gs:3],byte 0x0C
	ret

;启动分页机制
SetPaging:
	xor edx,edx
	mov eax,[dwMemSize]
	mov ebx,0x400000	;4M一个页目录对应4M内存
	div ebx				;计算需要多少个页目录项
	mov ecx,eax			;ecx为PDE个数
	cmp edx,0
	jz no_remainder
	inc ecx
no_remainder:
	mov [PageTableNumber],ecx
	;初始化页目录
	mov ax,SelectorFlatRW
	mov es,ax
	mov edi,PageDirBase0
	xor eax,eax
	mov eax,PageTblBase0|PG_P|PG_USU|PG_RWW
.1:
	stosd
	add eax,4096
	loop .1

	;初始化页表
	mov eax,[PageTableNumber]
	mov ebx,1024
	mul ebx
	mov ecx,eax
	mov edi,PageTblBase0
	xor eax,eax
	mov eax,PG_P|PG_USU|PG_RWW
.2:
	stosd
	add eax,4096
	loop .2

	mov eax,PageDirBase0
	mov cr3,eax
	mov eax,cr0
	or eax,80000000h
	mov cr0,eax
	
	nop
	ret
;分页结束



LABEL_S32_END:
SegS32Len equ LABEL_S32_END-LABEL_S32_START

[SECTION .stack]
[BITS 32]
LABEL_STACK_START:
	times 256 db 0
LABEL_STACK_END:
SegStackLen equ LABEL_STACK_END-LABEL_STACK_START

[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_DATA_START:
;实模式下使用这些符号
_dwMCRNumber dd 0
_dwMemSize dd 0		;可用内存块大小
_MemChkBuf: times 256 db 0
_PageTableNumber dd 0
;保护模式下使用这些符号
dwMCRNumber equ _dwMCRNumber-$$
dwMemSize equ _dwMemSize-$$
MemChkBuf equ _MemChkBuf-$$
PageTableNumber equ _PageTableNumber-$$
LABEL_DATA_END:

SegDataLen equ LABEL_DATA_END-LABEL_DATA_START

[SECTION .gdt]
LABEL_GDT:Descriptor 0,0,0
LABEL_DESC_S32:Descriptor 0,SegS32Len-1,DA_C|DA_32
SelectorS32 equ LABEL_DESC_S32-LABEL_GDT
LABEL_DESC_VIDEO:Descriptor 0xb8000,0xffff,DA_DRW
SelectorVideo equ LABEL_DESC_VIDEO-LABEL_GDT
LABEL_DESC_STACK:Descriptor 0,SegStackLen,DA_DRW
SelectorStack equ LABEL_DESC_STACK-LABEL_GDT
LABEL_DESC_DATA:Descriptor 0,SegDataLen-1,DA_DRW
SelectorData equ LABEL_DESC_DATA-LABEL_GDT
LABEL_DESC_FLAT_RW:Descriptor 0,0xfffff,DA_DRW|DA_LIMIT_4K
SelectorFlatRW equ LABEL_DESC_FLAT_RW-LABEL_GDT
LABEL_GDT_END:
GdtLen equ LABEL_GDT_END-LABEL_GDT
LABEL_GDT_PTR:
	dw GdtLen-1
	dd 0



