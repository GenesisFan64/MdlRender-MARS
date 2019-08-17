; ====================================================================
; ----------------------------------------------------------------
; DATA Section
; 
; MCD: $200000, max size: 256KB or 128KB
; MARS: $900000, max size: 1MB
; ----------------------------------------------------------------

Engine_data:
; --------------------------------------------------------

; 		include "engine/modes/title/data.asm"
		
; ====================================================================

Engine_data_end:
	if MOMPASS=7
		message "MD DATA uses: \{((Engine_data_end-Engine_data)&$FFFFF)}"
	endif
