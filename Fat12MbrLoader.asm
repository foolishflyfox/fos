org 0x7c00

	LoaderCoreAddr_base 	equ 0x1000
	LoaderCoreAddr_offset	equ 0x100
	;fat16表加载位置
	Fat16_base 				equ 0x900
	Fat16_offset 			equ 0x000
	;Fat16表的起始扇区
	Fat16SectorStart		equ 1
	;Fat16表占用的扇区个数
	Fat16SectorCnt			equ 9
	;根目录的扇区数
	RootDirSectorCnt		equ 14
	;根目录起始扇区
	RootDirSectorStart		equ 19

	jmp short LABEL_START		; Start to boot.
	nop				; 这个 nop 不可少

	; 下面是 FAT12 磁盘的头
	BS_OEMName	DB 'ForrestY'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512		; 每扇区字节数(固定)
	BPB_SecPerClus	DB 1		; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1		; Boot 记录占用多少扇区(1个MBR)
	BPB_NumFATs		DB 2		; 共有多少 FAT 表(固定)
	BPB_RootEntCnt	DW 224		; 根目录文件数最大值0xe0
	BPB_TotSec16	DW 2880		; 逻辑扇区总数(针对1.44M软盘)
	BPB_Media		DB 0xF0		; 媒体描述符
	BPB_FATSz16		DW 9		; 每FAT扇区数(FAT表位于MBR后)
	BPB_SecPerTrk	DW 18		; 每磁道扇区数(1.44M=80*2*18)
	BPB_NumHeads	DW 2		; 磁头数(面数)
	BPB_HiddSec		DD 0		; 隐藏扇区数
	BPB_TotSec32	DD 0		; wTotalSectorCount为0时这个值记录扇区数
	BS_DrvNum		DB 0		; 中断 13 的驱动器号
	BS_Reserved1	DB 0		; 未使用
	BS_BootSig		DB 29h		; 扩展引导标记 (29h)
	BS_VolID		DD 0		; 卷序列号,A盘
	BS_VolLab	DB 'fool_flyfox'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

LABEL_START:
	mov	ax, cs
	mov ds,ax
	mov ss,ax
	mov sp,0x7c00
	mov ax,LoaderCoreAddr_base
	mov es,ax
	mov bx,0

	mov cx,RootDirSectorCnt
	mov ax,RootDirSectorStart
LABEL_SEARCH_LOADER:
	push word 1
	push ax
	call LABEL_READ_SECTOR
	add sp,4
	
	mov [LABEL_CMP_ADDR],word 0
	push cx
	mov cx,512/32
LABEL_LOOP_CMP:
	;检测ax指定的页中是否有LOADER.BIN文件
	call LABEL_CMP_NAME
	cmp byte [LABEL_IS_SAME],1
	jnz LOOP_CMP_NEXT
	;如果相同了
	mov si,[LABEL_CMP_ADDR]
	add si,26
	mov cx,[es:si]
	mov [LABEL_LOADER_SECTOR],cx
	pop cx
	jmp LABEL_FIND_LOADER
LOOP_CMP_NEXT:
	add word [LABEL_CMP_ADDR],32
	loop LABEL_LOOP_CMP
	pop cx
	inc ax
	loop LABEL_SEARCH_LOADER

LABEL_NO_LOADER:
;	mov ax,0xb800
;	mov es,ax
;	mov [es:0],byte 'W'
;	mov [es:1],byte 0x0c
	mov dx,str_no_loader
	call DisplayMsg
	jmp $

LABEL_FIND_LOADER:
;	mov ax,0xb800
;	mov es,ax
;	mov [es:0],byte 'R'
;	mov [es:1],byte 0x0c
	mov dx,str_load_ok
	call DisplayMsg
	;加载FAT表
	mov ax,Fat16_base
	mov es,ax
	mov bx,Fat16_offset
LABEL_FAT16_LOAD:
	push word Fat16SectorCnt
	push word Fat16SectorStart
	call LABEL_READ_SECTOR
	mov di,bx
;	jmp $
	;加载内核
	mov ax,LoaderCoreAddr_base
	mov es,ax
	mov bx,LoaderCoreAddr_offset
LABEL_LOADING:
	mov ax,[LABEL_LOADER_SECTOR]
	mov cx,ax
	add ax,31
	push word 1
	push ax
	call LABEL_READ_SECTOR
	add bx,512			;V1版本由于没有加这行,导致执行大于512B的bootloader失败
	add sp,4

	xor dx,dx
	mov ax,cx
	mov cx,3
	mul cx
	mov cx,2
	div cx
	mov si,di
	add si,ax
	push es
	mov ax,Fat16_base
	mov es,ax
	mov ax,[es:si]
	pop es
	cmp dx,0
	jnz LABEL_HALF_BEGIN
	and ax,0x0FFF
	jmp CMP_NEXT_SECTOR
LABEL_HALF_BEGIN:;从半个字节开始
	shr ax,4
CMP_NEXT_SECTOR:
	cmp ax,0xFF6
	jg LABEL_BEGIN_CORE
	mov [LABEL_LOADER_SECTOR],ax
	jmp LABEL_LOADING

LABEL_BEGIN_CORE:
	jmp LoaderCoreAddr_base:LoaderCoreAddr_offset
;	jmp $

LABEL_CMP_NAME:;无参数，所用全局变量LABEL_CMP_ADDR
	push cx
	push bx
	push ax
	mov si,[LABEL_CMP_ADDR]
	mov cx,LoaderNameLen
	mov bx,0
LABEL_CMP_CHAR:
	mov al,[bx+LABEL_LOADER_NAME]
	cmp al,[es:si+bx]
	jnz LABEL_DIFF
	inc bx
	loop LABEL_CMP_CHAR
	jmp LABEL_SAME

LABEL_DIFF:;名称不相同
	mov [LABEL_IS_SAME],byte 0
	jmp LABEL_CMP_END
LABEL_SAME:;名称相同
	mov [LABEL_IS_SAME],byte 1
LABEL_CMP_END:
	pop ax
	pop bx
	pop cx
	ret

LABEL_READ_SECTOR:
	push bp
	mov bp,sp
	push cx
	push ax
	;[bp+4]->起始扇区 [bp+6]->扇区个数 (LBA模型)
	push bx
	mov ax,[bp+4]
	xor dx,dx
	mov bx,18
	div bx
	inc dx	;dx--起始扇区号(CHR模型)
	mov cl,dl
	xor dx,dx
	mov bx,2
	div bx
	mov dh,dl
	mov ch,al
	mov al,[bp+6]
	mov ah,0x02
	mov dl,[BS_DrvNum]
	pop bx
	int 0x13
;	jmp $	

	pop ax
	pop cx
	mov sp,bp
	pop bp
	ret

DisplayMsg:;dx--在LOAD_RUSULT中的信息索引
	push es
	mov ax,cs
	mov es,ax
	mov bp,dx
	add bp,LOAD_RESULT
	mov cx,9
	mov ax,0x1301
	mov bx,0x000c
	mov dx,0x0100
	int 10h
	pop es
	ret

LABEL_LOADER_NAME:
	db 'LOADER  BIN'
LoaderNameLen equ $-LABEL_LOADER_NAME
LOAD_RESULT:
	db 'Load ok  '	;9byte
	str_load_ok equ 0
	db 'No Loader'	;9byte
	str_no_loader equ 9
LABEL_LOADER_SECTOR:dw 0
;名称比较的起始地址
LABEL_CMP_ADDR:
	dw 0
LABEL_IS_SAME:	;全局变量,名称比较结果--1、相同，0、不同
	db 0
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志

