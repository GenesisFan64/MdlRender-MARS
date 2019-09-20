; ====================================================================		
; ----------------------------------------------------------------
; MARS CPU
; 
; DO NOT REMOVE THE FREE RUN TIMER ADJUSTMENTS
; ----------------------------------------------------------------

		phase CS3
		cpu SH7600

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 constants
; ----------------------------------------------------------------

; ====================================================================		
; ----------------------------------------------------------------
; MASTER SH2 CPU
; ----------------------------------------------------------------

		align 4
SH2_Master:
		dc.l SH2_M_Entry,CS3|$40000	; Cold PC,SP
		dc.l SH2_M_Entry,CS3|$40000	; Manual PC,SP

		dc.l SH2_Error			; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_Error			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_Error			; CPU address error
		dc.l SH2_Error			; DMA address error
		dc.l SH2_Error			; NMI vector
		dc.l SH2_Error			; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_Error,SH2_Error	; Trap vectors
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error

 		dc.l master_irq			; Level 1 IRQ
		dc.l master_irq			; Level 2 & 3 IRQ's
		dc.l master_irq			; Level 4 & 5 IRQ's
		dc.l master_irq			; PWM interupt
		dc.l master_irq			; Command interupt
		dc.l master_irq			; H Blank interupt
		dc.l master_irq			; V Blank interupt
		dc.l master_irq			; Reset Button

; ====================================================================
; ----------------------------------------------------------------
; Master entry
; ----------------------------------------------------------------

