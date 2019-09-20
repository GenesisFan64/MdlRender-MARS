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

MAX_VERTICES	equ	2730;2048
MAX_POLYGONS	equ	1024
MAX_MODELS	equ	64
MAX_ZDISTANCE	equ	-192		; lower distance, more stable

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

; 		struct $C0000000
; MarsMdl_OutPnts ds.l 3*MAX_VERTICES			; Output vertices for reading
; 		finish
		
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

; MarsVideo_Render:
; 		sts	pr,@-r15
; 		mov 	#MarsMdl_ZList,r2
; .next:
; 		mov	@r2,r0
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		bsr	MarsVideo_DrwPoly
; 		mov	r0,r1
; .off:
; 		bra	.next
; 		add 	#8,r2
; .finish:
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg

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
	; r13 - Left dda buffer
	; r14 - Right dda buffer
		mov	#PolyRndr_Left,r13
		mov	#PolyRndr_Right,r14
		mov	@(plydda_src_x,r13),r3
		mov	@(plydda_src_x,r14),r4
		mov	@(plydda_src_y,r13),r5
		mov	@(plydda_src_y,r14),r6
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
		mov 	@(plydda_src_dx,r13),r0
		add 	r0,r3
		mov 	@(plydda_src_dx,r14),r0
		add 	r0,r4
		mov 	@(plydda_src_dy,r13),r0
		add 	r0,r5
		mov 	@(plydda_src_dy,r14),r0
		add 	r0,r6

		add 	#-1,r9			; Decrement line
		add 	#-1,r10
		cmp/pl	r9
		bt	.lk
		add	#sizeof_plydda,r13
		mov	@(plydda_src_x,r13),r3
		mov	@(plydda_src_y,r13),r5
		mov 	@(plydda_x,r13),r7
		mov 	@(plydda_h,r13),r9
.lk
		cmp/pl	r10
		bt	.rk
		add	#sizeof_plydda,r14
		mov	@(plydda_src_x,r14),r4
		mov	@(plydda_src_y,r14),r6
		mov 	@(plydda_x,r14),r8
		mov 	@(plydda_h,r14),r10	
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
		shlr16	r0
		cmp/eq	#0,r0
		bf	drwpoly_texture

; ----------------------------------------
; Solid color
; ----------------------------------------

.solid_color:
		mov 	r1,@-r15
		mov 	r2,@-r15
		mov 	r3,@-r15
		mov 	r4,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		
		shlr16	r7
		exts	r7,r7
		shlr16	r8
		exts	r8,r8
 		mov	r7,r0
 		sub 	r8,r0
 		cmp/pl	r0
 		bf	.revsolid
		mov	r7,r0		; swap dest X
		mov	r8,r3
		mov 	r3,r7
		mov	r0,r8
.revsolid:
		cmp/pl	r11
		bf	.exits
		mov	r8,r0
		sub	r7,r0
		cmp/pl	r0
		bf	.exits
		cmp/eq	#1,r0
		bt	.exits

	; X crop
		cmp/pl	r7
		bt	.leftoks
		mov	#0,r7
.leftoks:
		mov 	#SCREEN_WIDTH,r0
		cmp/gt	r0,r8
		bf	.rghtoks
		mov	r0,r8
.rghtoks:

	; STABLE
		mov 	@(polygn_mtrl,r1),r0
		and	#$FF,r0
		mov	r0,r3
		shll8	r0
		or	r0,r3
		
		mov 	#-2,r2
		mov	r8,r4
		and 	r2,r4
		mov 	r7,r0
		and 	r2,r0
		sub	r0,r4
		cmp/pl	r4
		bf	.exits
		shlr	r4
		mov	r11,r0
; 		add 	#1,r0
		shll8	r0
		mov	r0,r5
		mov	r7,r0
		shlr	r0
		exts	r0,r0
		add 	r0,r5
		mov	#_vdpreg,r8
; .wstart:	mov.w	@(10,r8),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wstart
		mov	r4,r0
		mov.w	r0,@(4,r8)	; Set length
		mov	r5,r0
		mov.w	r0,@(6,r8)	; Set address
		mov	r3,r0
		mov.w	r0,@(8,r8)	; Set data
.wend:		mov.w	@(10,r8),r0
		and	#%10,r0
		tst	r0,r0
		bf	.wend

.exits:
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		mov	@r15+,r1
		rts
		nop
		align 4
		ltorg

; ----------------------------------------
; Texture material
; ----------------------------------------

; 		mov	@(plydda_src_x,r13),r3
; 		mov	@(plydda_src_x,r14),r4
; 		mov	@(plydda_src_y,r13),r5
; 		mov	@(plydda_src_y,r14),r6
; 		mov 	@(plydda_x,r13),r7	; start X
; 		mov 	@(plydda_x,r14),r8	; end X
; 		mov 	@(plydda_h,r13),r9
; 		mov 	@(plydda_h,r14),r10
drwpoly_texture:
		mov 	r1,@-r15
		mov 	r2,@-r15
		mov 	r3,@-r15
		mov 	r4,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15
		mov 	r11,@-r15

 		mov	r7,r0
 		sub 	r8,r0
 		cmp/pz	r0
 		bf	.backwrdst
		mov	r7,r0		; swap dest X
		mov	r8,r2
		mov 	r2,r7
		mov	r0,r8
		mov	r3,r0		; swap texture X
		mov	r4,r2
		mov 	r2,r3
		mov	r0,r4
		mov	r5,r0		; swap texture Y
		mov	r6,r2
		mov 	r2,r5
		mov	r0,r6
