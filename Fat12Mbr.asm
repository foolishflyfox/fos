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
	jmp $
times 	510-($-$$)	db	0	
dw 	0xaa55				; 结束标志

