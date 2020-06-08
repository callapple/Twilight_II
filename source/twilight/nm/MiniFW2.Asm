	mcopy	Fireworks.Macs

ColorDiff	gequ	24
MaxDHitable gequ	2
MaxDItemNum gequ	5

	copy	T2.common.asm
	copy	T2.datactl.asm

*
*
Globals	data
*
* The Blanker's global data segment
*
*
NumFW	ds	2
Prefs	ds	2
rFWPrefs	str	'MiniFireworks Prefs'

* Blah
	end

*
*
DoBlankT2	Start
*
* Main blanker code
*
*
	using	CommonData
	using	Globals
	jsr	DoBlankT2_2	;do the setup and all...
MovePtr	equ	4	;placed here by DoBlankT2_2

* Same stuff as LedMsg2.Asm
	end

*
*
DoMakeT2	start
*
* Handles the making of all the stuff in the setup window
*
*
	using	Globals
	using	CommonData
	jsr	DoMakeT2_2	;call back for common stuff...

	ldx	#0	;high word of resource ID
	ldy	#1	;low word of resource ID
	jsr	LoadCtrlsByID

* Make sure we're dealing with the T2pref file.

	WordResult
	_GetCurResourceFile
	PushWord	RezFileID
	_SetCurResourceFile

	jsr	load_setup

noShapes1	anop
MoveOn	_SetCurResourceFile

	lda	NumFw
	and	#$7F
	tay		;value to set it to
	ldx      #1	;rControlTemplate ID
	jsr	Mk1stDatactl	;make the first datactl from disk

	lda	NumFW
	and	#$8000	;flag bit for clear screen first
	clc		;rotate in a zero
	rol	a
	rol	a	;take highest bit to lowest
	ldy	#2	;Launch Things check box

	jsr	SetCtlToVal start
	rts
	end

*
*
DoLoadSetupT2 start
*
* Handles the loading of all the stuff from the prefs file and all
*
*
	using	Globals
	using	CommonData

	jsr	load_setup
	rts

load_setup	entry
	PushWord	#$800F	;default value
	PushWord #NumFW	;pointer to word-variable to store it in
	lda	#rT2ModuleWord ;type
	ldx	#rFWPrefs	;ptr to res name
	ldy	#0	;loading only a word
	jsr	LoadAPref
	rts
	end

*
*
DoSaveT2	start
*
* Handles the saving of the module's prefs and all
*
*

	using	Globals
	using	CommonData

*
* First, grab data from controls in window.
*

	ldy	#1	;NumFireworks DataCtl
	jsr	ReadDataCtl
	sta	NumFW	;store the value it has...

            ldy	#2	;launch checkbox
	jsr	GetACtlVal
	beq	JustSaveIt
	lda	NumFW
	ora	#$8000
	sta	NumFW

*
*  Got data into the program, now store it to disk
*

JustSaveIt	WordResult
	_GetCurResourceFile
	PushWord	RezFileID
	_SetCurResourceFile

	PushWord #2	;length of block in bytes
	PushWord	NumFW	;Value to store
	lda	#rT2ModuleWord
	ldx	#rFWPrefs	;ptr to res name
	jsr	SaveAPref

	PushWord	RezFileID
	_UpdateResourceFile
	_SetCurResourceFile
	rts
	end

*
*
DoHitT2	start
*
* Handle Item hits
*
*
	using	CommonData
	jsr	DoHitT2_2
	rts
	end


*
*
DoKillT2	start
*
* "Handles" actions not supported by this module
*
*
DoUnloadSetupT2 entry
	rts		;act very noncholant about it
	end