.backwrdst:
		shlr16	r7
		exts	r7,r7
		shlr16	r8
		exts	r8,r8
		
	; OOB point check
		cmp/pl	r8
		bf	.texexit
		mov	#SCREEN_WIDTH,r0
		cmp/gt	r0,r7
		bt	.texexit
		
	; Start division
		mov	r8,r0
		mov 	r7,r2
		sub 	r2,r0
		add 	#1,r0
		cmp/eq	#0,r0
		bf	.nozero
		mov 	#1,r0
.nozero:
		mov	#_JR,r2
		sub	r3,r4			; SRC X
		mov 	r0,@r2
		nop
		mov 	r4,@(4,r2)
		nop
		mov	#8,r2
.waitdx:
		dt	r2
		bf	.waitdx
		mov 	#_HRL,r2
		mov 	@r2,r4
		
		mov	#_JR,r2
		sub	r5,r6			; SRC Y
		mov 	r0,@r2
		nop
		mov 	r6,@(4,r2)
		nop
		mov	#8,r2
.waitdy:
		dt	r2
		bf	.waitdy
		mov 	#_HRL,r2
		mov 	@r2,r6

	; X crop check
		cmp/pz	r7
		bt	.leftok
		mov 	r7,r2
		mov	#0,r7
		neg 	r2,r2
.rghtfix:
		add	r4,r3				; Update X
		add	r6,r5				; Update Y
		dt	r2
		bf	.rghtfix
.leftok:
		mov 	#SCREEN_WIDTH,r0
		cmp/gt	r0,r8
		bf	.rghtok
		mov	r0,r8
.rghtok:

		mov	@(polygn_mtrl,r1),r10		; texture data
		mov	@(polygn_mtrlopt,r1),r2		; texture width
		mov 	r11,r0
		shll8	r0
		shll	r0
		mov 	#_overwrite+$200,r11
		add 	r0,r11
		add 	r7,r11
		sub 	r7,r8
		cmp/pl	r8
		bf	.texexit

.texloop:
		swap.w	r5,r1				; Build row offset
		mulu.w	r1,r2
		mov	r3,r1	   			; Build column index
		sts	macl,r0
		shlr16	r1
		add	r1,r0
		mov.b	@(r0,r10),r0			; Read pixel
		mov.b	r0,@r11	   			; Write pixel
		add 	#1,r11
		add	r4,r3				; Update X
		add	r6,r5				; Update Y
		dt	r8
		bf	.texloop
		
.texexit:
		mov 	@r15+,r11
		mov 	@r15+,r10
		mov 	@r15+,r9
		mov 	@r15+,r8
		mov 	@r15+,r7
		mov 	@r15+,r6
		mov 	@r15+,r5
		mov 	@r15+,r4
		mov 	@r15+,r3
		mov 	@r15+,r2
		mov 	@r15+,r1
		rts
		nop
		align 4
		ltorg
		
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
		mov 	#MarsMdl_Objects,r1
		mov 	#sizeof_mdl,r2
		mov 	#0,r0
.clrbuff:
		mov	r0,@r1
		add 	#4,r1
		dt	r2
		bf	.clrbuff

; 		mov 	#MarsMdl_Objects,r1
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
		mov	#MarsMdl_CurrPly,r2	; Reset stuff
		mov	#MARSVid_Polygns,r0
		mov	r0,@r2
		mov	#MarsMdl_CurrZtp,r2
		mov	#MarsMdl_ZList+4,r0
		mov	r0,@r2		
		mov	#MarsMdl_FaceCnt,r2
		mov	#0,r0
		mov	r0,@r2

		mov 	#MarsMdl_Objects,r14
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

		mov	#MarsMdl_ZList+4,r14	; Z points
		mov	#MarsMdl_ZList,r13	; polygon addreses	
		mov	#MARSVid_Polygns,r12	; polygon list
		mov	#MAX_ZDISTANCE,r11	; max Z distance
		mov	#MarsMdl_FaceCnt,r10	; numof_faces
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
		mov	#MarsMdl_ZList+4,r14	; Z list
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
		mov	r2,@-r15

