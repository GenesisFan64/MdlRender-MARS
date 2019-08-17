; ====================================================================
; ----------------------------------------------------------------
; MARS ONLY
; 
; CPU communication from MAIN to SUB
; ----------------------------------------------------------------

; --------------------------------------------------------
; MdMars_Task_M / MdMars_Task_S
; 
; Request task to SubCPU
; check system/mars/main.asm to see each task action
;
; Input:
; d0 - Task number
; --------------------------------------------------------

MdMars_Task_M:
		move.b	d0,(sysmars_reg+comm14)
		rts
MdMars_Task_S:
		move.b	d0,(sysmars_reg+(comm14+1))
		rts
		
; --------------------------------------------------------
; MdMars_Wait_M / MdMars_Wait_S
; 
; Wait if current SH2 CPU is free
;
; Input:
; d0 - Task number
; --------------------------------------------------------

MdMars_Wait_M:
		tst.b	(sysmars_reg+comm14)
		bne.s	MdMars_Wait_M
		rts
MdMars_Wait_S:
		tst.b	(sysmars_reg+(comm14+1))
		bne.s	MdMars_Wait_S
		rts
		
; --------------------------------------------------------
; MdMars_SendData
; 
; Transfer data from 68k to SH2
;
; Input:
; a0 - Input data
; d0 | LONG - Output address (SH2 map)
; d1 | WORD - Size
;
; Uses:
; d4-d5,a4-a6
; --------------------------------------------------------

MdMars_SendData:
		lea	(sysmars_reg),a6
		move.w	#0,dreqctl(a6)
		move.w	d1,d4
		lsr.w	#1,d4
		move.w	d4,dreqlen(a6)
		move.w	#%100,dreqctl(a6)
		move.l	d0,d4
		move.w	d4,dreqdest+2(a6)
		swap	d4
		move.w	d4,dreqdest(a6)

		move.w	2(a6),d4		; CMD Interrupt
		bset	#0,d4
		move.w	d4,2(a6)
		movea.l	a0,a4
		lea	dreqfifo(a6),a5
		move.w	d1,d5
		lsr.w	#3,d5
		sub.w	#1,d5
.sendfifo:
		move.w	(a4)+,(a5)
		move.w	(a4)+,(a5)
		move.w	(a4)+,(a5)
		move.w	(a4)+,(a5)
.full:
		move.w	dreqctl(a6),d4
		btst	#7,d4
		bne.s	.full
		dbra	d5,.sendfifo
		rts

; --------------------------------------------------------
