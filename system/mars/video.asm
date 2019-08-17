; ====================================================================
; ----------------------------------------------------------------
; MARS Video
; ----------------------------------------------------------------

; MARS Polygons
; 
; type format:
;   0 - end-of-list
;  -1 - skip polygon (already drawn)
; $03 - triangle
; $04 - quad

; ----------------------------------------
; Settings
; ----------------------------------------

MAX_VERTICES	equ	2048
MAX_POLYGONS	equ	512
MAX_MODELS	equ	24
MAX_ZDISTANCE	equ	-128		; lower distance, more stable

; ----------------------------------------
; Variables
; ----------------------------------------

SCREEN_WIDTH	equ	320
SCREEN_HEIGHT	equ	224

; ----------------------------------------
; Structs
; ----------------------------------------

; current DDA
		struct 0
plydda_h	ds.l 1
plydda_x	ds.l 1
plydda_dx	ds.l 1
plydda_src_x	ds.l 1
plydda_src_y	ds.l 1
plydda_src_dx	ds.l 1
plydda_src_dy	ds.l 1
sizeof_plydda	ds.l 0
		finish
		
; playfield struct
		struct 0
plyfld_x	ds.l 1
plyfld_y	ds.l 1
plyfld_z	ds.l 1
plyfld_x_rot	ds.l 1
plyfld_y_rot	ds.l 1
plyfld_z_rot	ds.l 1
sizeof_plyfld	ds.l 0
		finish

; model object struct
		struct 0
mdl_data	ds.l 1			; 0 - endoflist
mdl_x		ds.l 1
mdl_y		ds.l 1
mdl_z		ds.l 1
mdl_x_rot	ds.l 1
mdl_y_rot	ds.l 1
mdl_z_rot	ds.l 1
sizeof_mdl	ds.l 0
		finish

; polygon struct
		struct 0
polygn_type	ds.l 1			; Type ( Polygon(3), Quad(4) or EndOfList(0) )
polygn_mtrl	ds.l 1			; Material Type: Color (0-$FF) or Texture data address
polygn_mtrlopt	ds.l 1			; Material Setting: add $xx to solid color / texture width
polygn_points	ds.l 4			; X/Y points 16-bit
polygn_srcpnts	ds.l 4			; X/Y points 16-bit
sizeof_polygn	ds.l 0
		finish
		
; MarsVideo_DrwPoly
		struct $C0000000
PolyRndr_Left	ds.b sizeof_plydda*4
PolyRndr_Right	ds.b sizeof_plydda*4
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Init Video
; 
; Uses:
; a0-a2,d0-d1
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov 	#_vdpreg,r4
		
		mov 	#FM,r0			; FB to MARS
  		mov.b	r0,@(adapter,gbr)
		
	; Init linetable and swap

		bsr	.this_fb
		nop
		bsr	.this_fb
		nop

	; Enable bitmap $01
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r4)
		
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Init current framebuffer
; ------------------------------------------------

.this_fb:
		mov.b	@(vdpsts,r4),r0
		and	#$80,r0
		tst	#$80,r0
		bf	.this_fb
		
 		mov	#_framebuffer,r1
		mov	#$100,r0
		mov	#240,r2
		mov	#$100,r3
.loop:
		mov.w	r0,@r1
		add	#2,r1
		add	r3,r0
		dt	r2
		bf	.loop
		
 		mov.b	@(framectl,r4),r0
		not	r0,r0
 		and	#1,r0
		rts
		mov.b	r0,@(framectl,r4)
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Video render (polygons)
; ----------------------------------------------------------------

MarsVideo_Render:
		sts	pr,@-r15
		mov 	#MARSMdl_ZList,r2
.next:
		mov	@r2,r0
		cmp/eq	#0,r0
		bt	.finish
		bsr	MarsVideo_DrwPoly
		mov	r0,r1
.off:
		bra	.next
		add 	#8,r2
.finish:

	; Reset mdl face counter
		mov	#MARSMdl_FaceCnt,r2
		mov	#0,r0
		mov	r0,@r2

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; OLD METHOD
; 		mov 	#MARSVid_Polygns,r1
; .next:
; 		mov	@(polygn_type,r1),r0
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		cmp/eq	#-1,r0
; 		bt	.off
; 		bsr	MarsVideo_DrwPoly
; 		nop
; .off:
; 		bra	.next
; 		add 	#sizeof_polygn,r1
; .finish:

; ====================================================================
; ----------------------------------------------------------------
; Video subroutines
; ----------------------------------------------------------------


; --------------------------------------------------------
; MarsVideo_DrwPoly
; 
; r1 - polygon points
; r2 - free
; --------------------------------------------------------

