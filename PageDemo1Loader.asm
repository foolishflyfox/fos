%include "pm.inc"

org 0x100

PageDirBase		equ		0x200000
PageTableBase	equ		0x201000


jmp LABEL_OS_ENTRY

[SECTION .gdt]
LABEL_GDT:Descriptor 0,0,0
LABEL_DESC_S32:Descriptor 0,SegS32Len-1,DA_32|DA_C
SelectorS32 equ LABEL_DESC_S32-LABEL_GDT
LABEL_DESC_VIDEO:Descriptor 0xb8000,0xffff,DA_DRW
SelectorVideo equ LABEL_DESC_VIDEO-LABEL_GDT
LABEL_DESC_STACK:Descriptor 0,SegStackLen,DA_DRW|DA_32
SelectorStack equ LABEL_DESC_STACK-LABEL_GDT
LABEL_DESC_PDIR:Descriptor PageDirBase,4095,DA_DRW
SelectorPDir equ LABEL_DESC_PDIR-LABEL_GDT
LABEL_DESC_PTABLE:Descriptor PageTableBase,1023,DA_DRW|DA_LIMIT_4K
SelectorPTable equ LABEL_DESC_PTABLE-LABEL_GDT
LABEL_GDT_END:
GdtLen equ LABEL_GDT_END-LABEL_GDT

LABEL_GDT_PTR:
	dw GdtLen-1
	dd 0

[SECTION .stack]
[BITS 32]
LABEL_STACK_START:
	times 512 db 0
LABEL_STACK_END:
SegStackLen equ LABEL_STACK_END-LABEL_STACK_START

[SECTION .s32]
[BITS 32]
LABEL_S32_START:
	mov ax,SelectorStack
	mov ss,ax
	mov sp,SegStackLen

	mov ax,SelectorVideo
	mov gs,ax
	mov [gs:0],byte '^'
	mov [gs:1],byte 0x0c

	call LABEL_PAGE_ON

	call LABEL_TASK_FUN

	jmp $

LABEL_TASK_FUN:
	mov [gs:4],byte '^'
	mov [gs:5],byte 0x0c
	ret

;启用分页机制
LABEL_PAGE_ON:
;	jmp $
	mov ax,SelectorPDir
	mov es,ax
	mov ebx,0
	mov ecx,1024
	mov eax,PageTableBase
	or eax,PG_P|PG_USU|PG_RWW
@1:	;该循环用于设置表目录
	mov [es:ebx],eax
	add ebx,4
	add eax,4096
	loop @1
	
	mov ax,SelectorPTable
	mov es,ax
	mov ebx,0
	mov ecx,1024*1024
	mov eax,0
	or eax,PG_P|PG_USU|PG_RWW
@2:
	mov [es:ebx],eax
	add ebx,4
	add eax,4096
	loop @2

	mov eax,PageDirBase
	mov cr3,eax
	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax
	
	mov [gs:2],byte '_'
	mov [gs:3],byte 0x0c
	ret


LABEL_S32_END:
SegS32Len equ LABEL_S32_END-LABEL_S32_START

[SECTION .entry]
[BITS 16]
LABEL_OS_ENTRY:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax

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
	
	jmp SelectorS32:0
	



