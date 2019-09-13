; ====================================================================
; ----------------------------------------------------------------
; Screen mode $00
; 
; MARS ONLY
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

		struct 0
mdmdl_x		ds.w 1
mdmdl_y		ds.w 1
mdmdl_z		ds.w 1
mdmdl_x_rot	ds.w 1
mdmdl_y_rot	ds.w 1
mdmdl_z_rot	ds.w 1
sizeof_thismdl	ds.l 0
		finish
		
; ====================================================================
; ------------------------------------------------------
; RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
GmMd0_Models	ds.b sizeof_thismdl
		finish
		
; ====================================================================
; ------------------------------------------------------
; CODE section
; ------------------------------------------------------

GmMode_0:		
		move.w	#$2700,sr
		bsr	Mode_Init

		clr.b	(RAM_VdpRegs+7).l			; Backdrop color $00
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.w	(vdp_ctrl),d4
		and.w	#1,d4
		beq.s	.ntsc
		bset	#3,(RAM_VdpRegs+1).l
.ntsc:
		bsr	Video_Update
	; Init
; 		bsr	Mde0_Mars_Init
		lea	ASCII_PAL(pc),a0
		moveq	#$30,d0
		move.w	#$F,d1
		bsr	Video_LoadPal

	; Enable display
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_VSync

		lea	str_Title(pc),a0
		move.l	#locate(0,0,26),d0
		bsr	Video_Print
; 
; 		lea	(sysmars_reg),a6
; 		lea	(GmMd0_Models),a5
; 		moveq	#0,d7
; 		move.w	(Controller_1+on_hold).w,d0
; 		move.w	d0,d1
; 		lsr.w	#8,d1
; 
; 		btst	#bitJoyMode,d1
; 		beq.s	.hmode
; 		moveq	#0,d4
; 		move.w	d4,mdmdl_x(a5)
; 		move.w	d4,mdmdl_y(a5)
; 		move.w	d4,mdmdl_z(a5)
; 		move.w	d4,mdmdl_x_rot(a5)
; 		move.w	d4,mdmdl_y_rot(a5)
; 		move.w	d4,mdmdl_z_rot(a5)
; 		moveq	#1,d7
; .hmode:
; 		move.w	(Controller_1+on_press),d2
; 		btst	#bitJoyStart,d2
; 		beq.s	.lel
; 		bsr	Mde0_Mars_TEST
; .lel:
; 
; 	; button hold
; 		btst	#bitJoyLeft,d0
; 		beq.s	.hleft
; 		add.w	#4,mdmdl_x(a5)
; 		moveq	#1,d7
; .hleft:
; 		btst	#bitJoyRight,d0
; 		beq.s	.hright
; 		sub.w	#4,mdmdl_x(a5)
; 		moveq	#1,d7
; .hright:
; 		btst	#bitJoyUp,d0
; 		beq.s	.hup
; 		add.w	#4,mdmdl_y(a5)
; 		moveq	#1,d7
; .hup:
; 		btst	#bitJoyDown,d0
; 		beq.s	.hdown
; 		sub.w	#4,mdmdl_y(a5)
; 		moveq	#1,d7
; .hdown:
; 		btst	#bitJoyZ,d1
; 		beq.s	.hz
; 		add.w	#4,mdmdl_z(a5)
; 		moveq	#1,d7
; .hz:
; 		btst	#bitJoyC,d0
; 		beq.s	.hc
; 		sub.w	#4,mdmdl_z(a5)
; 		moveq	#1,d7
; .hc:
; 
; 	; ROTATE
; 		btst	#bitJoyA,d0
; 		beq.s	.ha
; 		add.w	#4,mdmdl_x_rot(a5)
; 		moveq	#1,d7
; .ha:
; 		btst	#bitJoyB,d0
; 		beq.s	.hb
; 		sub.w	#4,mdmdl_x_rot(a5)
; 		moveq	#1,d7
; .hb:
; 
; 		tst.w	d7
; 		beq	.loop
; 
; 		bsr	Mde0_Mars_Move
		bra	.loop
		
; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; ----------------------------------------------
; Init models
; ----------------------------------------------

Mde0_Mars_Init:
		bsr	MdMars_Wait_M
		
		lea	(sysmars_reg),a6
		move.l	#TEST_MODEL,d4
		move.w	d4,comm2(a6)
		swap	d4
		move.w	d4,comm0(a6)	; Location
		move.w	#0,comm4(a6)	; Slot
		move.w	#0,comm6(a6)	; X pos
		move.w	#0,comm8(a6)	; Y pos
		move.w	#0,comm10(a6)	; Z pos

		move.w	#$10,d0
		bra	MdMars_Task_M

; ----------------------------------------------
; Move model
; ----------------------------------------------

Mde0_Mars_Move:
		bsr	MdMars_Wait_M

		move.w	#0,comm0(a6)			; Slot
		move.w	mdmdl_x(a5),comm2(a6)		; X pos
		move.w	mdmdl_y(a5),comm4(a6)		; Y pos
		move.w	mdmdl_z(a5),comm6(a6)		; Z pos
		move.w	mdmdl_x_rot(a5),comm8(a6)	; X rot
		move.w	mdmdl_y_rot(a5),comm10(a6)	; Y rot
		move.w	mdmdl_z_rot(a5),comm12(a6)	; Z rot
		
		move.w	#$11,d0
		bra	MdMars_Task_M

Mde0_Mars_TEST:
		lea	($880100),a0
		move.l	#$18000,d0
		move.w	#$100,d1
		bra	MdMars_SendData

; ====================================================================
; ------------------------------------------------------
; VSync
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Interrupts
; ------------------------------------------------------

; --------------------------------------------------
; VBlank
; --------------------------------------------------

; --------------------------------------------------
; HBlank
; --------------------------------------------------
		
; ====================================================================
; ------------------------------------------------------
; Objects
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; DATA Section, small
; ------------------------------------------------------

		align 2
str_Title:	dc.b "\\w \\w \\w \\w",$A
		dc.b "\\w \\w \\w \\w   MD Frames \\l",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		dc.l RAM_FrameCount
		align 4
