; ===========================================================================
; +-----------------------------------------------------------------+
; UNTITLED GAME PROJECT
; (C)Kevin C. "GenesisFan64"
; 
; 32X version
; 
; Started on 6/November/2018
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/const.asm"	; RAM / Variables are here
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/mars/map.asm"	; MARS map
		
; ====================================================================
; ----------------------------------------------------------------
; Header
; ----------------------------------------------------------------

		include	"system/mars/head.asm"

; ====================================================================
; ----------------------------------------------------------------
; CODE Section
; 
; MCD: $FF0000
; MARS: $880000
; ----------------------------------------------------------------

Engine_Code:
		phase $FF0000
		
; --------------------------------------------------------
; Subroutines
; --------------------------------------------------------

		include	"system/md/system.asm"
		include	"system/md/video.asm"
		include	"system/md/sound.asm"
		include	"engine/global.asm"

; ====================================================================
; --------------------------------------------------------
; INIT
; --------------------------------------------------------

MD_Main:
		bsr 	Sound_init
		bsr 	Video_init
		bsr	System_Init

; ====================================================================
; --------------------------------------------------------
; Main loop
; --------------------------------------------------------

		include "engine/code.asm"

; ====================================================================

		dephase
Engine_Code_end:
	if MOMPASS=7
		message "MD CODE uses: \{Engine_Code_end-Engine_Code}"
	endif
		
; ====================================================================
; ----------------------------------------------------------------
; MARS ONLY
; 
; SH2 CODE
; ----------------------------------------------------------------

		align 4
MARS_RAMDATA:
; --------------------------------------------------------

		include "system/mars/main.asm"

; --------------------------------------------------------
		ltorg
		cpu 68000
		padding off
		dephase
MARS_RAMDATA_E:

; ====================================================================
; ----------------------------------------------------------------
; ROM data visible for SH2
; 
; this section will be
; gone if RV=1
; ----------------------------------------------------------------

		phase CS1+*
		align 4
; ---------------------------------------------

Textr_uslogo:	binclude "engine/data/mtrl/logos.bin"
		align 4
Textr_grass:	binclude "engine/data/mtrl/grass_art.bin"
		align 4
Textr_semaf:	binclude "engine/data/mtrl/semf_art.bin"
		align 4
		
; ---------------------------------------------
		dephase

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------
		
ROM_END:
		rompad (ROM_END&$FF0000)+$20000