MarsVideo_DrwPoly:
		sts	pr,@-r15

	; TOP/BOTTOM Y
		mov 	#$7FFFFFFF,r11		; lowest Y
		mov 	#$FFFFFFFF,r12		; top Y
		mov 	@(polygn_type,r1),r0	; numof_points & $FF
		and	#$FF,r0
		cmp/eq	#3,r0
		bt	.valid
		cmp/eq	#4,r0
		bf	.exit
.valid:

		mov	#$FFFF,r6
		mov 	r0,r7
		mov 	r1,r8
		add 	#polygn_points,r8
		mov 	#0,r10			; start point id
		mov 	#0,r9			; counter
.first_y:
		mov 	@r8,r0
		and	r6,r0
		exts	r0,r0
		cmp/gt	r11,r0
		bt	.yhigh
		mov 	r0,r11
		mov 	r9,r10
.yhigh:
		cmp/ge	r0,r12
		bt	.yhighb
		mov 	r0,r12
.yhighb:
		add 	#4,r8			; sizeof_point
		add 	#4,r9			; next point*sizeof_point
		dt	r7
		bf	.first_y
		add 	#-4,r9			; get back

		cmp/pl	r12			; bottom < 0
		bf	.exit
		mov 	#SCREEN_HEIGHT,r0
		cmp/ge	r0,r11			; top > 224
		bt	.exit
		cmp/eq	r11,r12
		bt	.exit
		cmp/gt	r11,r12
		bf	.exit

	; r8 - current point * sizeof_point
	; r9 - end point * sizeof_point
	; r10 - curr point copy
		mov	#PolyRndr_Left,r14	; 4 times
		bsr	dda_left
		mov 	r10,r8			; copy current point
		add 	#sizeof_plydda,r14
		bsr	dda_left
		nop
		add 	#sizeof_plydda,r14
		bsr	dda_left
		nop
		add 	#sizeof_plydda,r14
		bsr	dda_left
		nop
		mov	#PolyRndr_Right,r14	; 4 times
		bsr	dda_right
		mov 	r10,r8			; copy current point
		add 	#sizeof_plydda,r14
		bsr	dda_right
		nop
		add 	#sizeof_plydda,r14
		bsr	dda_right
		nop
		add 	#sizeof_plydda,r14
		bsr	dda_right
		nop

; ------------------------------------------------
; Start line rendering
; ------------------------------------------------

	; r7 - Left X
	; r8 - Right X
	; r9 - Left height
	; r10 - Right height
	; r11 - Current Y
	; r12 - End Y
	; r13 - left dda
	; r14 - right dda
		mov	#PolyRndr_Left,r13
		mov	#PolyRndr_Right,r14
		mov 	@(plydda_x,r13),r7	; start X
		mov 	@(plydda_x,r14),r8	; end X
		mov 	@(plydda_h,r13),r9
		mov 	@(plydda_h,r14),r10
.yloop:
		cmp/ge	r12,r11
		bt	.exit
		cmp/pz	r11
		bf	.ymin
		mov 	#SCREEN_HEIGHT,r0
		cmp/ge	r0,r11
		bt	.exit
		bsr	drwpoly_line
		nop
.ymin:
		mov 	@(plydda_dx,r13),r0	; Update X
		add 	r0,r7
		mov 	@(plydda_dx,r14),r0
		add 	r0,r8

		mov	@(plydda_src_x,r13),r0
		mov	@(plydda_src_y,r13),r3
		mov 	@(plydda_src_dx,r13),r4
		mov 	@(plydda_src_dy,r13),r5
		add 	r4,r0
		add 	r5,r3
		mov	r0,@(plydda_src_x,r13)
		mov	r3,@(plydda_src_y,r13)
		mov	@(plydda_src_x,r14),r0
		mov	@(plydda_src_y,r14),r3
		mov 	@(plydda_src_dx,r14),r4
		mov 	@(plydda_src_dy,r14),r5
		add 	r4,r0
		add 	r5,r3
		mov	r0,@(plydda_src_x,r14)
		mov	r3,@(plydda_src_y,r14)

		add 	#-1,r9			; Decrement line
		add 	#-1,r10
		cmp/pl	r9
		bt	.lk
		add	#sizeof_plydda,r13
		mov 	@(plydda_h,r13),r9
		mov 	@(plydda_x,r13),r7
.lk
		cmp/pl	r10
		bt	.rk
		add	#sizeof_plydda,r14
		mov 	@(plydda_h,r14),r10
		mov 	@(plydda_x,r14),r8
.rk
	; Next Y
		bra	.yloop
		add 	#1,r11

