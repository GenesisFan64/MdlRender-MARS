; ====================================================================
; ----------------------------------------------------------------
; MARS Video
; ----------------------------------------------------------------

; MARS Polygons
; 
; type format:
;  0 - end-of-list
; -1 - skip polygon (already drawn)
;
; tttt nnnn
; 
; nnnn:
;   $03 - triangle
;   $04 - quad
;
; tttt
;   $00 - no change
;   $01 - dithering

; ----------------------------------------
; Settings
; ----------------------------------------

MAX_VERTICES	equ	512
MAX_POLYGONS	equ	512
MAX_MODELS	equ	16

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
		
; model slot struct
		struct 0
mdl_data	ds.l 1
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
polygn_type	ds.l 1			; Setting | Type ( Polygon(3) or Quad(4) )
polygn_mtrl	ds.l 1			; Material Type: Color (0-$FF) or Texture data address
polygn_mtrlopt	ds.l 1			; Material Setting: add $xx to solid color / texture width
polygn_flags	ds.l 1			; if required
polygn_points	ds.l 2*4		; X/Y/Z
polygn_srcpnts	ds.l 2*4
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
		mov 	#MARSVid_Polygns,r1
.next:
		mov	@(polygn_type,r1),r0
		cmp/eq	#0,r0
		bt	.finish
		cmp/eq	#-1,r0
		bt	.off
		bsr	MarsVideo_DrwPoly
		nop
.off:
		bra	.next
		add 	#sizeof_polygn,r1

.finish:
		lds	@r15+,pr
		rts
		nop
		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Video subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrwPoly
; 
; r1 - polygon points
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
		mov 	r0,r7
		mov 	r1,r8
		add 	#polygn_points,r8
		mov 	#0,r10			; start point id
		mov 	#0,r9			; counter
.first_y:
		mov 	@(4,r8),r0
		add 	#SCREEN_HEIGHT/2,r0
		cmp/gt	r11,r0
		bt	.yhigh
		mov 	r0,r11
		mov 	r9,r10
.yhigh:
		cmp/ge	r0,r12
		bt	.yhighb
		mov 	r0,r12
.yhighb:
		add 	#8,r8			; sizeof_point
		add 	#8,r9			; next point*sizeof_point
		dt	r7
		bf	.first_y
		add 	#-8,r9			; get back

		cmp/pl	r12			; bottom < 0
		bf	.exit
		mov 	#SCREEN_HEIGHT/2,r0
		shll	r0
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

		mov	@(plydda_src_x,r13),r2
		mov	@(plydda_src_y,r13),r3
		mov 	@(plydda_src_dx,r13),r4
		mov 	@(plydda_src_dy,r13),r5
		add 	r4,r2
		add 	r5,r3
		mov	r2,@(plydda_src_x,r13)
		mov	r3,@(plydda_src_y,r13)
		mov	@(plydda_src_x,r14),r2
		mov	@(plydda_src_y,r14),r3
		mov 	@(plydda_src_dx,r14),r4
		mov 	@(plydda_src_dy,r14),r5
		add 	r4,r2
		add 	r5,r3
		mov	r2,@(plydda_src_x,r14)
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
		mov 	#_overwrite+$200,r6
		mov 	r11,r0
		shll8	r0
		shll	r0
		add 	r0,r6
		
	; r4 - left
	; r5 - right