; --------------------------
; Critical part
; --------------------------

	;  r14 - model buffer
	;  r13 - polygon buffer
	;  r12 - vertices address
	;  r11 - face address
	;  r10 - numof_faces (from header)
	;   r9 - Zbuffer list (BLANK|Z points) 
	; mach - faces drawn
		mov	#MarsMdl_CurrPly,r13
		mov 	#MarsMdl_CurrZtp,r9	; Zbuffer (Zdata)
		mov	@r13,r13
		mov 	@($8,r1),r12
		mov 	@($C,r1),r11		; face data
		mov	@(4,r1),r10		; numof_faces
		mov	@r9,r9

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

	; Prespective stuff
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlread_dopersp
		nop

	; -------------------------
	; OOB check
	; -------------------------
		cmp/pz	r4
		bt	.offpnts
		mov	#MAX_ZDISTANCE,r0	; max Z far
		cmp/gt	r0,r4
		bf	.offpnts
	; -------------------------
		mov	#-160,r0		; X out
		cmp/ge	r0,r2
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r2
		bt	.offpnts
	; -------------------------
		mov	#-112,r0		; Y out
		cmp/ge	r0,r3
		bf	.offpnts
		neg	r0,r0
		cmp/gt	r0,r3
		bf	.inside
		
	; -------------------------
.offpnts:
		add 	#-1,r6
.inside:
		cmp/gt	r8,r4			; lowest Z
		bt	.highz
		mov	r4,r8
.highz:
		mov	#SCREEN_WIDTH/2,r0	; Set X/Y
		add 	r2,r0
		mov.w	r0,@r5
		mov 	#SCREEN_HEIGHT/2,r0
		add 	r3,r0
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
		
		mov	#MarsMdl_FaceCnt,r7
		mov	@r7,r0
		add 	#1,r0
		mov 	#MAX_POLYGONS,r2
		cmp/ge	r2,r0
		bf	.tomuch
		mov 	r2,r0
.tomuch:
		mov 	r0,@r7
.offbnds:
		dt	r10
		bf	.plgnloop
		
		mov	#0,r0
		mov	r0,@(polygn_type,r13)
		mov	r0,@r9

		mov	#MarsMdl_CurrZtp,r0
		mov	r9,@r0
		mov	#MarsMdl_CurrPly,r0
		mov	r13,@r0

		mov	@r15+,r2
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Muliply X and Y for perspective
; persp*256/Z
; 
; r4 - Z current
; ------------------------------------------------

mdlread_dopersp:
		sts	pr,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r13,@-r15
		mov 	#MarsMdl_Playfld,r13

	; PASS 1
		mov	@(mdl_x_rot,r14),r0	; X rotation
		bsr	mdlrd_readsine
		shlr8	r0
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
		mov	@(mdl_y_rot,r14),r0	; Y rotation
		bsr	mdlrd_readsine
		shlr8	r0		
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
		mov	@(mdl_z_rot,r14),r0	; Z rotation
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
		mov	@(mdl_x,r14),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r2
		mov	@(mdl_y,r14),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r3
		mov	@(mdl_z,r14),r0
		shlr8	r0
		shll	r0
		exts	r0,r0
		add 	r0,r4

	; PASS 2
		mov	@(plyfld_x,r13),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r2
		mov	@(plyfld_y,r13),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r3
		mov	@(plyfld_z,r13),r0
		shlr8	r0
		shll	r0
		exts	r0,r0
		add 	r0,r4
		mov	@(plyfld_x_rot,r13),r0	; X rotation
		bsr	mdlrd_readsine
		shlr8	r0
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
		mov	@(plyfld_y_rot,r13),r0	; Y rotation
		bsr	mdlrd_readsine
		shlr8	r0		
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
		mov	@(plyfld_z_rot,r13),r0	; Z rotation
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

	; Y perspective
		mov	#256*256,r8
		mov	#256*256,r7
		mov	r4,r0
		cmp/pz	r0
		bf	.dontdiv
		mov 	#1,r0
.dontdiv:
		mov 	#_JR,r5
		mov 	r0,@r5
		nop
		mov 	r7,@(4,r5)
		nop
		mov	#8,r5
.waitdx:
		dt	r5
		bf	.waitdx
		mov	#_HRL,r5
		mov 	@r5,r5
		dmuls	r5,r3
		sts	macl,r3		; new Y
		cmp/pz	r4
		bf	.dontfix
		neg 	r3,r3
.dontfix:

	; X perspective
		mov	r4,r0
		cmp/pz	r0
		bf	.dontdiv2
		mov 	#1,r0
.dontdiv2:
		mov 	#_JR,r5
		mov 	r0,@r5
		nop
		mov 	r8,@(4,r5)
		nop
		mov	#8,r5
.waitdx2:
		dt	r5
		bf	.waitdx2
		mov	#_HRL,r5
		mov 	@r5,r5
		dmuls	r5,r2
		sts	macl,r2		; new X
		cmp/pz	r4
		bf	.dontfix2
		neg	r2,r2
.dontfix2:

		shlr8	r2
		exts	r2,r2
		shlr8	r3
		exts	r3,r3
		shlr2	r4
		exts	r4,r4

		mov	@r15+,r13
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; r0 - tan
; r7 - sine
; r8 - cosine
mdlrd_readsine:
; 		sts	pr,@-r15
		shll2	r0
		mov	#$1FFF,r7
		and	r7,r0
		mov	#sin_table,r7
		mov	#sin_table+$800,r8
		mov	@(r0,r7),r7
		mov	@(r0,r8),r8
; 		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg
