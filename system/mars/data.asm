; ====================================================================
; ----------------------------------------------------------------
; MARS User data
; 
; this data is stored on SDRAM
; ----------------------------------------------------------------

TEST_PICTURPAL:	binclude "engine/data/mtrl/rubia_pal.bin"
		align 4
TEST_MODEL:
		binclude "engine/data/rubia_head.bin"
		dc.l .vert,.face,.vrtx,.mtrl	; vertices, faces, vertex, material
.vert:		binclude "engine/data/rubia_vert.bin"
.face:		binclude "engine/data/rubia_face.bin"
.vrtx:		binclude "engine/data/rubia_vrtx.bin"
.mtrl:		include "engine/data/rubia_mtrl.asm"