; --------------------------------
; finish
; --------------------------------

.exit:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Draw line
; ------------------------------------------------

drwpoly_line:
		mov	@(polygn_mtrl,r1),r0
		mov 	#$FFFF0000,r3
		and	r3,r0
		cmp/eq	#0,r0
		bf	.has_texture

; ----------------------------------------
; Solid color
; ----------------------------------------

.solid_color:
		mov 	r7,r3
		mov 	r8,r0
		shlr16	r0
		shlr16	r3
		exts	r0,r0
		exts	r3,r3
		mov 	r3,r4
		mov 	r0,r5
		
		sub 	r3,r0
		cmp/pl	r0
		bt	.plus
		mov 	r4,r0		; reverse line
		mov 	r5,r3
		mov 	r3,r4
		mov 	r0,r5
.plus:
	; r4 - left
	; r5 - right
; 		mov	#SCREEN_WIDTH,r0
; 		cmp/gt	r0,r5
; 		bt	.bad
; 		cmp/pl	r5
; 		bt	.bad
; 		mov 	#2,r6
; 		mov 	r5,r0
; 		sub 	r4,r0
; 		cmp/ge	r6,r0
; 		bf	.bad

		mov 	#_overwrite+$200,r6
		mov 	r11,r0
		shll8	r0
		shll	r0
		add 	r0,r6

	; Left
		mov 	r4,r0			; r4 - X
		cmp/pl	r0			; < 0
		bf	.min_l
		mov 	#SCREEN_WIDTH,r3	; > 320
		cmp/ge	r3,r0
		bt	.min_l
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
		mov 	r3,r0
		shll8	r0
		or	r0,r3			; $xxxx
		mov 	r4,r0
		and 	#1,r0
		cmp/eq	#0,r0
		bt	.ful_l
		shlr8	r3			; $00xx
.ful_l:
		mov 	#-2,r0
		and	r0,r4			; x & $FFFE
		mov 	r4,r0
		mov.w 	r3,@(r0,r6)
.min_l:

; 	Right
		mov 	r5,r0
		cmp/pl	r0
		bf	.min_r
		mov 	#SCREEN_WIDTH,r3
		cmp/ge	r3,r0
		bt	.min_r
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
		mov 	r3,r0
		shll8	r0
		or	r0,r3
		mov 	r5,r0
		and 	#1,r0
		cmp/eq	#0,r0
		bf	.ful_r
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
		shll8	r3
.ful_r:
		mov 	#-2,r0
		and	r0,r5
		mov 	r5,r0
		mov.w 	r3,@(r0,r6)
.min_r:


; 	LINE FILL
		mov 	#SCREEN_WIDTH,r3
		cmp/gt	r3,r5
		bf	.lowr
		mov 	r3,r5
.lowr:
		mov 	r4,r0
		add 	#2,r0
		cmp/pz	r4
		bt	.lowl
		xor	r0,r0
.lowl:
		mov 	#-2,r4
		and 	r4,r0
		mov 	r0,r4
		sub 	r0,r5
		shlr	r5		; /2
		exts	r5,r5
		add 	#-1,r5
		cmp/pz	r5
		bf	.bad
		mov 	r5,r0
		mov 	#_vdpreg,r6
		mov.b	r0,@(filllength,r6)
		mov 	#$100,r0
		shlr	r4
		add 	r4,r0
		mov 	r11,r4
		shll8	r4
		add 	r4,r0
		mov.w	r0,@(fillstart,r6)
		mov 	@(polygn_mtrl,r1),r0
		and	#$FF,r0
		mov	r0,r3
; 		mov 	@(polygn_mtrlopt,r1),r0
; 		add 	r0,r3
		mov 	r3,r0
		shll8	r0
		or	r3,r0
		mov.w	r0,@(filldata,r6)
		
.waitfill:
		mov.w	@(vdpsts,r6),r0
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.waitfill
		
.bad:
		rts
		nop
		align 4
		
; ----------------------------------------
; Texture material
; ----------------------------------------

; free regs: r2-r6
; r7 - Left X
; r8 - Right X
; r11 - Current Y
; r13 - left dda
; r14 - right dda

.has_texture:
		mov 	r1,@-r15
		mov 	r2,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15

		mov	r7,r9
		mov	r8,r10
		mov	@(plydda_src_x,r14),r4		; texture RX
		mov	@(plydda_src_x,r13),r5		; texture LX
		mov	@(plydda_src_y,r14),r6		; texture RY
		mov	@(plydda_src_y,r13),r7		; texture LY
 		mov	r9,r0
 		sub 	r8,r0
 		cmp/pz	r0
 		bf	.backwrdst
		mov	r9,r2		; swap dest X
		mov	r10,r3
		mov 	r3,r9
		mov	r2,r10
 		mov	r7,r2		; swap texture X
 		mov	r6,r3
 		mov	r2,r6
 		mov	r3,r7		
 		mov	r5,r2		; swap texture Y
 		mov	r4,r3
 		mov	r2,r4
 		mov	r3,r5	
