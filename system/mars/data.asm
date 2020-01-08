; ====================================================================
; ----------------------------------------------------------------
; MARS User data
; 
; this data is stored on SDRAM
; ----------------------------------------------------------------

		align 4
TEST_MODEL:	binclude "engine/data/cube_head.bin"
		dc.l .vert,.face,.vrtx,.mtrl	; vertices, faces, vertex, material
.vert:		binclude "engine/data/cube_vert.bin"
.face:		binclude "engine/data/cube_face.bin"
.vrtx:		binclude "engine/data/cube_vrtx.bin"
.mtrl:		include "engine/data/cube_mtrl.asm"
TEST_PICTURPAL:	binclude "engine/data/mtrl/doremi_pal.bin"
		align 4
