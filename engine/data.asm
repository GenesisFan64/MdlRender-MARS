; ====================================================================
; ----------------------------------------------------------------
; DATA Section
; 
; MCD: $200000, max size: 256KB or 128KB
; MARS: $900000, max size: 1MB
; ----------------------------------------------------------------

Engine_data:
; --------------------------------------------------------

; Textr_uslogo:	binclude "engine/data/mtrl/logos.bin"
; 		align 4
; Textr_grass:	binclude "engine/data/mtrl/grass_art.bin"
; 		align 4
Textr_TestTexture:
		binclude "engine/data/mtrl/doremi_art.bin"
		align 4
		
; ====================================================================

Engine_data_end:
	if MOMPASS=7
		message "ROM DATA uses: \{((Engine_data_end-Engine_data)&$FFFFF)}"
	endif