; 		mov 	#2,r6
; 		mov 	r4,r3
; 		mov	r5,r0
; 		sub 	r3,r0
; 		cmp/gt	r6,r0
; 		bf	.bad


	; Left
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
		mov 	r3,r0
		shll8	r0
		or	r0,r3			; $xxxx
		mov 	r4,r0			; r4 - X
		cmp/pl	r0			; < 0
		bf	.min_l
		mov 	#SCREEN_WIDTH,r2	; > 320
		cmp/ge	r2,r0
		bt	.min_l
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

	; Right
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
		mov 	r3,r0
		shll8	r0
		or	r0,r3
		mov 	r5,r0
		cmp/pl	r0
		bf	.min_r
		mov 	#SCREEN_WIDTH,r2
		cmp/ge	r2,r0
		bt	.min_r
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
		mov 	@(polygn_mtrl,r1),r3
		mov 	@(polygn_mtrlopt,r1),r0
		add 	r0,r3
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
		sub	r4,r5
		mov 	#_JR,r0
		mov 	r3,@r0
		nop
		mov 	r5,@(4,r0)
		nop
		mov	#32,r0
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
		mov	#32,r0
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
		mov 	#$8000,r3
		
		mov 	r1,r2
		add 	#polygn_points,r2
		add 	r8,r2
		mov 	@r2,r4			; r4 - OLD X point
		mov	#SCREEN_WIDTH/2,r0
		add 	r0,r4
		mov 	r4,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_x,r14)
		mov 	@(4,r2),r5		; r5 - OLD Y point
		add 	#SCREEN_HEIGHT/2,r5
		
	; SRC OLD POINTS
		mov 	r1,r2
		add 	#polygn_srcpnts,r2
		add 	r8,r2
		mov 	@r2,r6			; r6 - OLD SRC X point
		mov 	r6,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_src_x,r14)
		mov 	@(4,r2),r7		; r7 - OLD SRC Y point
		mov 	r7,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_src_y,r14)
		
		add 	#8,r8
		cmp/gt	r9,r8
		bf	.lft_ok
		mov 	#0,r8
.lft_ok:
		mov 	r1,r2
		add 	#polygn_points,r2
		add 	r8,r2
		mov 	@(4,r2),r3		; r3 - NEW Y point
		mov	#SCREEN_HEIGHT/2,r0
		add 	r0,r3

		mov 	r3,r0
		sub 	r5,r0
		cmp/eq	#0,r0			; if Y == 0
		bt	dda_left		; try again
		cmp/pz	r0			; if Y < 0
		bf	.exit			; exit this
		mov 	r0,@(plydda_h,r14)
		mov 	r0,r5
		
		mov 	@r2,r2			; r2 - NEW X point
		mov	#SCREEN_WIDTH/2,r0
		add 	r0,r2
		sub 	r4,r2
		shll16	r2
		mov	#_JR,r0			; NEW X / HEIGHT
		mov 	r5,@r0
		nop
		mov 	r2,@(4,r0)
		nop
		mov	#32,r0
.wait:
		dt	r0
		bf	.wait
		mov	#_HRL,r0
		mov	@r0,r2
		mov	r2,@(plydda_dx,r14)
		
	; SRC
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov 	@r3,r2
		sub 	r6,r2
		mov 	@(4,r3),r3
		sub 	r7,r3
	
		mov	#_JR,r6
		mov	#_HRL,r7
		shll16	r2
		shll16	r3
		
	; calc dx
		mov 	r5,@r6
		nop
		mov 	r2,@(4,r6)
		nop
		mov	#32,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov	@r7,r2
		mov	r2,@(plydda_src_dx,r14)
	; calc dy
		mov 	r5,@r6
		nop
		mov 	r3,@(4,r6)
		nop
		mov	#32,r0
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
		mov 	#$8000,r3
		
		mov 	r1,r2
		add 	#polygn_points,r2
		add 	r8,r2
		mov 	@r2,r4			; r4 - OLD X point
		mov	#SCREEN_WIDTH/2,r0
		add 	r0,r4
		mov 	r4,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_x,r14)
		mov 	@(4,r2),r5		; r5 - OLD Y point
		add 	#SCREEN_HEIGHT/2,r5
		
	; SRC OLD POINTS
		mov 	r1,r2
		add 	#polygn_srcpnts,r2
		add 	r8,r2
		mov 	@r2,r6			; r6 - OLD SRC X point
		mov 	r6,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_src_x,r14)
		mov 	@(4,r2),r7		; r7 - OLD SRC Y point
		mov 	r7,r0
		shll16	r0
		or	r3,r0
		mov 	r0,@(plydda_src_y,r14)

		add 	#-8,r8
		cmp/pz	r8
		bt	.lft_ok
		mov 	r9,r8