SH2_M_Entry:
		mov.l	#_sysreg,r14
		ldc	r14,gbr

		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(hintclr,gbr)	; clear IRQ ACK regs
		mov.w	r0,@(hintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		mov.w	r0,@(pwmintclr,gbr)
		mov.w	r0,@(pwmintclr,gbr)
		
		mov.l	#_FRT,r1		; Set Free Run Timer
		mov	#$00,r0
		mov.b	r0,@(_TIER,r1)		;
		mov	#$E2,r0
		mov.b	r0,@(_TOCR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_OCR_H,r1)		;
		mov	#$01,r0
		mov.b	r0,@(_OCR_L,r1)		;
		mov	#0,r0
		mov.b	r0,@(_TCR,r1)		;
		mov	#1,r0
		mov.b	r0,@(_TCSR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_FRC_L,r1)		;
		mov.b	r0,@(_FRC_H,r1)		;
		mov	#$f2,r0			; reset setup
		mov.b	r0,@(_TOCR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_OCR_H,r1)		;
		mov	#$01,r0
		mov.b	r0,@(_OCR_L,r1)		;
		mov	#$E2,r0
		mov.b	r0,@(_TOCR,r1)		;
		
; ---------------------------------------------
; Wait for MD and Slave SH2
; ---------------------------------------------

.wait_md:
		mov.l	@(comm0,gbr),r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r1
.wait_slave:
		mov.l	@(comm8,gbr),r0		; wait for the slave to finish booting
		cmp/eq	r1,r0
		bf	.wait_slave
		mov	#0,r0			; clear SLAV
		mov.l	r0,@(comm8,gbr)

; ---------------------------------------------

SH2_M_HotStart:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_CCR,r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#VIRQ_ON|CMDIRQ_ON,r0
    		mov.b	r0,@(intmask,gbr)
		mov	#$20,r0
		ldc	r0,sr
; 		mov 	#CACHE_DATA,r1
; 		mov 	#$C0000000,r2
; 		mov 	#(CACHE_END-CACHE_START)/4,r3
; .copy:
; 		mov 	@r1+,r0
; 		mov 	r0,@r2
; 		add 	#4,r2
; 		dt	r3
; 		bf	.copy
		
; --------------------------------------------------------
; Init
; --------------------------------------------------------

		mov 	#TEST_PICTURPAL,r1
		mov 	#256,r3
		bsr	MarsVideo_LoadPal
		mov 	#0,r2
		
; --------------------------------------------------------
; Loop
; --------------------------------------------------------

master_loop:
		mov	#MarsMdl_Playfld,r4
		mov 	#$100,r5		; speed

; 	; X Y Z
		mov 	@(plyfld_z,r4),r1
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		mov 	#JoyZ,r3
		and 	r3,r0
		cmp/eq	r3,r0
		bf	.no_z
		add 	r5,r1
.no_z:
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyC,r0
		tst	r0,r0
		bt	.no_c
		sub 	r5,r1
.no_c:
		mov 	r1,@(plyfld_z,r4)
		
		mov 	@(plyfld_x,r4),r1
		mov 	@(plyfld_y,r4),r2
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyUp,r0
		tst	r0,r0
		bt	.no_u
		add 	r5,r2
.no_u:
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyDown,r0
		tst	r0,r0
		bt	.no_d
		sub 	r5,r2
.no_d:
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyLeft,r0
		tst	r0,r0
		bt	.no_l
		add 	r5,r1
.no_l:
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyRight,r0
		tst	r0,r0
		bt	.no_r
		sub 	r5,r1
.no_r:
		mov 	r1,@(plyfld_x,r4)
		mov 	r2,@(plyfld_y,r4)
; 		
; 	; ROTATE
		mov 	@(plyfld_x_rot,r4),r1
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		mov 	#JoyA,r3
		and 	r3,r0
		cmp/eq	r3,r0
		bf	.no_a
		add 	r5,r1
.no_a:
		mov	#MARS_Controller_1,r0
		mov	@r0,r0
		and	#JoyB,r0
		tst	r0,r0
		bt	.no_b
		sub 	r5,r1
.no_b:
		mov 	r1,@(plyfld_x_rot,r4)

; 	; X Y Z
		mov	#MARSMdl_Objects,r4
		mov 	@(mdl_z,r4),r1
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		mov 	#JoyZ,r3
		and 	r3,r0
		cmp/eq	r3,r0
		bf	.no2_z
		add 	r5,r1
.no2_z:
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyC,r0
		tst	r0,r0
		bt	.no2_c
		sub 	r5,r1
.no2_c:
		mov 	r1,@(mdl_z,r4)
		
		mov 	@(mdl_x,r4),r1
		mov 	@(mdl_y,r4),r2
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyUp,r0
		tst	r0,r0
		bt	.no2_u
		add 	r5,r2
.no2_u:
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyDown,r0
		tst	r0,r0
		bt	.no2_d
		sub 	r5,r2
.no2_d:
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyLeft,r0
		tst	r0,r0
		bt	.no2_l
		add 	r5,r1
.no2_l:
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyRight,r0
		tst	r0,r0
		bt	.no2_r
		sub 	r5,r1
.no2_r:
		mov 	r1,@(mdl_x,r4)
		mov 	r2,@(mdl_y,r4)

; 	; ROTATE
		mov 	@(mdl_x_rot,r4),r1
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		mov 	#JoyA,r3
		and 	r3,r0
		cmp/eq	r3,r0
		bf	.no_a2
		add 	r5,r1
.no_a2:
		mov	#MARS_Controller_2,r0
		mov	@r0,r0
		and	#JoyB,r0
		tst	r0,r0
		bt	.no_b2
		sub 	r5,r1
.no_b2:
		mov 	r1,@(mdl_x_rot,r4)

		
; -------------------------------------------
; Wait VBLANK
; -------------------------------------------

		mov 	#1,r0
		mov	#MarsVid_VIntBit,r1
		mov 	r0,@r1
.wait_v:
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	.wait_v
		mov.w 	@(comm0,gbr),r0
		add 	#1,r0
		mov.w 	r0,@(comm0,gbr)
		mov.w 	@(comm10,gbr),r0
		cmp/eq	#1,r0
		bf	.lol2
		bra	master_loop
		nop
.lol2:
		mov 	#1,r0
		mov.w	r0,@(comm10,gbr)
		mov.w 	@(comm2,gbr),r0
		add 	#1,r0
		mov.w 	r0,@(comm2,gbr)
		bra	master_loop
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Master CPU MD Requests
; ----------------------------------------------------------------

		align 4
Mstr_MD_Tasks:
		dc.l .null_task		; $00
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $04
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $08
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $0C
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task

		dc.l .task_10		; $10
		dc.l .task_11
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $14
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $18
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task		; $1C
		dc.l .null_task
		dc.l .null_task
		dc.l .null_task
		
; --------------------------------------------------------
; $00 - null
; --------------------------------------------------------

.null_task:
		rts
		nop
		align 4

; --------------------------------------------------------
; $10 - Set new Model
; --------------------------------------------------------

.task_10:
		mov 	#$FFFF,r2
		mov.w	@(comm0,gbr),r0
		shll16	r0
		mov 	r0,r1
		mov.w	@(comm2,gbr),r0
		and 	r2,r0
		or	r1,r0
		mov	r0,r1
		mov	@(comm4,gbr),r0
		mov	#sizeof_mdl,r2
		mulu	r0,r2
		sts	macl,r0

		mov 	#MARSMdl_Objects,r3
		add 	r0,r3
		mov 	r1,@(mdl_data,r3)
		mov.w	@(comm6,gbr),r0
		mov	r0,r1
		mov.w	@(comm8,gbr),r0
		mov	r0,r2
		mov.w	@(comm10,gbr),r0
		mov 	r1,@(mdl_x,r3)
		mov 	r2,@(mdl_y,r3)
		mov 	r0,@(mdl_z,r3)
		rts
		nop
		align 4

; --------------------------------------------------------
; $11 - Move model
; --------------------------------------------------------

.task_11:
		mov	#0,r0
		mov.w	@(comm0,gbr),r0
		mov	#sizeof_mdl,r2
		mulu	r2,r0
		sts	macl,r0
		mov 	#MARSMdl_Objects,r8
		add 	r0,r8
		
		mov.w	@(comm2,gbr),r0
		mov	r0,r1
		mov.w	@(comm4,gbr),r0
		mov	r0,r2
		mov.w	@(comm6,gbr),r0
		mov 	r0,r3
		mov.w	@(comm8,gbr),r0
		mov	r0,r4
		mov.w	@(comm10,gbr),r0
		mov	r0,r5
		mov.w	@(comm12,gbr),r0
		
		shll8	r1
		shll8	r2
		shll8	r3
		shll8	r4
		shll8	r5
		shll8	r0
		mov 	r1,@(mdl_x,r8)
		mov 	r2,@(mdl_y,r8)
		mov 	r3,@(mdl_z,r8)
		mov 	r4,@(mdl_x_rot,r8)
		mov 	r5,@(mdl_y_rot,r8)
		mov 	r0,@(mdl_z_rot,r8)
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; irq
; 
; r0-r1 are safe
; ----------------------------------------------------------------

		align 4
master_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15
	
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	#int_m_list,r1
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		
		lds.l	@r15+,pr
		mov.l	@r15+,r1
		mov.l	@r15+,r0
		rte
		nop
		align 4
		ltorg

; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4
int_m_list:
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_pwm,m_irq_pwm
		dc.l m_irq_cmd,m_irq_cmd
		dc.l m_irq_h,m_irq_h
		dc.l m_irq_v,m_irq_v
		dc.l m_irq_vres,m_irq_vres

; =================================================================
; ------------------------------------------------
; Unused
; ------------------------------------------------

m_irq_bad:
		rts
		nop
		align 4
		ltorg
		
; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

m_irq_pwm:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(pwmintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

m_irq_cmd:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(cmdintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

		mov	r2,@-r15
		mov	r3,@-r15

		mov	#_DMASOURCE0,r1
		stc	gbr,r0
		add	#dreqfifo,r0
		mov	r0,@r1			; Source
		add 	#4,r1

		mov 	#$FFFF,r3
		mov.w	@(dreqdest,gbr),r0
		and	r3,r0
		shll16	r0
		mov	r0,r2
		mov.w	@(dreqdest+2,gbr),r0
		and 	r3,r0
		or	r2,r0
		mov 	#CS3,r2
		or	r2,r0
		mov	r0,r3

		mov	r0,@r1			; Destination
		add	#4,r1
		mov.w	@(dreqlen,gbr),r0
		extu.w	r0,r0
		mov	r0,@r1			; Length
		add	#4,r1
		mov	#%0100010011100001,r0
		mov	r0,@r1			; Control register
		mov	#_DMAOPERATION,r1
		mov	#%0001,r0
		mov	r0,@r1			; DMA Start
		mov	#_DMACHANNEL0,r1
cpuw_01:
		mov	@r1,r0
		tst	#%10,r0
		bt	cpuw_01
		mov	#_DMAOPERATION,r1
		mov	#0,r0
		mov	r0,@r1			; DMA off

		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg
		
; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

m_irq_h:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(hintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

		rts
		nop
		align 4
		ltorg
		
; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

m_irq_v:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(vintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

	; wait linefill request
		mov 	#_vdpreg,r1
.min_r		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.min_r
		
	; send palette from cache to vdp palette
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov.l	#_vdpreg,r1		; Wait for palette access ok
.wait		mov.b	@(vdpsts,r1),r0
		tst	#$20,r0
		bt	.wait
		mov	#MARSVid_Palette,r1	; Send palette from cache
		mov	#_palette,r2
 		mov	#256,r3
		mov	#%0101011011110001,r4	; transfer size 2 / burst
		mov	#_DMASOURCE0,r5 	; _DMASOURCE = $ffffff80
		mov	#_DMAOPERATION,r6 	; _DMAOPERATION = $ffffffb0
		mov	r1,@r5			; set source address
		mov	r2,@(4,r5)		; set destination address
		mov	r3,@(8,r5)		; set length
		xor	r0,r0
		mov	r0,@r6			; Stop OPERATION
		xor	r0,r0
		mov	r0,@($C,r5)		; clear TE bit
		mov	r4,@($C,r5)		; load mode
		add	#1,r0
		mov	r0,@r6			; Start OPERATION
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2

		mov	#$FFFF,r2
		mov	#MarsSys_Input,r3
		mov.w 	@(comm14,gbr),r0
		and	r2,r0
		mov 	r0,r4
		mov.w 	@(comm12,gbr),r0
		and	r2,r0
		mov	@r3,r1
		xor	r0,r1
		mov	r0,@r3
		and	r0,r1
		mov	r1,@(4,r3)
		add 	#8,r3
		mov 	r4,r0
		mov	@r3,r1
		xor	r0,r1
		mov	r0,@r3
		and	r0,r1
		mov	r1,@(4,r3)

		mov 	#0,r0
		mov	#MarsVid_VIntBit,r1
		mov 	r0,@r1
		rts
		nop
		align 4
		ltorg
		
; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt
; ------------------------------------------------

m_irq_vres:
		mov	#1,r0
		mov.w	r0,@(vresintclr,gbr)
		
		mov 	#SH2_Master+4,r1
		mov 	@r1,r15
		mov 	#SH2_M_HotStart,r0
		mov	r0,@r15
		mov.w	#$F0,r0
		mov	r0,@(4,r15)
		
; ----------------------------------

		rte			; only this one
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; SLAVE SH2 CPU
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,CS3|$3F000	; Cold PC,SP
		dc.l SH2_S_Entry,CS3|$3F000	; Manual PC,SP

		dc.l SH2_Error			; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_Error			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_Error			; CPU address error
		dc.l SH2_Error			; DMA address error
		dc.l SH2_Error			; NMI vector
		dc.l SH2_Error			; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_Error,SH2_Error	; Trap vectors
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error		
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error

 		dc.l slave_irq			; Level 1 IRQ
		dc.l slave_irq			; Level 2 & 3 IRQ's
		dc.l slave_irq			; Level 4 & 5 IRQ's
		dc.l slave_irq			; PWM interupt
		dc.l slave_irq			; Command interupt
		dc.l slave_irq			; H Blank interupt
		dc.l slave_irq			; V Blank interupt
		dc.l slave_irq			; Reset Button

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

SH2_S_Entry:
		mov	#_sysreg,r14
		ldc	r14,gbr
		mov.l	#_FRT,r1		; Set Free Run Timer
		mov	#$00,r0
		mov.b	r0,@(_TIER,r1)		;
		mov	#$E2,r0
		mov.b	r0,@(_TOCR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_OCR_H,r1)	;
		mov	#$01,r0
		mov.b	r0,@(_OCR_L,r1)		;
		mov	#0,r0
		mov.b	r0,@(_TCR,r1)		;
		mov	#1,r0
		mov.b	r0,@(_TCSR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_FRC_L,r1)		;
		mov.b	r0,@(_FRC_H,r1)		;

; --------------------------------------------------------
; Wait for MD, report to Master SH2
; --------------------------------------------------------

.wait_md:
		mov.l	@(comm0,gbr),r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r0
		mov.l	r0,@(comm8,gbr)

; --------------------------------------------------------

SH2_S_HotStart:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_CCR,r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#CMDIRQ_ON,r0
    		mov.b	r0,@(intmask,gbr)
		mov	#$20,r0
		ldc	r0,sr
		mov.w	r0,@(pwmintclr,gbr)
		mov.w	r0,@(pwmintclr,gbr)
		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(hintclr,gbr)	;clear IRQ ACK regs
		mov.w	r0,@(hintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		
; --------------------------------------------------------
; Init
; --------------------------------------------------------

		bsr	MarsSound_Init
		nop
		bsr	MarsVideo_Init
		nop
		bsr	MarsMdl_Init
		nop

		mov 	#MARSMdl_Objects,r3
		mov 	#TEST_MODEL_2,r1
		mov 	r1,@(mdl_data,r3)
		mov 	#0,r0
		mov 	r0,@(mdl_x,r3)
		mov 	r0,@(mdl_y,r3)
		mov 	#-$A000,r0
		mov 	r0,@(mdl_z,r3)

		mov 	#MARSMdl_Objects+sizeof_mdl,r3
		mov 	#TEST_MODEL,r1
		mov 	r1,@(mdl_data,r3)
		mov 	#0,r0
		mov 	r0,@(mdl_x,r3)
		mov 	r0,@(mdl_y,r3)
; 		mov 	#-$8000,r0
		mov 	r0,@(mdl_z,r3)

; --------------------------------------------------------
; Loopf
; --------------------------------------------------------

slave_loop:
		mov.w 	@(comm10,gbr),r0
		cmp/eq	#0,r0
		bt	slave_loop

		bsr	MarsVideo_SwapFrame	; FB SWAP request
		nop
		bsr	MarsMdl_Run		; Read models and build faces
		nop
		bsr	MarsVideo_WaitFrame	; Wait swap
		nop
		bsr	MarsVideo_ClearFrame
		nop
		
	; -----------------------------------
	; Render polygons
	; -----------------------------------
		mov 	#MARSMdl_ZList,r2
.next:
		mov	@r2,r0
		cmp/eq	#0,r0
		bt	.finish
		bsr	MarsVideo_DrwPoly
		mov	r0,r1
		mov 	r0,@r2
		mov 	r0,@(4,r2)
.off:
		bra	.next
		add 	#8,r2
.finish:

	; -----------------------------------
	
		mov 	#0,r0
		mov.w 	r0,@(comm10,gbr)
		
		mov.w 	@(comm4,gbr),r0
		add 	#1,r0
		mov.w 	r0,@(comm4,gbr)
		bra	slave_loop
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; irq
; 
; r0-r1 are safe
; ----------------------------------------------------------------

		align 4
slave_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15
	
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	#int_s_list,r1
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		
		lds.l	@r15+,pr
		mov.l	@r15+,r1
		mov.l	@r15+,r0
		rte
		nop
		
; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4
int_s_list:
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_pwm,s_irq_pwm
		dc.l s_irq_cmd,s_irq_cmd
		dc.l s_irq_h,s_irq_h
		dc.l s_irq_v,s_irq_v
		dc.l s_irq_vres,s_irq_vres

; =================================================================
; ------------------------------------------------
; Unused
; ------------------------------------------------

s_irq_bad:
		rts
		nop
		align 4
		ltorg
		
; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

s_irq_pwm:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(pwmintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

  		mov.w	@(monowidth,gbr),r0
  		shlr8	r0
 		tst	#$80,r0
 		bf	.exit
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		sts	pr,@-r15
		bsr	MarsSound_PWM
		nop
		lds	@r15+,pr
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
.exit:
		nop
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

s_irq_cmd:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(cmdintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

		nop
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(hintclr,gbr)
		nop
		nop
		nop
		nop
		
; ----------------------------------

		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | VBlank
; ------------------------------------------------

s_irq_v:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		xor	#$02,r0
		mov.b	r0,@(_TOCR,r1)
		mov.w	r0,@(vintclr,gbr)
		nop
		nop
		nop
		nop

; ----------------------------------
		
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt
; ------------------------------------------------

s_irq_vres:
		mov	#1,r0
		mov.w	r0,@(vresintclr,gbr)
		
; 		mov 	#SH2_Slave+4,r1
; 		mov 	@r1,r15
; 		mov 	#SH2_S_HotStart,r0
; 		mov	r0,@r15
; 		mov.w	#$F0,r0
; 		mov	r0,@(4,r15)
		
; ----------------------------------

		rte			; only this one
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Error trap
; ----------------------------------------------------------------

SH2_Error:
		nop
		bra	SH2_Error
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; MARS System features
; ----------------------------------------------------------------

		include "system/mars/video.asm"
		include "system/mars/sound.asm"
		align 4
		
; ====================================================================
; ----------------------------------------------------------------
; MARS DATA
; ----------------------------------------------------------------

sin_table	binclude "system/mars/data/sinedata.bin"

; ====================================================================
; ----------------------------------------------------------------
; MARS User data
; ----------------------------------------------------------------

TEST_PICTURPAL:	binclude "engine/data/mtrl/semf_pal.bin"
		align 4

TEST_MODEL:
		binclude "engine/data/test_head.bin"
		dc.l .vert,.face,.vrtx,.mtrl	; vertices, faces, vertex, material
.vert:		binclude "engine/data/test_vert.bin"
.face:		binclude "engine/data/test_face.bin"
.vrtx:		binclude "engine/data/test_vrtx.bin"
.mtrl:		include "engine/data/test_mtrl.asm"

TEST_MODEL_2:
		binclude "engine/data/semaf_head.bin"
		dc.l .vert,.face,.vrtx,.mtrl	; vertices, faces, vertex, material
.vert:		binclude "engine/data/semaf_vert.bin"
.face:		binclude "engine/data/semaf_face.bin"
.vrtx:		binclude "engine/data/semaf_vrtx.bin"
.mtrl:		include "engine/data/semaf_mtrl.asm"

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

SH2_RAM:
		struct SH2_RAM|TH
	if MOMPASS=1
MARSRAM_System	ds.l 0
MARSRAM_Video	ds.l 0
MARSRAM_Sound	ds.l 0
sizeof_marsram	ds.l 0
	else
MARSRAM_System	ds.b (sizeof_marssys-MARSRAM_System)
MARSRAM_Video	ds.b (sizeof_marsvid-MARSRAM_Video)
MARSRAM_Sound	ds.b (sizeof_marssnd-MARSRAM_Sound)
sizeof_marsram	ds.l 0
	endif

.here:
	if MOMPASS=7
		message "MARS RAM from \{((SH2_RAM)&$FFFFFF)} to \{((.here)&$FFFFFF)}"
	endif
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

		struct MARSRAM_System
MarsSys_Input	ds.l 4
MARSSys_MdReq	ds.l 1
sizeof_marssys	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

		struct MARSRAM_Sound
MARSSnd_Pwm	ds.b sizeof_sndchn*8
sizeof_marssnd	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

		struct MARSRAM_Video
MARSVid_LastFb	ds.l 1
MarsVid_VIntBit	ds.l 1
MARSMdl_FaceCnt	ds.l 1
MarsMdl_CurrPly	ds.l 1
MarsMdl_CurrZtp	ds.l 1
; MARSMdl_OutPnts ds.l 3*MAX_VERTICES			; Output vertices for reading
MARSMdl_ZList	ds.l 2*MAX_POLYGONS			; Polygon address | Polygon Z pos
MARSVid_Palette	ds.w 256
MARSMdl_Playfld	ds.b sizeof_plyfld			; Playfield buffer (or camera)
MARSVid_Polygns	ds.b sizeof_polygn*MAX_POLYGONS		; Polygon data
MARSMdl_Objects	ds.b sizeof_mdl*MAX_MODELS
sizeof_marsvid	ds.l 0
		finish

; --------------------------------------------------------
; Alias
; --------------------------------------------------------

MARS_Controller_1	equ	MarsSys_Input
MARS_Controller_2	equ	MarsSys_Input+8
marspad_onhold		equ	0
marspad_onpress		equ	4