.backwrdst:
		shlr16	r9
		exts	r9,r9
		shlr16	r10
		exts	r10,r10
		cmp/pl	r10
		bf	.texexit
		mov	#SCREEN_WIDTH,r0
		cmp/gt	r0,r9
		bt	.texexit
		mov	r10,r3
		mov 	r9,r0
		sub 	r0,r3
		add 	#1,r3

	; SRC X
		mov	#0,r0
		cmp/eq	r0,r3
		bf	.nozer
		mov	#1,r3
.nozer:
		sub	r4,r5
		mov 	#_JR,r0
		mov 	r3,@r0
		nop
		mov 	r5,@(4,r0)
		nop
		mov	#8,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov 	#_HRL,r0
		mov 	@r0,r5

	; SRC Y
		sub	r6,r7
		mov 	#_JR,r0
		mov 	r3,@r0
		nop
		mov 	r7,@(4,r0)
		nop
		mov	#8,r0
.waitdy:
		dt	r0
		bf	.waitdy
		mov 	#_HRL,r0
		mov 	@r0,r7

	; crop check
		cmp/pl	r9
		bt	.leftok
		mov	#0,r9
.leftok:
		mov	r10,r0
		mov	#SCREEN_WIDTH,r3
		cmp/gt	r3,r0
		bf	.rightok
		mov	r3,r10
		sub 	r3,r0
		cmp/pl	r0
		bf	.rightok
.rghtfix:
		add	r5,r4				; Update X
		add	r7,r6				; Update Y
		dt	r0
		bf	.rghtfix
.rightok:

		mov 	#_overwrite+$200,r8
		add 	r10,r8
		mov 	r11,r0
		shll8	r0
		shll	r0
		add 	r0,r8

	; start
		mov	@(polygn_mtrl,r1),r3		; texture data
		mov	@(polygn_mtrlopt,r1),r2		; texture width
.texloop:
		swap.w	r6,r1				; Build row offset
		mulu.w	r1,r2
		mov	r4,r1	   			; Build column index
		sts	macl,r0
		shlr16	r1
		add	r1,r0

		mov.b	@(r0,r3),r0			; Read pixel
		mov.b	r0,@-r8	   			; Write pixel

		add	r5,r4				; Update X
		dt	r10
		cmp/ge	r9,r10
		bt/s	.texloop
		add	r7,r6				; Update Y

.texexit:
		mov 	@r15+,r10
		mov 	@r15+,r9
		mov 	@r15+,r8
		mov 	@r15+,r7
		mov 	@r15+,r2
		mov 	@r15+,r1
		rts
		nop
		align 4
		
		ltorg

; 		mov 	#_overwrite+$200,r3
; 		mov 	@(polygn_mtrl,r1),r6
; 		mov 	r11,r0
; 		shll8	r0
; 		shll	r0
; 		add 	r0,r3
; 		mov 	r7,r0
; 		shlr16	r0
; 		exts	r0,r0
; 		mov.b 	r6,@(r0,r3)		
; 		mov 	r8,r0
; 		shlr16	r0
; 		exts	r0,r0
; 		rts
; 		mov.b 	r6,@(r0,r3)
		
; ---------------------------------
; Left DDA
; 
; r1 - polygon data
; ---------------------------------

dda_left:
		mov 	r1,r3
		add 	#polygn_points,r3
		add 	r8,r3
		mov.w 	@r3,r4			; r4 - OLD X point
		mov 	r4,r0
		shll16	r0
		mov 	r0,@(plydda_x,r14)
		mov.w 	@(2,r3),r0		; r5 - OLD Y point
		mov	r0,r5

	; SRC OLD POINTS
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov.w 	@r3,r6			; r6 - OLD SRC X point
		mov 	r6,r0
		shll16	r0
		mov 	r0,@(plydda_src_x,r14)
		mov.w 	@(2,r3),r0		; r7 - OLD SRC Y point
		mov 	r0,r7
		shll16	r0
		mov 	r0,@(plydda_src_y,r14)
		
		add 	#4,r8
		cmp/gt	r9,r8
		bf	.lft_ok
		mov 	#0,r8