.lft_ok:
		mov 	r1,r2
		add 	#polygn_points,r2
		add 	r8,r2
		mov 	@(4,r2),r3		; r3 - NEW Y point
		mov	#SCREEN_HEIGHT/2,r0
		add 	r0,r3
		
		mov 	r3,r0
		sub 	r5,r0
		cmp/eq	#0,r0			; if Y == 0
		bt	dda_right		; try again
		cmp/pz	r0			; if Y < 0
		bf	.exit			; exit this
		mov 	r0,@(plydda_h,r14)
		mov 	r0,r5
		
		mov 	@r2,r2			; r2 - NEW X point
		mov	#SCREEN_WIDTH/2,r0
		add 	r0,r2
		sub 	r4,r2
		shll16	r2
		mov	#_JR,r0			; NEW X / HEIGHT
		mov 	r5,@r0
		nop
		mov 	r2,@(4,r0)
		nop
		mov	#32,r0
.wait:
		dt	r0
		bf	.wait
		mov	#_HRL,r0
		mov	@r0,r2
		mov	r2,@(plydda_dx,r14)
		
	; SRC
		mov 	r1,r3
		add 	#polygn_srcpnts,r3
		add 	r8,r3
		mov 	@r3,r2
		sub 	r6,r2
		mov 	@(4,r3),r3
		sub 	r7,r3
	
		mov	#_JR,r6
		mov	#_HRL,r7
		shll16	r2
		shll16	r3
		
	; calc dx
		mov 	r5,@r6
		nop
		mov 	r2,@(4,r6)
		nop
		mov	#32,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov	@r7,r2
		mov	r2,@(plydda_src_dx,r14)
	; calc dy
		mov 	r5,@r6
		nop
		mov 	r3,@(4,r6)
		nop
		mov	#32,r0
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
		mov 	#MARSVid_MdlList,r1
		mov 	#sizeof_mdl,r2
		mov 	#0,r0
.clrbuff:
		mov	r0,@r1
		add 	#4,r1
		dt	r2
		bf	.clrbuff

		mov 	#MARSVid_MdlList,r1
		mov 	#TEST_MODEL,r0
		mov 	r0,@(mdl_data,r1)
		rts
		nop
		align 4

; --------------------------------------------------------
; Calculate models (not Render)
; --------------------------------------------------------

MarsMdl_Run:
		sts	pr,@-r15
		mov 	#MARSVid_MdlList,r14
.loop:
		mov	@(mdl_data,r14),r0
		cmp/eq	#0,r0
		bt	.exit
		bsr	.this_model
		mov 	r0,r1
		add	#sizeof_mdl,r14
		bra	.loop
		nop
.exit:
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Read current model
; 
; r14 - model buffer
; ------------------------------------------------

.this_model:
		sts	pr,@-r15
		
	; Points output
; 		mov 	#MarsMdl_OutPnts,r12
		mov	@($10,r1),r13
; 		mov	#154,r0			; max cache points
; 		cmp/ge	r0,r13
; 		bf	.ranout
		mov	#MarsMdl_OutPnts,r12
; .ranout:
		mov	r12,r11
		mov	@r1,r10
.cpypnts:
		mov	@r10+,r2
		mov	@r10+,r3
		mov	@r10+,r4

		mov	@(mdl_x,r14),r0
		sub 	r0,r2
		mov	@(mdl_y,r14),r0
		sub 	r0,r3
		mov	@(mdl_z,r14),r0
		add 	r0,r4

		mov	#160*256,r5
		mov 	#_JR,r0
		mov 	r4,@r0
		nop
		mov 	r5,@(4,r0)
		nop
		mov	#32,r0
