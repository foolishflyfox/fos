org 0x7c00

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
	mov	ds, ax
	mov	es, ax
	Call	DispStr			; 调用显示字符串例程
	jmp	$			; 无限循环
DispStr:
	mov	bp, BootMessage	; ES:BP = 待显示字符串地址
	mov	cx, 16			; CX = 待显示字符串长度
	mov	ax, 01301h		; AH = 13h-显示字符串,  AL = 01h-仅包含字符串
	mov	bx, 000ch		; 视频区页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
	mov dh, 2			; 第2行(从0开始)
	mov	dl, 2			; 第2列(从0开始)
	int	10h			; int 10h
	ret
BootMessage:		db	"Hello, OS world!"
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