.lft_ok:
		mov 	r1,r3
		add 	#polygn_points,r3
		add 	r8,r3
		mov.w 	@(2,r3),r0		; NEW Y point

		sub 	r5,r0
		cmp/eq	#0,r0			; if Y == 0
		bt	dda_left		; try again
		cmp/pz	r0			; if Y < 0
		bf	.exit			; exit this
		mov 	r0,@(plydda_h,r14)
		mov 	r0,r5
		
		mov.w 	@r3,r0
		mov	r0,r3			; r3 - NEW X point
		sub 	r4,r3
		shll16	r3
		mov	#_JR,r0			; NEW X / HEIGHT
		mov 	r5,@r0
		nop
		mov 	r3,@(4,r0)
		nop
		mov	#8,r0
.wait:
		dt	r0
		bf	.wait
		mov	#_HRL,r0
		mov	@r0,r4
		mov	r4,@(plydda_dx,r14)
		
	; SRC
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov.w 	@r3,r4
		sub 	r6,r4
		mov.w 	@(2,r3),r0
		mov	r0,r3
		sub 	r7,r3
	
		mov	#_JR,r6
		mov	#_HRL,r7
		shll16	r4
		shll16	r3
		
	; calc dx
		mov 	r5,@r6
		nop
		mov 	r4,@(4,r6)
		nop
		mov	#8,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov	@r7,r4
		mov	r4,@(plydda_src_dx,r14)
	; calc dy
		mov 	r5,@r6
		nop
		mov 	r3,@(4,r6)
		nop
		mov	#8,r0
.waitdy:
		dt	r0
		bf	.waitdy
		mov	@r7,r3
		mov	r3,@(plydda_src_dy,r14)

.exit:
		rts
		nop
		align 4

; ---------------------------------
; Right DDA
; 
; r1 - polygon data
; ---------------------------------

dda_right:
		mov 	r1,r3
		add 	#polygn_points,r3
		add 	r8,r3
		mov.w 	@r3,r4			; r4 - OLD X point
		mov 	r4,r0
		shll16	r0
		mov 	r0,@(plydda_x,r14)
		mov.w 	@(2,r3),r0		; r5 - OLD Y point
		mov	r0,r5
		
	; SRC OLD POINTS
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov.w 	@r3,r6			; r6 - OLD SRC X point
		mov 	r6,r0
		shll16	r0
		mov 	r0,@(plydda_src_x,r14)
		mov.w 	@(2,r3),r0		; r7 - OLD SRC Y point
		mov 	r0,r7
		shll16	r0
		mov 	r0,@(plydda_src_y,r14)

		add 	#-4,r8
		cmp/pz	r8
		bt	.lft_ok
		mov 	r9,r8
.lft_ok:
		mov 	r1,r3
		add 	#polygn_points,r3
		add 	r8,r3
		mov.w 	@(2,r3),r0		; NEW Y point

		sub 	r5,r0
		cmp/eq	#0,r0			; if Y == 0
		bt	dda_right		; try again
		cmp/pz	r0			; if Y < 0
		bf	.exit			; exit this
		mov 	r0,@(plydda_h,r14)
		mov 	r0,r5
		
		mov.w 	@r3,r0
		mov	r0,r3			; r3 - NEW X point
		sub 	r4,r3
		shll16	r3
		mov	#_JR,r0			; NEW X / HEIGHT
		mov 	r5,@r0
		nop
		mov 	r3,@(4,r0)
		nop
		mov	#8,r0
.wait:
		dt	r0
		bf	.wait
		mov	#_HRL,r0
		mov	@r0,r4
		mov	r4,@(plydda_dx,r14)
		
	; SRC
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov.w 	@r3,r4
		sub 	r6,r4
		mov.w 	@(2,r3),r0
		mov	r0,r3
		sub 	r7,r3
	
		mov	#_JR,r6
		mov	#_HRL,r7
		shll16	r4
		shll16	r3
		
	; calc dx
		mov 	r5,@r6
		nop
		mov 	r4,@(4,r6)
		nop
		mov	#8,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov	@r7,r4
		mov	r4,@(plydda_src_dx,r14)
	; calc dy
		mov 	r5,@r6
		nop
		mov 	r3,@(4,r6)
		nop
		mov	#8,r0
.waitdy:
		dt	r0
		bf	.waitdy
		mov	@r7,r3
		mov	r3,@(plydda_src_dy,r14)

.exit:
		rts
		nop
		align 4
		ltorg		; finish section

; ------------------------------------
; MarsVideo_ClearFrame
; ------------------------------------

MarsVideo_ClearFrame:
		mov	#_vdpreg,r1
.wait2		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait2
		
		mov	#255,r2			; 256 words per pass
		mov	#$100,r3		; Starting address
		mov	#0,r4			; Clear to zero
		mov	#256,r5			; Increment address by 256
		mov	#((512*240)/256)/2,r6	; 140 passes
.loop
		mov	r2,r0
		mov.w	r0,@(4,r1)		; Set length
		mov	r3,r0
		mov.w	r0,@(6,r1)		; Set address
		mov	r4,r0
		mov.w	r0,@(8,r1)		; Set data
		add	r5,r3
		
.wait		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait
		dt	r6
		bf	.loop
		rts
		nop
		align 4

; ------------------------------------
; MarsVideo_SwapFrame
; 
; Swap frame
; ------------------------------------

MarsVideo_SwapFrame:
		mov	#_vdpreg,r1
		mov	#MARSVid_LastFb,r2
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)
		rts
		mov.b	r0,@r2
		align 4
; 		ltorg
		
; ------------------------------------
; MarsVideo_WaitFrame
; 
; Wait if frame is ready
; ------------------------------------

MarsVideo_WaitFrame:
		mov	#_vdpreg,r1
		mov	#MARSVid_LastFb,r2
		mov.b	@r2,r0
		mov	r0,r2
.wait3		mov.b	@(framectl,r1),r0
		cmp/eq	r0,r2
		bf	.wait3
		rts
		nop
		align 4

; ------------------------------------
; MarsVdp_LoadPal
; 
; Load palette to MARS VDP
;
; Input:
; r1 - Data
; r2 - Start at
; r3 - Number of colors
; 
; Uses:
; r0,r4-r6
; ------------------------------------

MarsVideo_LoadPal:
		mov 	r1,r4
		mov 	#MARSVid_Palette,r5
		mov 	r2,r0
		shll	r0
		add 	r0,r5
		mov 	r3,r6
.loop:
		mov.w	@r4+,r0
		mov.w	r0,@r5
		add 	#2,r5
		dt	r6
		bf	.loop
		rts
		nop
		align 4
		ltorg
		
; ====================================================================
; ----------------------------------------------------------------
; 3D MODEL RENDER
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init model system
; --------------------------------------------------------

MarsMdl_Init:
		mov 	#MARSMdl_Objects,r1
		mov 	#sizeof_mdl,r2
		mov 	#0,r0
.clrbuff:
		mov	r0,@r1
		add 	#4,r1
		dt	r2
		bf	.clrbuff

; 		mov 	#MARSMdl_Objects,r1
; 		mov 	#TEST_MODEL,r0
; 		mov 	r0,@(mdl_data,r1)
		rts
		nop
		align 4

; --------------------------------------------------------
; Calculate models (not Render)
; --------------------------------------------------------

MarsMdl_Run:
		sts	pr,@-r15
		mov 	#MARSMdl_Objects,r14
.loop:
		mov	@(mdl_data,r14),r0
		cmp/eq	#0,r0
		bt	.exitmdl
		bsr	make_model
		mov 	r0,r1
		bra	.loop		; next object
		add	#sizeof_mdl,r14
.exitmdl:

; ------------------------------------------------
; Z Sort faces
; 
; Painters algorithm
; ------------------------------------------------

		mov	#MARSMdl_ZList+4,r14	; Z points
		mov	#MARSMdl_ZList,r13	; polygon addreses	
		mov	#MARSVid_Polygns,r12	; polygon list
		mov	#MAX_ZDISTANCE,r11	; max Z distance
		mov	#MARSMdl_FaceCnt,r10	; numof_faces
		mov	@r10,r10
		mov	#0,r0
		mov	r0,@r13			; clear first entry
.next:
		cmp/pl	r11			; out of Z distance?
		bt	.exit
		cmp/pl	r10			; out of faces?
		bf	.exit

		mov	@r14,r0			; grab Z pos
		cmp/eq	#0,r0			; 0 - endoflist
		bf	.nores
		
		mov	#MARSMdl_ZList+4,r14	; Z list
		mov	#MARSVid_Polygns,r12	; polygon list
		bra	.next
		add 	#1,r11			; Z distance + 1
.nores:
		cmp/eq	#1,r0			; 1 - already set
		bt	.off
		cmp/eq	r11,r0			; Z match?
		bf	.off

	; Found face
		mov	r12,@r13		; set address
		add 	#8,r13
		mov	#0,r0
		mov	r0,@r13
		add	#1,r0
		mov	r0,@r14			; mark as set
		add 	#-1,r10
.off:
		add 	#sizeof_polygn,r12
		bra	.next
		add 	#8,r14			; next Z entry
.exit:

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read current model
; 
; r14 - model buffer
; ------------------------------------------------

make_model:
		sts	pr,@-r15
		
	; Points output
		mov	#MarsMdl_Playfld,r13
		mov 	#MarsMdl_OutPnts,r12
		mov	@r1,r10
; 		mov	#MAX_VERTICES,r0
; 		cmp/ge	r0,r10
; 		bf	.ranout
; 		mov	r0,r10
; .ranout:
		mov	@(8,r1),r11
.cpypnts:
		mov	@r11+,r2
		mov	@r11+,r3
		mov	@r11+,r4

	; Modify position
		mov	@(plyfld_x,r13),r5
		mov	@(mdl_x,r14),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r2
		sub 	r5,r2
		mov	@(plyfld_y,r13),r5
		mov	@(mdl_y,r14),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r3
		sub 	r5,r3
		mov	@(plyfld_z,r13),r5	
		mov	@(mdl_z,r14),r0
		shlr8	r0
		shll	r0
		exts	r0,r0
		add 	r0,r4
		add 	r5,r4
		
	; Rotate points
	; r2 - X
	; r3 - Y
	; r4 - Z

	; X rotation
		mov	@(mdl_x_rot,r14),r0
		mov	@(plyfld_x,r13),r7
		shlr8	r0
		bsr	mdlrd_readsine
		add 	r7,r0
		dmuls	r2,r8		; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r4,r7		; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5
		neg	r7,r7
		dmuls	r2,r7		; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r4,r8		; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2		; Save X	

	; Y rotation
		mov	@(mdl_y_rot,r14),r0
		mov	@(plyfld_y,r13),r7
		shlr8	r0
		bsr	mdlrd_readsine
		add 	r7,r0
		mov	r3,r9
		dmuls	r3,r8		; Y cos @
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r7		; Z sin @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add 	r5,r9
		neg	r7,r7
		dmuls	r3,r7		; Y -sin @
		mov	r9,r3		; Save Y
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r8		; Z cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add	r5,r9
		mov	r9,r4		; Save Z

	; Z rotation
		mov	@(mdl_z_rot,r14),r0
		mov	@(plyfld_z,r13),r7
		shlr8	r0
		bsr	mdlrd_readsine
		add 	r7,r0
		dmuls	r2,r8		; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r3,r7		; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5

		neg	r7,r7
		dmuls	r2,r7		; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r3,r8		; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2		; Save X
		mov	r6,r3

		bsr	mdlrd_calcpersp
		nop

	; r2-r3 new X
	; r5-r6 old X

		shlr8	r2
		exts	r2,r2
		shlr8	r3
		exts	r3,r3
		shlr2	r4
		exts	r4,r4
		mov	r2,@r12
		mov	r3,@(4,r12)
		mov	r4,@(8,r12)
		add 	#$C,r12
		
		dt	r10
		bf	.cpypnts
	
	; --------------------------
	; Read faces
	; --------------------------

	;  r14 - model buffer
	;  r13 - polygon buffer
	;  r12 - vertices address
	;  r11 - face address
	;  r10 - numof_faces (in model)
	;   r9 - Zbuffer list (BLANK|Z points) 
	; mach - faces drawn

		mov	#0,r0
		lds	r0,mach
		mov	#MARSVid_Polygns,r13
		mov 	#MarsMdl_OutPnts,r12
		mov 	@($C,r1),r11		; face data
		mov	@(4,r1),r10		; numof_faces
		mov	#MARSMdl_ZList+4,r9	; Zbuffer (Zdata)
		mov	#MAX_POLYGONS,r0
		cmp/ge	r0,r10
		bf	.plgnloop
		mov	r0,r10
.plgnloop:
		mov.w	@r11+,r7		; r7 - numof_points | mtrl flag
		mov.w	@r11+,r6		; r6 - material id
		cmp/pl	r7
		bt	.nomtrl
		mov	#$FF,r0
		and	r0,r7
		
	; face has texture material
		mov	r6,r0
		mov 	@($14,r1),r5		; material data
		shll2	r0
		shll	r0
		add 	r0,r5
		mov	@r5,r0
		mov	r0,r6
		mov	@(4,r5),r0
		mov	r0,@(polygn_mtrlopt,r13)

		mov	@($10,r1),r4		; texture points
		mov	r13,r3
		add 	#polygn_srcpnts,r3
		mov	r7,r5
.srcpnts:
		mov	#0,r0
		mov.w 	@r11+,r0
		shll2	r0
		mov	r4,r2
		add 	r0,r2

		mov.w	@r2+,r0
		mov.w	r0,@r3
		mov.w	@r2+,r0
		mov.w	r0,@(2,r3)
		add	#4,r3
		dt	r5
		bf	.srcpnts

.nomtrl:
	; face has points only
		; r7 - type
		mov	r6,@(polygn_mtrl,r13)
		mov	r7,@(polygn_type,r13)

	; read dest points
		mov	#0,r8			; last Z
		mov	r7,r6			; off points
		mov	r13,r5
		add 	#polygn_points,r5
.points:
		mov	#0,r0
		mov.w 	@r11+,r0
		mov	#$C,r4
		mulu	r4,r0
		sts	macl,r0
		mov	r12,r4
		add 	r0,r4

	; OOB check
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		cmp/pz	r4
		bt	.offpnts
		mov	#MAX_ZDISTANCE,r0	; max Z far
		cmp/ge	r0,r4
		bf	.offpnts
		
		mov	#-160,r0		; X out
		cmp/ge	r0,r2
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r2
		bt	.offpnts

		mov	#-112,r0		; Y out
		cmp/ge	r0,r3
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r3
		bf	.inside
.offpnts:
		add 	#-1,r6
.inside:
	; lowest Z
		cmp/gt	r8,r4
		bt	.highz
		mov	r4,r8
.highz:
	; Set X/Y
		mov	#SCREEN_WIDTH/2,r0
		add 	r0,r2
		mov	r3,r0
		add 	#SCREEN_HEIGHT/2,r0
		mov.w	r2,@r5
		mov.w	r0,@(2,r5)

		add	#4,r5
		dt	r7
		bf	.points

	; OOB set?
		cmp/pl	r6
		bf	.offbnds
		mov	r8,@r9			; add Z entry
		add 	#8,r9
		add 	#sizeof_polygn,r13
		
		sts	mach,r0
		add 	#1,r0
		lds	r0,mach
.offbnds:
		dt	r10
		bf	.plgnloop
		
		mov	#0,r0
		mov	r0,@(polygn_type,r13)
		mov	r0,@r9

		mov	#MARSMdl_FaceCnt,r2
		mov	@r2,r3
		sts	mach,r0
		add 	r0,r3
		mov	r3,@r2

		lds	@r15+,pr
		rts
		nop
		align 4
; 		ltorg

; ------------------------------------------------
; r4 - Z

mdlrd_calcpersp:
	; (160)*256 / z
		mov	#240<<8,r7	; distance << 8
		mov 	#_JR,r0
		mov	r4,r5
		cmp/pl	r4
		bf	.dontdiv
		mov 	#1,r5
.dontdiv:
		mov 	r5,@r0
		nop
		mov 	r7,@(4,r0)
		nop
		mov	#8,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov	#_HRL,r0
		mov 	@r0,r7
; .dontdiv:
		mov	r2,r5		; old X
		mov	r3,r6		; old Y
		muls	r7,r2
		sts	macl,r2		; new X
		muls	r7,r3
		sts	macl,r3		; new Y

	; Z fix
		mov	#96,r0
		add 	r0,r4
		rts
		nop
		align 4

; ------------------------------------------------
; r0 - tan
; r7 - sine
; r8 - cosine
mdlrd_readsine:
		shll2	r0
		mov	#$1FFF,r7
		and	r7,r0
		mov	#sin_table,r7
		mov	#sin_table+$800,r8
		mov	@(r0,r7),r7
		mov	@(r0,r8),r8
		rts
		nop
		align 4

		ltorg

;
; Rotate point around Z axis
;
; Entry:
;
; r5: x
; r6: y
; r7: theta
;
; Returns:
;
; r0: (x  cos @) + (y sin @)
; r1: (x -sin @) + (y cos @)
;
; 	align	2
; 
; Rotate_Point
; 
; 	shll2	r7
; 	mov	r7,r0
; 	mov	#sin_table,r1
; 	mov	#sin_table+$800,r2
; 	mov	@(r0,r1),r3
; 	mov	@(r0,r2),r4
; 
; 	dmuls.l	r5,r4		; x cos @
; 	sts	macl,r0
; 	sts	mach,r1
; 	xtrct	r1,r0
; 	dmuls.l	r6,r3		; y sin @
; 	sts	macl,r1
; 	sts	mach,r2
; 	xtrct	r2,r1
; 	add	r1,r0
; 
; 	neg	r3,r3
; 	dmuls.l	r5,r3		; x -sin @
; 	sts	macl,r1
; 	sts	mach,r2
; 	xtrct	r2,r1
; 	dmuls.l	r6,r4		; y cos @
; 	sts	macl,r2
; 	sts	mach,r3
; 	xtrct	r3,r2
; 	add	r2,r1
; 
; 	rts
; 	nop
; 
; rot_angle	dc.l	0
