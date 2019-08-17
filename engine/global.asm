; ====================================================================
; ---------------------------------------------
; Put your global structs/values here
; ---------------------------------------------

; -------------------------------------
; Structures
; -------------------------------------

; Player data

; plyr_flags
bitActive	equ 7

		struct 0
plyr_blocks	ds.l 1		; block address
plyr_timers	ds.l 1		; timer address
plyr_control	ds.l 1		; controller address data
plyr_vscrl	ds.l 1		; current vertical scroll
plyr_vspd	ds.l 1		; max add speed
plyr_vadd	ds.l 1		; button add speed
plyr_width	ds.w 1		; blocks width
plyr_height	ds.w 1		; blocks height
plyr_flags	ds.w 1		; byte
plyr_xpos	ds.w 1		; board xpos
plyr_ypos	ds.w 1		; board ypos
sizeof_plyr	ds.l 0
		finish
		
; -------------------------------------
; RAM
; 
; This section will not be deleted by
; switching game modes
; -------------------------------------

		struct RAM_Global
Puzl_Player	ds.b sizeof_plyr*4
Puzl_Blocks	ds.b $800*4
Puzl_Timers	ds.b $800*4
Puzl_Mode	ds.w 1
sizeof_global	ds.l 0
		finish
		
