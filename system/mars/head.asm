; ====================================================================
; ----------------------------------------------------------------
; ROM HEAD
; 
; 32X
; ----------------------------------------------------------------

		dc.l 0				; Stack point
		dc.l $3F0			; Entry point (always $3F0)
		dc.l MD_ErrBus			; Bus error
		dc.l MD_ErrAddr			; Address error
		dc.l MD_ErrIll			; ILLEGAL Instruction
		dc.l MD_ErrZDiv			; Divide by 0
		dc.l MD_ErrChk			; CHK Instruction
		dc.l MD_ErrTrapV		; TRAPV Instruction
		dc.l MD_ErrPrivl		; Privilege violation
		dc.l MD_Trace			; Trace
		dc.l MD_Line1010		; Line 1010 Emulator
		dc.l MD_Line1111		; Line 1111 Emulator
		dc.l MD_ErrorEx			; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx	
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx		
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l RAM_HBlankGoTo		; VDP HBlank interrupt
		dc.l MD_ErrorTrap
		dc.l RAM_VBlankGoTo		; VDP VBlank interrupt
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA 32X        "
		dc.b "(C)GF64 20??.???"
		dc.b "NO TITLE                                        "
		dc.b "NO TITLE                                        "
		dc.b "GM HOMEBREW-00"
		dc.w 0
		dc.b "J               "
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.b "RA",$F8,$20
		dc.l $200000
		dc.l $203FFF
		align $1F0
		dc.b "U               "

; ====================================================================
; ----------------------------------------------------------------
; MARS New header
; ----------------------------------------------------------------

		jmp	(MARS_Entry).l
		align $2A2
		jmp	(RAM_HBlankGoTo).l
		align $2AE
		jmp	(RAM_VBlankGoTo).l

; ----------------------------------------------------------------

		align $3C0
		dc.b "MARS CHECK MODE "			; module name
		dc.l 0					; version
		dc.l MARS_RAMDATA			; 0
		dc.l 0					;
		dc.l MARS_RAMDATA_e-MARS_RAMDATA	; 4
		dc.l SH2_M_Entry			; Master SH2 PC
		dc.l SH2_S_Entry			; Slave SH2 PC
		dc.l SH2_Master				; Master SH2 VBR
		dc.l SH2_Slave				; Slave SH2 VBR
		binclude "system/mars/data/security.bin"

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; 
; must be at $3F0
; ----------------------------------------------------------------

MARS_Entry:
 		bcs.s	.no_mars

		lea	(sysmars_reg).l,a5
.M_OK:		cmp.l	#"M_OK",comm0(a5)
		bne	.M_OK
.S_OK:		cmp.l	#"S_OK",comm4(a5)
		bne	.S_OK

		moveq	#0,d0
		move.l	d0,comm0(a5)
		move.l	d0,comm4(a5)
		bsr	MD_Init
		bset	#bitMars,(RAM_SysFlags).l
		bra	MD_Main

; --------------------------------------------------------
; No MARS detected
; --------------------------------------------------------

.no_mars:
		move.w	#$2700,sr
		bsr	MD_Init
		bclr	#bitMars,(RAM_SysFlags).l
		bra	MD_Main

; ====================================================================
; ----------------------------------------------------------------
; Error trap
; ----------------------------------------------------------------

MD_ErrBus:		; Bus error
MD_ErrAddr:		; Address error
MD_ErrIll:		; ILLEGAL Instruction
MD_ErrZDiv:		; Divide by 0
MD_ErrChk:		; CHK Instruction
MD_ErrTrapV:		; TRAPV Instruction
MD_ErrPrivl:		; Privilege violation
MD_Trace:		; Trace
MD_Line1010:		; Line 1010 Emulator
MD_Line1111:		; Line 1111 Emulator
MD_ErrorEx:		; Error exception
MD_ErrorTrap:
		rte
	
; ====================================================================
; ----------------------------------------------------------------
; System init goes here
; ----------------------------------------------------------------

MD_Init:
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp
.waitframe:	move.w	(vdp_ctrl).l,d0		; Wait for VBlank
		btst	#bitVint,d0
		beq.s	.waitframe
		move.l	#$80048144,(vdp_ctrl).l	; Keep display
		lea	($FFFF0000),a0
		move.w	#($F000/4)-1,d0
.clrram:
		clr.l	(a0)+
		dbf	d0,.clrram
		movem.l	($FF0000),d0-a6		; Clear registers
		rts