.waitdx:
		dt	r0
		bf	.waitdx
		mov 	#_HRL,r0
		mov 	@r0,r0
		muls	r0,r2
		sts	macl,r2
		muls	r0,r3
		sts	macl,r3
		
		shlr8	r2
		exts	r2,r2
		shlr8	r3
		exts	r3,r3
		mov	r2,@r11
		mov	r3,@(4,r11)
		mov	r4,@(8,r11)		
		
		add 	#$C,r11

		dt	r13
		bf	.cpypnts
	
	; --------------------------
	; Read faces
	; --------------------------

		mov	#MARSVid_Polygns,r13
		; r12 - vertices
		mov 	@(4,r1),r11		; face data
		mov	@($14,r1),r10		; numof_faces
		mov	#0,r9
		mov	#0,r8
		mov	#MAX_POLYGONS,r0
		cmp/ge	r0,r10
		bf	.plgnloop
		mov	r0,r10
.plgnloop:
		mov.w	@r11+,r9		; r9 - numof_points | mtrl flag
		mov.w	@r11+,r8		; r8 - material id
		cmp/pl	r9
		bt	.nomtrl
		mov	#$FF,r0
		and	r0,r9
		
	; face has texture material
		mov	r8,r0
		mov 	@($C,r1),r7		; material data
		shll2	r0
		shll	r0
		add 	r0,r7
		mov	@r7,r0
		mov	r0,r8
		mov	@(4,r7),r0
		mov	r0,@(polygn_mtrlopt,r13)

		mov	@(8,r1),r4		; texture points
		mov	r13,r3
		add 	#polygn_srcpnts,r3
		mov	r9,r7
.srcpnts:
		mov	#0,r0
		mov.w 	@r11+,r0
		shll2	r0
		mov	r4,r2
		add 	r0,r2

		mov.w	@r2+,r0
		mov	r0,@r3
		mov.w	@r2+,r0
		mov	r0,@(4,r3)
		add	#8,r3
		dt	r7
		bf	.srcpnts

.nomtrl:
	; face has points only
		; r9 - type
		mov	r8,@(polygn_mtrl,r13)

	; read dest points
	; free regs: r4-r6
		mov	#0,r8		; off points
		mov	r9,r7		; numof_points loop
		mov	r13,r3
		add 	#polygn_points,r3
.points:
		mov	#0,r0
		mov.w 	@r11+,r0
		mov	#$C,r2
		mulu	r2,r0
		sts	macl,r0
		mov	r12,r2
		add 	r0,r2

	; Z OOB
		mov	@r2,r4
		mov	@(4,r2),r5
		mov	@(8,r2),r6
		mov	#-192*8,r0	; max Z far
		cmp/ge	r0,r6
		bf	.offpnts
		cmp/pz	r6
		bt	.offpnts

	; X/Y OOB check
		mov	#-160*8,r0
		cmp/ge	r0,r4
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r4
		bt	.offpnts

		mov	#-112*8,r0
		cmp/ge	r0,r5
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r5
		bf	.inside
.offpnts:
		add 	#1,r8
.inside:
		mov	r4,@r3
		mov	r5,@(4,r3)
		add	#8,r3
		dt	r7
		bf	.points
		
		mov	#sizeof_polygn,r2
		mov	#4,r0
		cmp/pl	r8
		bf	.offbnds

		mov	#0,r9
		mov	#0,r2
.offbnds:
		mov	r9,@(polygn_type,r13)
		add 	r2,r13
		dt	r10
		bf	.plgnloop
		
		mov	#0,r0
		mov	r0,@(polygn_type,r13)
		
		lds	@r15+,pr
		rts
		nop
		align 4
; 		ltorg

; ; --------------------------------------------------------
; ; TEMPORAL
; ; --------------------------------------------------------
; 
; ; r1 - model data
; MarsMdl_TEMP:
; 		sts	pr,@-r15
; 
; 		mov 	#320/2,r7
; 		mov 	@r1,r2
; 		mov 	@(8,r1),r6
; .drwvert:
; 		mov 	@(4,r2),r0
; 		add 	#224/2,r0
; 		shll8	r0
; 		shll 	r0
; 		mov 	r0,r5
; 		mov 	@r2,r0
; 		add 	r7,r0
; 		add 	r0,r5
; 		mov 	#_framebuffer+$200,r4
; 		add 	r5,r4
; 		mov 	#1,r0
; 		mov.b	r0,@r4
; 		
; 		add	#$C,r2
; 		dt	r6
; 		bf	.drwvert
; 
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg