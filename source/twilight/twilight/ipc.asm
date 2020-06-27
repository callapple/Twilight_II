         setcom 80
	mcopy	ipc.mac
	keep	ipc
	copy  13:ainclude:e16.memory
	copy	equates
	copy	v1.2.equ
	copy	debug.equ
*-----------------------------------------------------------------------------*
* T2 EXTERNAL IPC Implementation Start
* V1.00 - T2 v1.0d37 - September 13, 1992 by JRM - started coding.
* v1.01 - T2 v1.0.1b3 - December 27, 1992 by JRM - seperate source segment
*-----------------------------------------------------------------------------*
* T2TurnOn - EXTERNAL IPC
*  Turn T2 on.
*  This is ALMOST the equivalent of pressing shift-clear to turn T2 back on.
*
* dataIn: reserved
* dataOut: reserved
*
* V1.00 - 1.0d37 - September 13, 1992 by JRM - Implementation
* v1.1 - t2 1.1f4 - March 24, 1993 by JRM - inc/dec

ipcTurnOn	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2TurnOn'

	copy	22:debug.asm

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	ipcT2Off	; 0 = T2 is on
	beq	done
	dec	ipcT2Off
done	rts

	End
*-----------------------------------------------------------------------------*
* T2TurnOff - EXTERNAL IPC
*  Turn T2 off.
*  This is ALMOST the equivalent of pressing shift-clear to turn T2 back off.
*
* dataIn: reserved
* dataOut: reserved
*
* V1.00 - 1.0d37 - September 13, 1992 by JRM - Implementation
* v1.1 - t2 1.1f4 - March 24, 1993 by JRM - inc/dec

ipcTurnOff	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2TurnOff'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	inc	ipcT2Off
	rts

	End
*-----------------------------------------------------------------------------*
* T2BoxOverrideOff - EXTERNAL IPC
*  Turn blinking box on by turning the override flag off.
*  This is the temporary (i.e. not saved to disk) equivalent of turning on the
*   blinking box checkbox in Setup: Options.
*  The box will only be turned on if the user has the box turned on in setup.
*  In other words, the override flag will be ignored if the box is already
*   turned off in setup.
*
* dataIn: reserved
* dataOut: reserved
*
* V1.00 - 1.0d37 - September 13, 1992 by JRM - Implementation

ipcBoxOverrideOff Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2BoxOverrideOff'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

* We do not simply clear a bit in OptionsFlag to turn
* on the box when a t2BlinkBoxOff request is received because that would fuck
* with setup and that is not good.
* By using an override flag, we also guarantee that the box will not be turned
* on by any applications if the user has it turned off in setup.

;	lda	#FALSE
	stz	BoxOverride
	rts

	End
*-----------------------------------------------------------------------------*
* T2BoxOverrideOn - EXTERNAL IPC
*  Turn blinking box off by turning on the box override flag.
*  This is the temporary (i.e. not saved to disk) equivalent of turning off the
*   blinking box checkbox in Setup: Options.
*  The box will only be turned off if the user has the box turned off in setup.
*  In other words, the override flag will be ignored if the box is already
*   turned off in setup.
*
* dataIn: reserved
* dataOut: reserved
*
* V1.00 - 1.0d37 - September 13, 1992 by JRM - Implementation

ipcBoxOverrideOn Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2BoxOverrideOn'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

* We do not simply clear a bit in OptionsFlag to turn
* off the box when a t2BlinkBoxOff request is received because that would fuck
* with setup and that is not good.
* By using an override flag, we also guarantee that the box will not be turned
* on by any applications if the user has it turned off in setup.

	mvw	#TRUE,BoxOverride
	rts

	End
*-----------------------------------------------------------------------------*
* T2GetInfo - EXTERNAL IPC
*  Return the state of/information on several apsects of T2.
*
* dataIn: reserved (pass zero)
* dataOut: pointer to structure
*  +00 - word output - count
*  +02 - word input - start buffer offset (FROM this byte)
*  +04 - word input - end buffer offset   (TO this byte)
* (end buffer offset minus start buffer offset = SIZE)
*  +06 - byte array output - returned information output buffer
*  +06+SIZE - eos - end of structure
*
* Buffer information available (`-`=through)
*  00,01= state word
*  02,03= number of modules selected in random mode (1 if rm off)
*  04,05= version of Twilight II
*  06,07,08,09= pointer to 320 mode don't blank cursor
*  0a,0b,0c,0d= pointer to 640 mode don't blank cursor
*
* state word structure currently defined bits as follows:
*  bit 0 - current blinking box setup status
*         - %0 = blinking box turned off in setup
*         - %1 = blinking box turned on in setup
*  bit 1 - current blinking box override status
*         - %0 = blinking box override off
*         - %1 = blinking box override on
*  bit 2 - current background blank state
*         - %0 = screen is not currently background blanked
*         - %1 = screen is currently background blanked
*  bit 3 - current foreground blank state
*         - %0 = screen is not currently foreground blanked
*         - %1 = screen is currently foreground blanked
*  bit 4 - current active status - i.e. shift-clear
*         - %0 = twilight currently on
*         - %1 = twilight currently off
*  bit 5 - random mode on/off
*         - %0 = random mode off
*         - %1 = random mode on
*
* V1.00 - T2 v1.0d37 - September 13, 20, 1992 by JRM - Implementation
* v1.01 - T2 v1.0.1f2 - January 31 (ski!), 1993 - JRM - bit 5!, tsb.
* v1.02 - T2 v1.0.1f2 - February 3 (ROJAC!), 1993 - JRM - more info!

ipcGetInfo	Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	debug 'T2GetInfo'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

oStart_offset	equ	2
oEnd_offset	equ	4
oArray	equ	6

	jsr	makeStatusWord	; make the status word

	ldy	#oEnd_offset
	lda	[dataOut],y	; get end offset into infotbl
	sta	end+1

	ldy	#oStart_offset
	lda	[dataOut],y	; get start offset into infotbl
	tax
	ldy	#oArray	; start offset into dataout
copyProcs	lda	GetInfoBuffer,x
	sta	[dataOut],y
	iny
	iny
	inx
	inx
	cpx	#$0E	; past end of table?
	bge	exit	; yes, so stop
end	cpx	#0
	blt	copyProcs
exit	rts


makeStatusWord	anop
	stz	statusword	; set all bits to 0

	lda	OptionsFlag
	bit	#fBlinkingBox
               beq   boxOffInSetup	; leave bit 0 as 0 - box off in setup
	lda	#%1
	tsb	statusword	; set bit 0 to 1 - box on in setup

boxOffInSetup	anop

	lda	BoxOverride
	beq	overrideOff	; leave bit 1 as 0 - override off
	lda	#%10
;	ora	statusword
	tsb	statusword	; set bit 1 to 1 - override on

overrideOff	anop

	lda	NowFlag
	bne	noBkgBlank	; leave bit 2 as 0 - no bkg currently
	lda	#%100
;	ora	statusword
	tsb	statusword	; set bit 2 to 1 - bkg blank currently

noBkgBlank	anop

	lda	BlankFlag
	bne	noFrgBlank	; leave bit 3 as 0 - no frg currently
	lda	#%1000
;	ora	statusword
	tsb	statusword	; set bit 3 to 1 - frg blank in progress

noFrgBlank	anop

	lda	OnFlag
	bne	T2On	; leave bit 4 as 0 - t2 currently on
	lda	#%10000
;	ora	statusword
	tsb	statusword

T2On	anop

	lda	OptionsFlag
	bit	#fRandomize
	beq	noRandom
	lda	#%100000
	tsb	statusword

noRandom	anop
	rts

	End
*-----------------------------------------------------------------------------*
* T2StartupTools - startup any tools needed by modules.
*
* V1.00 - 1.0d37 - September 14-5, 1992 Jim R. Maricondo.
* V1.01 - 1.0.1b3 - December 26, 1992 Jim R. Maricondo.  Better error handling.
*
* dataIn - lo word: int bit flags for tools to start up.
*                   following bits currently defined:
*                       bit 0 = startup SANE
*                       bit 1 = startup sound manager
*        - hi word: int userid to allocate memory with
*
* dataOut - ptr to:
*  +00 word count - count
*  +02 word errors - any errors incurred in the startup
*
* NOTE: If there are any errors incurred, no tools will be started up and
*       no memory will be kept allocated!  This should make it easy for module
*       writers.
*

ipcStartupTools Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	Using	StartStopToolDATA
	debug 'T2StartupTools'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	stz	SaneHandle
	stz	SaneHandle+2
	stz	SoundHandle
	stz	SoundHandle+2

	lda	<dataIn
	bit	#%1
	beq	notSane

	LongResult
	ldy	#0
	phy
	PushWord #$100	; 1 page
	pei	<dataIn+2	; id
	PushWord #attrLocked+attrNoCross+attrBank+attrFixed+attrPage
	phy
	phy
	_NewHandle
	bcc   HandleOK
	plx
	plx
	brk	$EB
	brl	exit
HandleOK	anop
	lda	1,s
	sta	SaneHandle
	lda	1+2,s
	sta	SaneHandle+2
	makeDP
	lda	[3]
	pha
	_SaneStartup
	killLdp
	bcc	ok1
	pha
	~DisposeHandle SaneHandle
	pla
	bra	exit
ok1	anop

notSane	anop
	lda	<dataIn
	bit	#%10
	beq	noerrorexit

startSound	anop
	LongResult
	ldy	#0
	phy
	PushWord #$100	; 1 page
	pei	<dataIn+2	; id
	PushWord #attrLocked+attrNoCross+attrBank+attrFixed+attrPage
	phy
	phy
	_NewHandle
	bcc   HandleOK2
	plx
	plx
	brk	$EC
	bra	errorexit_snd
HandleOK2	anop
	lda	1,s
	sta	SoundHandle
	lda	1+2,s
	sta	SoundHandle+2
	makeDP
	lda	[3]
	pha
	_SoundStartup
	killLdp
	bcc	ok2
	pha
	~DisposeHandle SoundHandle
	pla
	bra	errorexit_snd
ok2	anop

noerrorexit	anop
	lda	#0
	bra	exit
errorexit_snd	anop
	pha
	lda	SaneHandle
	ora	SaneHandle+2
	bne	no_sane
	~DisposeHandle SaneHandle
	_SaneShutdown
no_sane	pla
exit	ldy	#2
	sta	[dataOut],y	; no errors!
	rts

	End
*-----------------------------------------------------------------------------*
* T2ShutdownTools - shutdown any tools needed by modules.
*
* V1.00 - 1.0d37 - September 14-5, 1992 Jim R. Maricondo.
*
* dataIn - lo word: int bit flags for tools to shut down.
*                   following bits currently defined:
*                       bit 0 = shutdown SANE
*                       bit 1 = shutdown sound manager
*        - hi word: reserved.
*
* dataOut - reserved.
*
* NOTE: no error checking is performed to verify if the tools were even started
*       in the first place, much less if they were started by you or not.
*       So have some responsibility!

ipcShutdownTools Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	Using	StartStopToolDATA
	debug 'T2ShutdownTools'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	<dataIn
	bit	#%1
	beq	notSane

	_SaneShutdown
	~DisposeHandle SaneHandle

notSane	anop
	lda	<dataIn
	bit	#%10
	beq	exit

	_SoundShutdown
	~DisposeHandle SoundHandle

exit	rts

	End
*-----------------------------------------------------------------------------*
StartStopToolDATA Data
	debug	'StartStopToolDATA'

SaneHandle	ds	4
SoundHandle	ds	4

	End
*-----------------------------------------------------------------------------*
* T2ShareMemory -
*
* V1.00 - 1.0d37 - September 15, 1992 Jim R. Maricondo.
* v1.1  - v1.1f4 - March 15, 1993 (no school!) Jim R. Maricondo
*
* dataIn - reserved.
*
* dataOut - pointer to structure:
*  +00 - word - count
*  +02 - word - size of buffer
*  +04 - long - pointer to buffer
* 
* You may modify this buffer at your leisure; it's not going anywhere.
* However, you _must_ get its address each time you receive MakeT2 or
*  BlankT2 or whatever.. don't assume that it won't move.
*  (Because if purge is pressed, it _will_ move!)
*
* It is suggested that you use the first two bytes of this 16 byte buffer
* as an ID word.  Stick a unique integer value in it so you know if someone
* else overwrote your buffer!

ipcShareMemory	Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	debug 'T2ShareMemory'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	#16
	ldy	#2
	sta	[dataOut],y
	iny
	iny
	lda	#shared_memory
	sta	[dataOut],y
	iny
	iny
	lda	#^shared_memory
	sta	[dataOut],y
	rts

shared_memory	ds	16 	; the shared memory

	End
*-----------------------------------------------------------------------------*
* T2SetBlinkProc - set a custom procedure called to blink the T2 menubar box.
*
* V1.00 - 1.0d37 - September 15, 1992 Jim R. Maricondo.
*
* dataIn - longint: pointer to custom blink procedure
*                   if 0, the current procedure is removed
*
* dataOut - reserved.
*
* NOTE: The custom blink procedure will be called every half a second or so
*       almost without fail.  It will be called even if the user has the normal
*       blinking box turned off in setup, so if you wish to honor the user's
*       request of not to blink, call T2GetCurState and look at bit 0.
*       In most cases, I would think that you would want to honor the user's
*       wish not to blink the box, but I leave it at the descretion of the
*       programmer.
* NOTE: In addition to JSL'ing to your custom handler the normal box will STILL
*       blink the normal box, so be sure to set the override flag if you don't
*       wish this to happen!
* NOTE: Only applications may make this call.
* NOTE: Keep your routine VERY SMALL; I suggest you only set a flag
*       or something simular.

ipcSetBlinkProc Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	Using	StartStopToolDATA
	debug 'T2SetBlinkProc'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	<dataIn
	sta	CustomBlinkProc+1
	lda	<dataIn+1
	sta	CustomBlinkProc+2
	rts

	End
*-----------------------------------------------------------------------------*
* T2BkgBlankNow - force a background blank, NOW!
*
* V1.00 - 1.0d37 - September 23, 1992 Jim R. Maricondo.
*
* dataIn - reserved.
* dataOut - reserved.
*
* NOTE: currently this will only work in SHR desktop programs
*       (you can't force a text bkg blank).  This might change in the future.
*

ipcBkgBlankNow	Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	debug 'T2BkgBlankNow'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	mvw	#TRUE,ImmediateBkgBlank
	rts

	End
*-----------------------------------------------------------------------------*
* T2GetBuffers - return handles to the two 64k SHR memory buffers, etc
*
* V1.00 - T2 v1.0d38 - September 25-6, 1992 Jim R. Maricondo.
*
* dataIn - reserved.
*
* dataOut - pointer to structure
*  +00 - word - count
*  +02 - long - handle to E1 buffer ($8000 bytes).
*  +06 - long - handle to 01 buffer ($8000 bytes) or NIL if none.
*  +10 - long - handle to palette buffer ($200 bytes).
*  +14 - eos  - end of structure

ipcGetBuffers	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2GetBuffers'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	ldx	#12-2
	ldy	#14-2
copy	lda	Screen1Hndl,x
	sta	[dataOut],y
	dey
	dey
	dex
	dex
	bpl	copy
	rts

	End
*-----------------------------------------------------------------------------*
* T2CalcFreqOffset - Convert rSound relPitch to ffstartsound freqOffset value.
*
* V1.00 - 1.0.1b2 - December 9, 1992 Jim R. Maricondo.
*
* This implements this formula w/o using SANE: ("Fw" is in HCGS TN 3)
*   freqOffset = 1.9596 * 2^(.000325521 * relPitch) * Fw
* This code ripped out of the System 6.0 Sound Control Panel. (Thanks DAL & Apl)
*
* dataIn - long - relpitch in lo word; hi word = $0000
*
* dataOut - pointer to structure
*  +00 - word - count
*  +02 - word - freqOffset for use with FFStartSound

ipcCalcFreqOffset Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'ipcCalcFreqOffset'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	<dataIn
               bmi   neg_pitch
               clc
               adc   #$3C00
               bra   go_pitch
neg_pitch      and   #$7FFF
               eor   #$FFFF
               inc   a
               adc   #$3C00
go_pitch       jsr   calcFreqOffset
	ldy	#2
               sta   [dataOut],y
	rts

calcFreqOffset name
               clc
               adc   #$07C8
               ldy   #$000B
               sec
               sbc   #$0C00
               bmi   L0AE7
L0AE1          dey
               sbc   #$0C00
               bpl   L0AE1
L0AE7          adc   #$0C00
               phy
               and   #$FFFE
               tay
               lda   freqLookupTbl,y
               ply
               dey
               bmi   L0AFA
L0AF6          lsr   a
               dey
               bpl   L0AF6
L0AFA          rts

freqLookupTbl  dc    i2'$51A9,$51B2,$51BC,$51C5'
               dc    i2'$51CF,$51D8,$51E2,$51EB'
               dc    i2'$51F5,$51FE,$5208,$5211'
               dc    i2'$521A,$5224,$522D,$5237'
               dc    i2'$5240,$524A,$5253,$525D'
               dc    i2'$5266,$5270,$527A,$5283'
               dc    i2'$528D,$5296,$52A0,$52A9'
               dc    i2'$52B3,$52BC,$52C6,$52CF'
               dc    i2'$52D9,$52E3,$52EC,$52F6'
               dc    i2'$52FF,$5309,$5313,$531C'
               dc    i2'$5326,$532F,$5339,$5343'
               dc    i2'$534C,$5356,$535F,$5369'
               dc    i2'$5373,$537C,$5386,$5390'
               dc    i2'$5399,$53A3,$53AD,$53B6'
               dc    i2'$53C0,$53CA,$53D3,$53DD'
               dc    i2'$53E7,$53F0,$53FA,$5404'
               dc    i2'$540E,$5417,$5421,$542B'
               dc    i2'$5434,$543E,$5448,$5452'
               dc    i2'$545B,$5465,$546F,$5479'
               dc    i2'$5482,$548C,$5496,$54A0'
               dc    i2'$54A9,$54B3,$54BD,$54C7'
               dc    i2'$54D1,$54DA,$54E4,$54EE'
               dc    i2'$54F8,$5502,$550C,$5515'
               dc    i2'$551F,$5529,$5533,$553D'
               dc    i2'$5547,$5550,$555A,$5564'
               dc    i2'$556E,$5578,$5582,$558C'
               dc    i2'$5595,$559F,$55A9,$55B3'
               dc    i2'$55BD,$55C7,$55D1,$55DB'
               dc    i2'$55E5,$55EF,$55F9,$5603'
               dc    i2'$560C,$5616,$5620,$562A'
               dc    i2'$5634,$563E,$5648,$5652'
               dc    i2'$565C,$5666,$5670,$567A'
               dc    i2'$5684,$568E,$5698,$56A2'
               dc    i2'$56AC,$56B6,$56C0,$56CA'
               dc    i2'$56D4,$56DE,$56E8,$56F2'
               dc    i2'$56FC,$5706,$5710,$571B'
               dc    i2'$5725,$572F,$5739,$5743'
               dc    i2'$574D,$5757,$5761,$576B'
               dc    i2'$5775,$577F,$5789,$5794'
               dc    i2'$579E,$57A8,$57B2,$57BC'
               dc    i2'$57C6,$57D0,$57DB,$57E5'
               dc    i2'$57EF,$57F9,$5803,$580D'
               dc    i2'$5817,$5822,$582C,$5836'
               dc    i2'$5840,$584A,$5855,$585F'
               dc    i2'$5869,$5873,$587D,$5888'
               dc    i2'$5892,$589C,$58A6,$58B1'
               dc    i2'$58BB,$58C5,$58CF,$58DA'
               dc    i2'$58E4,$58EE,$58F9,$5903'
               dc    i2'$590D,$5917,$5922,$592C'
               dc    i2'$5936,$5941,$594B,$5955'
               dc    i2'$5960,$596A,$5974,$597F'
               dc    i2'$5989,$5993,$599E,$59A8'
               dc    i2'$59B2,$59BD,$59C7,$59D1'
               dc    i2'$59DC,$59E6,$59F1,$59FB'
               dc    i2'$5A05,$5A10,$5A1A,$5A25'
               dc    i2'$5A2F,$5A39,$5A44,$5A4E'
               dc    i2'$5A59,$5A63,$5A6E,$5A78'
               dc    i2'$5A82,$5A8D,$5A97,$5AA2'
               dc    i2'$5AAC,$5AB7,$5AC1,$5ACC'
               dc    i2'$5AD6,$5AE1,$5AEB,$5AF6'
               dc    i2'$5B00,$5B0B,$5B15,$5B20'
               dc    i2'$5B2A,$5B35,$5B3F,$5B4A'
               dc    i2'$5B55,$5B5F,$5B6A,$5B74'
               dc    i2'$5B7F,$5B89,$5B94,$5B9F'
               dc    i2'$5BA9,$5BB4,$5BBE,$5BC9'
               dc    i2'$5BD3,$5BDE,$5BE9,$5BF3'
               dc    i2'$5BFE,$5C09,$5C13,$5C1E'
               dc    i2'$5C29,$5C33,$5C3E,$5C48'
               dc    i2'$5C53,$5C5E,$5C68,$5C73'
               dc    i2'$5C7E,$5C89,$5C93,$5C9E'
               dc    i2'$5CA9,$5CB3,$5CBE,$5CC9'
               dc    i2'$5CD3,$5CDE,$5CE9,$5CF4'
               dc    i2'$5CFE,$5D09,$5D14,$5D1F'
               dc    i2'$5D29,$5D34,$5D3F,$5D4A'
               dc    i2'$5D55,$5D5F,$5D6A,$5D75'
               dc    i2'$5D80,$5D8A,$5D95,$5DA0'
               dc    i2'$5DAB,$5DB6,$5DC1,$5DCB'
               dc    i2'$5DD6,$5DE1,$5DEC,$5DF7'
               dc    i2'$5E02,$5E0D,$5E17,$5E22'
               dc    i2'$5E2D,$5E38,$5E43,$5E4E'
               dc    i2'$5E59,$5E64,$5E6E,$5E79'
               dc    i2'$5E84,$5E8F,$5E9A,$5EA5'
               dc    i2'$5EB0,$5EBB,$5EC6,$5ED1'
               dc    i2'$5EDC,$5EE7,$5EF2,$5EFD'
               dc    i2'$5F08,$5F13,$5F1E,$5F29'
               dc    i2'$5F34,$5F3F,$5F4A,$5F55'
               dc    i2'$5F60,$5F6B,$5F76,$5F81'
               dc    i2'$5F8C,$5F97,$5FA2,$5FAD'
               dc    i2'$5FB8,$5FC3,$5FCE,$5FD9'
               dc    i2'$5FE4,$5FEF,$5FFA,$6006'
               dc    i2'$6011,$601C,$6027,$6032'
               dc    i2'$603D,$6048,$6053,$605E'
               dc    i2'$606A,$6075,$6080,$608B'
               dc    i2'$6096,$60A1,$60AC,$60B8'
L0DEB          dc    i2'$60C3,$60CE,$60D9,$60E4'
               dc    i2'$60F0,$60FB,$6106,$6111'
               dc    i2'$611C,$6128,$6133,$613E'
               dc    i2'$6149,$6155,$6160,$616B'
               dc    i2'$6176,$6182,$618D,$6198'
               dc    i2'$61A3,$61AF,$61BA,$61C5'
               dc    i2'$61D1,$61DC,$61E7,$61F3'
               dc    i2'$61FE,$6209,$6214,$6220'
               dc    i2'$622B,$6236,$6242,$624D'
               dc    i2'$6259,$6264,$626F,$627B'
               dc    i2'$6286,$6291,$629D,$62A8'
               dc    i2'$62B4,$62BF,$62CA,$62D6'
               dc    i2'$62E1,$62ED,$62F8,$6304'
               dc    i2'$630F,$631A,$6326,$6331'
               dc    i2'$633D,$6348,$6354,$635F'
               dc    i2'$636B,$6376,$6382,$638D'
               dc    i2'$6399,$63A4,$63B0,$63BB'
               dc    i2'$63C7,$63D2,$63DE,$63E9'
               dc    i2'$63F5,$6400,$640C,$6418'
               dc    i2'$6423,$642F,$643A,$6446'
               dc    i2'$6451,$645D,$6469,$6474'
               dc    i2'$6480,$648B,$6497,$64A3'
               dc    i2'$64AE,$64BA,$64C6,$64D1'
               dc    i2'$64DD,$64E9,$64F4,$6500'
               dc    i2'$650C,$6517,$6523,$652F'
               dc    i2'$653A,$6546,$6552,$655D'
               dc    i2'$6569,$6575,$6581,$658C'
               dc    i2'$6598,$65A4,$65B0,$65BB'
               dc    i2'$65C7,$65D3,$65DF,$65EA'
               dc    i2'$65F6,$6602,$660E,$6619'
               dc    i2'$6625,$6631,$663D,$6649'
               dc    i2'$6654,$6660,$666C,$6678'
               dc    i2'$6684,$6690,$669C,$66A7'
               dc    i2'$66B3,$66BF,$66CB,$66D7'
               dc    i2'$66E3,$66EF,$66FB,$6706'
               dc    i2'$6712,$671E,$672A,$6736'
               dc    i2'$6742,$674E,$675A,$6766'
               dc    i2'$6772,$677E,$678A,$6796'
               dc    i2'$67A2,$67AE,$67BA,$67C6'
               dc    i2'$67D2,$67DE,$67EA,$67F6'
               dc    i2'$6802,$680E,$681A,$6826'
               dc    i2'$6832,$683E,$684A,$6856'
               dc    i2'$6862,$686E,$687A,$6886'
               dc    i2'$6892,$689E,$68AA,$68B6'
               dc    i2'$68C2,$68CF,$68DB,$68E7'
               dc    i2'$68F3,$68FF,$690B,$6917'
               dc    i2'$6923,$6930,$693C,$6948'
               dc    i2'$6954,$6960,$696C,$6979'
               dc    i2'$6985,$6991,$699D,$69A9'
               dc    i2'$69B6,$69C2,$69CE,$69DA'
               dc    i2'$69E7,$69F3,$69FF,$6A0B'
               dc    i2'$6A18,$6A24,$6A30,$6A3C'
               dc    i2'$6A49,$6A55,$6A61,$6A6D'
               dc    i2'$6A7A,$6A86,$6A92,$6A9F'
               dc    i2'$6AAB,$6AB7,$6AC4,$6AD0'
               dc    i2'$6ADC,$6AE9,$6AF5,$6B01'
               dc    i2'$6B0E,$6B1A,$6B27,$6B33'
               dc    i2'$6B3F,$6B4C,$6B58,$6B64'
               dc    i2'$6B71,$6B7D,$6B8A,$6B96'
               dc    i2'$6BA3,$6BAF,$6BBB,$6BC8'
               dc    i2'$6BD4,$6BE1,$6BED,$6BFA'
               dc    i2'$6C06,$6C13,$6C1F,$6C2C'
               dc    i2'$6C38,$6C45,$6C51,$6C5E'
               dc    i2'$6C6A,$6C77,$6C83,$6C90'
               dc    i2'$6C9C,$6CA9,$6CB5,$6CC2'
L0FF3          dc    i2'$6CCF,$6CDB,$6CE8,$6CF4'
               dc    i2'$6D01,$6D0E,$6D1A,$6D27'
               dc    i2'$6D33,$6D40,$6D4D,$6D59'
               dc    i2'$6D66,$6D73,$6D7F,$6D8C'
               dc    i2'$6D98,$6DA5,$6DB2,$6DBE'
               dc    i2'$6DCB,$6DD8,$6DE5,$6DF1'
               dc    i2'$6DFE,$6E0B,$6E17,$6E24'
               dc    i2'$6E31,$6E3E,$6E4A,$6E57'
               dc    i2'$6E64,$6E71,$6E7D,$6E8A'
               dc    i2'$6E97,$6EA4,$6EB0,$6EBD'
               dc    i2'$6ECA,$6ED7,$6EE4,$6EF0'
               dc    i2'$6EFD,$6F0A,$6F17,$6F24'
               dc    i2'$6F31,$6F3D,$6F4A,$6F57'
               dc    i2'$6F64,$6F71,$6F7E,$6F8B'
L1063          dc    i2'$6F98,$6FA4,$6FB1,$6FBE'
               dc    i2'$6FCB,$6FD8,$6FE5,$6FF2'
               dc    i2'$6FFF,$700C,$7019,$7026'
               dc    i2'$7033,$7040,$704D,$705A'
               dc    i2'$7067,$7074,$7081,$708E'
               dc    i2'$709B,$70A8,$70B5,$70C2'
               dc    i2'$70CF,$70DC,$70E9,$70F6'
               dc    i2'$7103,$7110,$711D,$712A'
               dc    i2'$7137,$7144,$7151,$715E'
               dc    i2'$716B,$7179,$7186,$7193'
               dc    i2'$71A0,$71AD,$71BA,$71C7'
               dc    i2'$71D4,$71E2,$71EF,$71FC'
               dc    i2'$7209,$7216,$7223,$7231'
               dc    i2'$723E,$724B,$7258,$7265'
               dc    i2'$7273,$7280,$728D,$729A'
               dc    i2'$72A8,$72B5,$72C2,$72CF'
               dc    i2'$72DD,$72EA,$72F7,$7304'
L10EB          dc    i2'$7312,$731F,$732C,$733A'
               dc    i2'$7347,$7354,$7362,$736F'
               dc    i2'$737C,$738A,$7397,$73A4'
               dc    i2'$73B2,$73BF,$73CC,$73DA'
               dc    i2'$73E7,$73F5,$7402,$740F'
               dc    i2'$741D,$742A,$7438,$7445'
               dc    i2'$7453,$7460,$746D,$747B'
               dc    i2'$7488,$7496,$74A3,$74B1'
               dc    i2'$74BE,$74CC,$74D9,$74E7'
               dc    i2'$74F4,$7502,$750F,$751D'
               dc    i2'$752A,$7538,$7545,$7553'
               dc    i2'$7561,$756E,$757C,$7589'
               dc    i2'$7597,$75A4,$75B2,$75C0'
               dc    i2'$75CD,$75DB,$75E8,$75F6'
               dc    i2'$7604,$7611,$761F,$762D'
               dc    i2'$763A,$7648,$7656,$7663'
               dc    i2'$7671,$767F,$768C,$769A'
               dc    i2'$76A8,$76B5,$76C3,$76D1'
               dc    i2'$76DF,$76EC,$76FA,$7708'
               dc    i2'$7716,$7723,$7731,$773F'
               dc    i2'$774D,$775A,$7768,$7776'
               dc    i2'$7784,$7792,$779F,$77AD'
               dc    i2'$77BB,$77C9,$77D7,$77E5'
               dc    i2'$77F3,$7800,$780E,$781C'
               dc    i2'$782A,$7838,$7846,$7854'
               dc    i2'$7862,$786F,$787D,$788B'
               dc    i2'$7899,$78A7,$78B5,$78C3'
               dc    i2'$78D1,$78DF,$78ED,$78FB'
               dc    i2'$7909,$7917,$7925,$7933'
               dc    i2'$7941,$794F,$795D,$796B'
               dc    i2'$7979,$7987,$7995,$79A3'
               dc    i2'$79B1,$79BF,$79CD,$79DB'
               dc    i2'$79E9,$79F8,$7A06,$7A14'
               dc    i2'$7A22,$7A30,$7A3E,$7A4C'
               dc    i2'$7A5A,$7A68,$7A77,$7A85'
               dc    i2'$7A93,$7AA1,$7AAF,$7ABD'
               dc    i2'$7ACC,$7ADA,$7AE8,$7AF6'
               dc    i2'$7B04,$7B13,$7B21,$7B2F'
               dc    i2'$7B3D,$7B4C,$7B5A,$7B68'
               dc    i2'$7B76,$7B85,$7B93,$7BA1'
               dc    i2'$7BAF,$7BBE,$7BCC,$7BDA'
               dc    i2'$7BE9,$7BF7,$7C05,$7C14'
               dc    i2'$7C22,$7C30,$7C3F,$7C4D'
               dc    i2'$7C5B,$7C6A,$7C78,$7C86'
               dc    i2'$7C95,$7CA3,$7CB2,$7CC0'
               dc    i2'$7CCE,$7CDD,$7CEB,$7CFA'
               dc    i2'$7D08,$7D17,$7D25,$7D34'
               dc    i2'$7D42,$7D50,$7D5F,$7D6D'
               dc    i2'$7D7C,$7D8A,$7D99,$7DA7'
               dc    i2'$7DB6,$7DC5,$7DD3,$7DE2'
               dc    i2'$7DF0,$7DFF,$7E0D,$7E1C'
               dc    i2'$7E2A,$7E39,$7E48,$7E56'
               dc    i2'$7E65,$7E73,$7E82,$7E91'
               dc    i2'$7E9F,$7EAE,$7EBC,$7ECB'
               dc    i2'$7EDA,$7EE8,$7EF7,$7F06'
L12A3          dc    i2'$7F14,$7F23,$7F32,$7F41'
               dc    i2'$7F4F,$7F5E,$7F6D,$7F7B'
               dc    i2'$7F8A,$7F99,$7FA8,$7FB6'
               dc    i2'$7FC5,$7FD4,$7FE3,$7FF1'
               dc    i2'$8000,$800F,$801E,$802D'
               dc    i2'$803B,$804A,$8059,$8068'
               dc    i2'$8077,$8086,$8094,$80A3'
               dc    i2'$80B2,$80C1,$80D0,$80DF'
L12E3          dc    i2'$80EE,$80FD,$810B,$811A'
               dc    i2'$8129,$8138,$8147,$8156'
L12F3          dc    i2'$8165,$8174,$8183,$8192'
               dc    i2'$81A1,$81B0,$81BF,$81CE'
               dc    i2'$81DD,$81EC,$81FB,$820A'
               dc    i2'$8219,$8228,$8237,$8246'
               dc    i2'$8255,$8264,$8273,$8282'
               dc    i2'$8291,$82A0,$82B0,$82BF'
               dc    i2'$82CE,$82DD,$82EC,$82FB'
               dc    i2'$830A,$8319,$8329,$8338'
               dc    i2'$8347,$8356,$8365,$8374'
               dc    i2'$8384,$8393,$83A2,$83B1'
               dc    i2'$83C0,$83D0,$83DF,$83EE'
L134B          dc    i2'$83FD,$840D,$841C,$842B'
               dc    i2'$843A,$844A,$8459,$8468'
               dc    i2'$8478,$8487,$8496,$84A5'
               dc    i2'$84B5,$84C4,$84D3,$84E3'
               dc    i2'$84F2,$8502,$8511,$8520'
               dc    i2'$8530,$853F,$854E,$855E'
               dc    i2'$856D,$857D,$858C,$859C'
               dc    i2'$85AB,$85BA,$85CA,$85D9'
               dc    i2'$85E9,$85F8,$8608,$8617'
               dc    i2'$8627,$8636,$8646,$8655'
               dc    i2'$8665,$8674,$8684,$8693'
               dc    i2'$86A3,$86B3,$86C2,$86D2'
               dc    i2'$86E1,$86F1,$8700,$8710'
               dc    i2'$8720,$872F,$873F,$874E'
               dc    i2'$875E,$876E,$877D,$878D'
               dc    i2'$879D,$87AC,$87BC,$87CC'
               dc    i2'$87DB,$87EB,$87FB,$880B'
               dc    i2'$881A,$882A,$883A,$8849'
               dc    i2'$8859,$8869,$8879,$8889'
               dc    i2'$8898,$88A8,$88B8,$88C8'
               dc    i2'$88D7,$88E7,$88F7,$8907'
               dc    i2'$8917,$8927,$8936,$8946'
               dc    i2'$8956,$8966,$8976,$8986'
               dc    i2'$8996,$89A6,$89B5,$89C5'
               dc    i2'$89D5,$89E5,$89F5,$8A05'
               dc    i2'$8A15,$8A25,$8A35,$8A45'
               dc    i2'$8A55,$8A65,$8A75,$8A85'
               dc    i2'$8A95,$8AA5,$8AB5,$8AC5'
               dc    i2'$8AD5,$8AE5,$8AF5,$8B05'
               dc    i2'$8B15,$8B25,$8B35,$8B45'
               dc    i2'$8B56,$8B66,$8B76,$8B86'
               dc    i2'$8B96,$8BA6,$8BB6,$8BC6'
               dc    i2'$8BD7,$8BE7,$8BF7,$8C07'
               dc    i2'$8C17,$8C27,$8C38,$8C48'
               dc    i2'$8C58,$8C68,$8C78,$8C89'
               dc    i2'$8C99,$8CA9,$8CB9,$8CCA'
               dc    i2'$8CDA,$8CEA,$8CFB,$8D0B'
               dc    i2'$8D1B,$8D2B,$8D3C,$8D4C'
               dc    i2'$8D5C,$8D6D,$8D7D,$8D8D'
               dc    i2'$8D9E,$8DAE,$8DBF,$8DCF'
               dc    i2'$8DDF,$8DF0,$8E00,$8E10'
               dc    i2'$8E21,$8E31,$8E42,$8E52'
               dc    i2'$8E63,$8E73,$8E84,$8E94'
               dc    i2'$8EA4,$8EB5,$8EC5,$8ED6'
               dc    i2'$8EE6,$8EF7,$8F07,$8F18'
               dc    i2'$8F29,$8F39,$8F4A,$8F5A'
               dc    i2'$8F6B,$8F7B,$8F8C,$8F9D'
               dc    i2'$8FAD,$8FBE,$8FCE,$8FDF'
               dc    i2'$8FF0,$9000,$9011,$9021'
               dc    i2'$9032,$9043,$9053,$9064'
               dc    i2'$9075,$9086,$9096,$90A7'
               dc    i2'$90B8,$90C8,$90D9,$90EA'
               dc    i2'$90FB,$910B,$911C,$912D'
L14F3          dc    i2'$913E,$914E,$915F,$9170'
               dc    i2'$9181,$9192,$91A2,$91B3'
               dc    i2'$91C4,$91D5,$91E6,$91F7'
               dc    i2'$9208,$9218,$9229,$923A'
               dc    i2'$924B,$925C,$926D,$927E'
               dc    i2'$928F,$92A0,$92B1,$92C2'
               dc    i2'$92D3,$92E3,$92F4,$9305'
L152B          dc    i2'$9316,$9327,$9338,$9349'
               dc    i2'$935A,$936B,$937D,$938E'
               dc    i2'$939F,$93B0,$93C1,$93D2'
               dc    i2'$93E3,$93F4,$9405,$9416'
               dc    i2'$9427,$9438,$944A,$945B'
               dc    i2'$946C,$947D,$948E,$949F'
               dc    i2'$94B0,$94C2,$94D3,$94E4'
               dc    i2'$94F5,$9506,$9518,$9529'
               dc    i2'$953A,$954B,$955D,$956E'
               dc    i2'$957F,$9590,$95A2,$95B3'
               dc    i2'$95C4,$95D6,$95E7,$95F8'
               dc    i2'$960A,$961B,$962C,$963E'
               dc    i2'$964F,$9660,$9672,$9683'
               dc    i2'$9694,$96A6,$96B7,$96C9'
               dc    i2'$96DA,$96EC,$96FD,$970E'
               dc    i2'$9720,$9731,$9743,$9754'
               dc    i2'$9766,$9777,$9789,$979A'
               dc    i2'$97AC,$97BD,$97CF,$97E0'
               dc    i2'$97F2,$9804,$9815,$9827'
               dc    i2'$9838,$984A,$985B,$986D'
               dc    i2'$987F,$9890,$98A2,$98B4'
               dc    i2'$98C5,$98D7,$98E9,$98FA'
               dc    i2'$990C,$991E,$992F,$9941'
               dc    i2'$9953,$9964,$9976,$9988'
               dc    i2'$999A,$99AB,$99BD,$99CF'
               dc    i2'$99E1,$99F2,$9A04,$9A16'
               dc    i2'$9A28,$9A3A,$9A4B,$9A5D'
               dc    i2'$9A6F,$9A81,$9A93,$9AA5'
               dc    i2'$9AB6,$9AC8,$9ADA,$9AEC'
               dc    i2'$9AFE,$9B10,$9B22,$9B34'
               dc    i2'$9B46,$9B58,$9B6A,$9B7C'
               dc    i2'$9B8E,$9BA0,$9BB2,$9BC4'
               dc    i2'$9BD6,$9BE8,$9BFA,$9C0C'
               dc    i2'$9C1E,$9C30,$9C42,$9C54'
               dc    i2'$9C66,$9C78,$9C8A,$9C9C'
               dc    i2'$9CAE,$9CC0,$9CD2,$9CE4'
               dc    i2'$9CF7,$9D09,$9D1B,$9D2D'
               dc    i2'$9D3F,$9D51,$9D64,$9D76'
               dc    i2'$9D88,$9D9A,$9DAC,$9DBF'
               dc    i2'$9DD1,$9DE3,$9DF5,$9E08'
               dc    i2'$9E1A,$9E2C,$9E3E,$9E51'
               dc    i2'$9E63,$9E75,$9E88,$9E9A'
               dc    i2'$9EAC,$9EBE,$9ED1,$9EE3'
               dc    i2'$9EF6,$9F08,$9F1A,$9F2D'
               dc    i2'$9F3F,$9F51,$9F64,$9F76'
               dc    i2'$9F89,$9F9B,$9FAE,$9FC0'
               dc    i2'$9FD3,$9FE5,$9FF7,$A00A'
               dc    i2'$A01C,$A02F,$A041,$A054'
               dc    i2'$A066,$A079,$A08C,$A09E'
               dc    i2'$A0B1,$A0C3,$A0D6,$A0E8'
               dc    i2'$A0FB,$A10E,$A120,$A133'
               dc    i2'$A145,$A158,$A16B,$A17D'
               dc    i2'$A190,$A1A3,$A1B5,$A1C8'
               dc    i2'$A1DB,$A1ED,$A200,$A213'
               dc    i2'$A226,$A238,$A24B,$A25E'
               dc    i2'$A271,$A283,$A296,$A2A9'
               dc    i2'$A2BC,$A2CF,$A2E1,$A2F4'
               dc    i2'$A307,$A31A,$A32D,$A340'

	End
*-----------------------------------------------------------------------------*
* T2ForceBkgBlank - EXTERNAL IPC
*  Force [SHR] background blank, when the delay has elapsed.
*  Stop forcing this.
*
* dataIn: bit 0 is significant.  if 0, stop forcing, if 1, start forcing.
* dataOut: reserved
*
* V1.00 - v1.0.1b4 - January 17, 1993 by JRM - Implementation
* v1.1 - t2 1.1f4 - March 24, 1993 by JRM - inc/dec

ipcForceBkgBlank Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2ForceBkgBlank'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	<dataIn
	bit	#1
	beq	stopForcing

	inc	ForceBkgFlag
	rts

stopForcing	anop
	lda	ForceBkgFlag
	beq	alreadyZero
	dec	ForceBkgFlag
alreadyZero	rts

	End
*-----------------------------------------------------------------------------*
