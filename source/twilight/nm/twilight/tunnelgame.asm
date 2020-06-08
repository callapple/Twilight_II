#include "types.rez"
#include "t2common.rez"

// --- Flags resource

resource rT2ModuleFlags (moduleFlags) {
	fSetup+fFadeOut+fFadeIn+fGrafPort320, // module flags word
	$01,						// enabled flag (unimplemented)
	$0110,					// minimum T2 version required
	NIL,						// reserved
	"Tunnel Game"					// module name
};

// --- About text resource

resource rTextForLETextBox2 (moduleMessage) {
	TBLeftJust
	TBBackColor TBColorF
	TBForeColor TBColor1
	"Tunnel Game"
	TBForeColor TBColor0
	". Maneuver through the tunnels without hitting the walls.\n"
	TBForeColor TBColor4
	"Written by Nathan Mates, dedicated to Ah-Ram Kim."
};

// --- Version resource

resource rVersion (moduleVersion) {
       {1,0,0,final,2},             // Version
       verUS,                         // US Version
       "T2 Tunnel Game Module",     // program's name
       "By Nathan Mates.\n"
       "Special Thanks to Jim Maricondo."    // copyright notice
};

// --- About icon resource

resource rIcon (moduleIcon) {
		$8000,				// kind
		$0014,				// height
		$0016,				// width
		$"0000000000000000000000"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0F0000D00003000D0000F0"
                $"0F00000D0033300D0000F0"
		$"0F00000D00030000D000F0"
		$"0F00000D00000000D000F0"
		$"0F0000D00000000D0000F0"
		$"0F000D00000000D00000F0"
		$"0F0000D00000000D0000F0"
		$"0F0000D0000000D00000F0"
		$"0F000D00000000D00000F0"
		$"0F0000D0000000D00000F0"
		$"0FFFFFFFFFFFFFFFFAFFF0"
		$"0000000000000000000000"
		$"F0FFFFFFFFFFFFFFFFFF0F"
		$"F0FFFFFFFFFFFFFFFFFF0F"
		$"F0FF4AFFFFFFFFFFFFFF0F"
		$"F0CCCCCCCCCCCCCCCCCC0F"
		$"F0FFFFFFFFFFFFFFFAFF0F"
		$"F00000000000000000000F",

		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"FFFFFFFFFFFFFFFFFFFFFF"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0FFFFFFFFFFFFFFFFFFFF0"
		$"0FFFFFFFFFFFFFFFFFFFF0";

};

resource rControlList (0x00000001) {{
 0x00000001,  /* control resource id */
 0x00000004,  /* control resource id */
 0x00000003,  /* control resource id */
 0x00000002,  /* control resource id */
 0x00000005,  /* control resource id */
 0x00000006,  /* control resource id */
 0x00000007,  /* control resource id */
 0x00000008,  /* control resource id */
 0x00000009,  /* control resource id */
 10,
 11
};
};

resource rControlTemplate (0x00000001) {
 0x00000001,  /* control id */ 
{0x0033,0x005B,0x000,0x000},  /* control rectangle */
      PopUpControl{{   /* control type */
 0x0000,  /* flags */
 0x1002+fDrawPopDownIcon,   /* more flags */
 0,        /* ref con */
 0, /* title width */
 0x00000002, /* menu reference */
 0x012C,  /* inital value */
 0x00000000    /* color table id */
}};
};
resource rMenu (0x00000002) {
0x001E,  /* id of menu */
 RefIsResource*MenuTitleRefShift+RefIsResource*ItemRefShift+fAllowCache,
 0x00000002,  /* id of title string */
 {
 0x0000000A,    /* item reference */
 0x0000000B,    /* item reference */
 0x0000000C,    /* item reference */
};};
resource rPString (0x00000002) { 
"Control: "};
resource rMenuItem (0x0000000A) {
 0x012C, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000A,    /* title reference */
};
resource rPString (0x0000000A) { 
"Joystick"};
resource rMenuItem (0x0000000B) {
 0x012D, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000B,    /* title reference */
};
resource rPString (0x0000000B) { 
"Keyboard"};
resource rMenuItem (0x0000000C) {
 0x012E, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000C,    /* title reference */
};
resource rPString (0x0000000C) { 
"Computer"};


resource rControlTemplate (0x00000002) {
 0x00000002,  /* control id */ 
{0x004B,0x007C,0x005C,0x009C},  /* control rectangle */
    editLineControl{{  /* control type */
 0x0000,  /* flags */
 0x7002,  /* more flags */
 0,        /* ref con */
 0x0001, /* maximum length */
 0x00000003    /* title reference */
}};
};
resource rPString (0x00000003) { 
"J"};

resource rControlTemplate (0x00000003) {
 0x00000003,  /* control id */ 
{0x004B,0x00CC,0x005C,0x00EC},  /* control rectangle */
    editLineControl{{  /* control type */
 0x0000,  /* flags */
 0x7002,  /* more flags */
 0,        /* ref con */
 0x0001, /* maximum length */
 0x00000004    /* title reference */
}};
};
resource rPString (0x00000004) { 
"K"};

resource rControlTemplate (0x00000004) {
 0x00000004,  /* control id */ 
{0x004B,0x0112,0x005C,0x0133},  /* control rectangle */
    editLineControl{{  /* control type */
 0x0000,  /* flags */
 0x7002,  /* more flags */
 0,        /* ref con */
 0x0001, /* maximum length */
 0x00000005    /* title reference */
}};
};
resource rPString (0x00000005) { 
"L"};

resource rControlTemplate (0x00000005) {
 0x00000005,  /* control id */ 
{0x0041,0x007C,0x004D,0x00A6},  /* control rectangle */
    statTextControl{{  /* control type */
 0x0000,  /* flags */
 0x1002,  /* more flags */
 0,        /* ref con */
 0x00000006,   /* text reference */
 0x0004,   /* text length */
 0x0008 /* text justification */
}};
};
resource rTextForLETextBox2 (0x00000006){
 "Left"
};


resource rControlTemplate (0x00000006) {
 0x00000006,  /* control id */ 
{0x0041,0x00CC,0x004D,0x00F4},  /* control rectangle */
    statTextControl{{  /* control type */
 0x0000,  /* flags */
 0x1002,  /* more flags */
 0,        /* ref con */
 0x00000007,   /* text reference */
 0x0004,   /* text length */
 0x0008 /* text justification */
}};
};
resource rTextForLETextBox2 (0x00000007){
 "Stop"
};


resource rControlTemplate (0x00000007) {
 0x00000007,  /* control id */ 
{0x0041,0x0112,0x004D,0x0141},  /* control rectangle */
    statTextControl{{  /* control type */
 0x0000,  /* flags */
 0x1002,  /* more flags */
 0,        /* ref con */
 0x00000008,   /* text reference */
 0x0005,   /* text length */
  0x0008 /* text justification */
}};
};
resource rTextForLETextBox2 (0x00000008){
 "Right"
};


resource rControlTemplate (0x00000008) {
 0x00000008,  /* control id */ 
{0x004B,0x002C,0x0057,0x0059},  /* control rectangle */
    statTextControl{{  /* control type */
 0x0000,  /* flags */
 0x1002,  /* more flags */
 0,        /* ref con */
 0x00000009,   /* text reference */
 0x0005,   /* text length */
 0x0008 /* text justification */
}};
};
resource rTextForLETextBox2 (0x00000009){
 "Keys:"
};


resource rControlTemplate (0x00000009) {
 0x00000009,  /* control id */ 
{0x005F,0x0004,0x007C,0x015C},  /* control rectangle */
    statTextControl{{  /* control type */
 0x0000,  /* flags */
 0x1002,  /* more flags */
 0,        /* ref con */
 0x0000000A,   /* text reference */
 0x0074,   /* text length */
 0x0008 /* text justification */
}};
};
resource rTextForLETextBox2 (0x0000000A){
 "Note: Caps Lock ""Lock"" must be enabled\n"
 "to play this game. Hold down option or\n"
 "open-apple to slow game down to slow speeds."
};

resource rControlTemplate (10) {
		10,			// ID
		{ 25, 84, 48,130},		// rect
		iconButtonControl {{
			$000C,			// flag
			$1020,			// moreFlags
			$00000000,			// refCon
			moduleIcon,		// iconRef
			0,			// titleRef
			0,			// colorTableRef
			$0000			// displayMode
		}};
};

resource rControlTemplate (11) {
		11,			// ID
		{ 32,142, 42,250},		// rect
		statTextControl {{
			$0000,			// flag
			$1002,			// moreFlags
			$00000000,			// refCon
			1			//txtref...
		}};
};

resource rTextForLETextBox2 (1) {
	"Tunnel Game Options"
};
p	#$9d00+1
	bcs	No_Store
	STA	[Ptr_Clear]
	STA	[Ptr_Tsb]
	STA	[Ptr_Tsb2]
	INC	Ptr_Clear
	INC	Ptr_Clear
	INC	Ptr_Clear
	INC	Ptr_Tsb
	INC	Ptr_Tsb
	INC	Ptr_Tsb
	INC	Ptr_Tsb2
	INC	Ptr_Tsb2
	INC	Ptr_Tsb2
No_Store	CLC
	EOM

	EOM
Plot0	MAC
	txa
	bmi	]bb
	cmp	#$7d00
	bcs	]bb
	LDAL	$012000,X
	HEX	091F10
	STAL	$012000,X
]bb	TXA
	ADC	#$20
 dc h'E96221441111EE66EE11114412269E000000'
 dc h'EE221444411EE6006EE114444122EE000000'
 dc h'E9214AF7A41E650056E14A7FA4129E000000'
 dc h'EF214A7FA41E665566E14AF7A412FE000000'
 dc h'E9211444411EE6666EE1144441229E000000'
 dc h'EE6EE2441111EE66EE1111441EE6EE000000'
 dc h'E9656EE211111E66E111112EE6569E000000'
 dc h'EE65056EE22111EE11122EE65056EE000000'
 dc h'E60000005EE21E66E12EE50000006E000000'
 dc h'6000000006EE2E99E2EE6000000006000000'
 dc h'00000000006EE2FF2EE60000000000000000'
 dc h'00000000000062EE26000000000000000000'
 dc h'000000000000056650000000000000000000'
TableLen	equ	*-EvenBytes-2

oddBytes	  anop
 dc h'000000000000665995660000000000000000'
 dc h'00000000056E22E99E22E650000000000000'
 dc h'06000056EE22111EE11122EE650000600000'
 dc h'0E606EE2211111E66E1111122EE606E00000'
 dc h'0E96221441111EE66EE11114412269E00000'
 dc h'0EE2214AA411EE6006EE114AA4122EE00000'
 dc h'0E921447F441E650056E144F744129E00000'
 dc h'0EF2144F7441E665566E1447F4412FE00000'
 dc h'0E92114AA411EE6666EE114AA41229E00000'
 dc h'0EE6EE2441111EE66EE1111441EE6EE00000'
 dc h'0E9656EE211111E66E111112EE6569E00000'
 dc h'0EE65056EE22111EE11122EE65056EE00000'
 dc h'0E60000005EE21E66E12EE50000006E00000'
 dc h'06000000006EE2E99E2EE600000000600000'
 dc h'000000000006EE2FF2EE6000000000000000'
 dc h'000000000000062EE2600000000000000000'
 dc h'000000000000005665000000000000000000'

*
*
Setup	anop
*
* Handle the Setup and all. Entry: Accum=T2Message
*
*
	cmp	#MakeT2
	beq	doMake
	cmp	#HitT2
	jeq	doHit
*	cmp	#KillT2
*	jeq	doKill
	cmp	#SaveT2
	jeq	doSave
	cmp	#LoadSetupT2
	jeq	doLoadSetup
*	cmp	#UnloadSetupT2
*	jeq	doUnloadSetup
	brl	Done

*=================================================
*
*	Create	all	the	buttons	in	the	window
*
doMake	anop

	lda	T2data1+2
	sta	WindPtr+2
	lda	T2data1
	sta	WindPtr
	lda	T2data2
	sta	RezFileID
	WordResult
	_MMStartUp
	PullWord	MyID

	LongResult
	PushLong	WindPtr
	PushWord	#9	;resource 2 resource
	PushLong	#1	;resource item ID=1
	_NewControl2
	plx
	plx		;chuck result out

* Make sure we're dealing with the T2pref file.

	WordResult
	_GetCurResourceFile
	PushWord	RezFileID
	_SetCurResourceFile

	jsr	load_setup

noShapes1	anop
MoveOn	_SetCurResourceFile

	lda	ControlType
	clc
	adc	#299
	pha
	LongResult
	PushLong	WindPtr
	PushLong	#1	;Control Popup
	_GetCtlHandleFromID
	_SetCtlValue

	mov	KeyLeft,StrChar
	PushLong	WindPtr
	PushLong	#2	;itemId
	PushLong	#StrXfer
	_SetLETextByID

	mov	KeyStop,StrChar
	PushLong	WindPtr
	PushLong	#3	;itemId
	PushLong	#StrXfer
	_SetLETextByID

	mov	KeyRight,StrChar
	PushLong	WindPtr
	PushLong	#4	;itunset exit
Set AuxType $4004
Set KeepType $BC
Set A */system/cdevs/twilight
Echo Assembling {1}
if {1} == "Clocks"
  compile Clocks.Rez Keep=Clocks
  delete {a}/Clocks
  copy Clocks {a}
else if {1} == "AClock"
  compile AClock.Rez Keep=AClock
  delete {a}/Aclock
  copy AClock {a}
else if {1} == "SNF"
  compile SNF.Rez Keep=SNF
  delete {a}/SNF
  copy SNF {a}
else if {1} == "Boxes"
  derez Modern.Art -o boxes2.rez 13/rinclude/types.rez */orca/twilight/t2common.rez 
else if {1} == "Tunnel"
  compile TunnelGame.Rez Keep=TunnelGame
  delete {a}/TunnelGame
  copy TunnelGame {a}
else if {1} == "Persp"
  compile Perspective.Rez Keep=Perspective
  delete {a}/Perspective
  copy Perspective {a}
else if {1} == "Fire"
  compile Fireworks.Rez Keep=MiniFireworks
  delete {a}/MiniFireworks
  copy MiniFireworks {a}
else if {1} == "LedMsg"
  compile LedMsg.Rez Keep=Led.Msg
  delete {a}/Led.Msg
  copy Led.Msg {a}
else           
  Echo Known programs:
  Echo "  Aclock - AClock.Asm"
  Echo "  Boxes - Boxes.Asm"
  Echo "  Comedy - Comedian.Asm"
  Echo "  DClock - DClock.Asm"
  Echo "  Fire - Fireworks.Asm"
  Echo "  LedMsg - LedMsg.Asm"
  Echo "  MSlides - MSlides.Asm"
  Echo "  Persp - Perspective.Asm"
  Echo "  Plasma - Plasma.Asm"
  Echo "  SNF - SNF.Asm"
  Echo "  Tunnel - TunnelGame.Asm"
  end
 _GetCtlHandleFromID
&lab ldx #$3010
 jsl $E10000
 MEND
 MACRO
&lab _TEGetText
&lab ldx #$0C22
 jsl $E10000
 MEND
 MACRO
&lab _TECompactRecord
&lab ldx #$2822
 jsl $E10000
 MEND
xxx029.gif _9wwv_9HANGES׀ׂ¸„jP6 ר Ú ¸ ®  b 8 ;itemId
	PushLong	#StrXfer
	_GetLETextByID
	lda	StrChar
	cmp	#$61	;lower case?
	blt	OkStop1
	and	#$5F   
OkStop1	sta	KeyStop

	PushLong	WindPtr
	PushLong	#4	;itemId
	PushLong	#StrXfer
	_GetLETextByID
	lda	StrChar
	cmp	#$61	;lower case?
	blt	OkRight1
	and	#$5F
OkRight1	sta	KeyRight

	WordResult
	LongResult
	PushLong WindPtr
	PushLong	#1	;ControlType Popup
	_GetCtlHandleFromID
	_GetCtlValue
	pla
	sec
	sbc	#299
	sta	ControlType

* Now we're ready to save the data...

            LongResult         
            PushWord	#$1012
	PushLong	#rTunnelPrefs
	_RMLoadNamedResource
	jcc	HaveKeyLeft
	plx
	plx

	LongResult
	PushLong	#8	;8-byte record
	WordResult
	_GetCurResourceApp
	PushWord	#attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	jsr	StorePrefs

	PushLong	temp	;	handle
	PushWord	#attrNoSpec+attrNoCross	;	attr
	PushWord	#$1012	;	rtype
	LongResult
	PushWord	#$FFFF
	PushWord	#$1012
	_UniqueResourceID
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	_AddResource

	PushWord	#$1012	;rType
	PushLong	temp		;rID
	PushLong	#rTunnelPrefs	;ptr to name str
	_RMSetResourceName
	bra	createdFB

HaveKeyLeft anop
	jsr	StorePrefs

	PushWord	#TRUE	;	changeflag:	true
	PushWord	#$1012	;	rtype

	LongResult
	PushWord	#$1012
	PushLong	#rTunnelPrefs
	PushLong	#Temp	;don't care about filenum, but toolbox does
	_RMFindNamedResource	;get it
	_MarkResourceChange

createdFB	anop
            PushWord	RezFileID
	_UpdateResourceFile
	_SetCurResourceFile
	brl	Bye

*=================================================
*	Hit
*
*	handle	item	hits

doHit	anop

	stz	T2Result+2
	stz	T2Result
	lda	T2data2+2	;ctlID hi word must be zero
	bne	nothingHit
	lda	T2data2	;get ctlID
	cmp	#5
	blt	Enable
nothingHit	brl	Bye

enable	lda	#TRUE
	sta	T2Result
	bra	nothingHit

StorePrefs	anop
	PullWord	Temp2
	jsr	makePdp
	lda	KeyLeft
	sta	[3]
	ldy	#2
	lda	KeyStop
	sta	[3],y
	iny
	iny		;now 4
	lda	KeyRight
	sta	[3],y
	iny
	iny		;now 6
	lda	ControlType
	sta	[3],y
	killLdp
	PushWord	Temp2
	rts
Temp2	ds	2


MyID	ds	2
WindPtr	ds	4
RezFileID	ds	2

KeyL₪
     ·                           0 @               BOXES	‹K«;[;כ‡    ¥ֹ נ‚—dd­כ‡´   ×)ÿ כ‡¢   כ) כ‡₪   ) €נ,ג ¯5ְ )׀©ֽ©בכ‡ד       6H«­ְû­ְ0ûֲ ¢‏}  ÊÊשK«ֲ0K«¢("  בHH¢%"  ב¢‡"  ב­כ‡¢   ×) ׀©>ֿ© כ‡¨   ) ׀©ֶ ֿ©b כ‡×   ZH¢†"  בhHֹּ°) Hג ¯4ְ ×)נ4ְ ֲ hhH)€H¢."  בhכHH¢7"  בh¨) ×˜JJJJ בH¢†"  בhHHHH­כ‡¨   H¢"  בhhכ‡   hכHHH­כ‡¨   JH¢"  בhhכ‡’   H¢†"  בhHHHH­כ‡×   H¢"  בhhכ‡”   hכHHH­כ‡×   JH¢"  בhhכ‡–   ­כ‡¢   ׀ ­כ‡”   כ‡˜   mכ‡–   כ‡˜      ­כ‡   כ‡˜      mכ‡’   כ‡˜       כ‡`   ‚׳ :׀8­כ‡”   כ‡˜   mכ‡–   כ‡˜      ©  8םכ‡   כ‡˜      8םכ‡’   כ‡˜       כ‡`   ©  mכ‡   כ‡˜      mכ‡’   כ‡˜       כ‡`   ‚ :׀8­כ‡   כ‡˜      mכ‡’   כ‡˜      ©d 8םכ‡”   כ‡˜      8םכ‡–   כ‡˜    כ‡`   ©d mכ‡”   כ‡˜       mכ‡’   כ‡˜       כ‡`   ‚a ©d 8םכ‡”   כ‡˜      8םכ‡–   כ‡˜   ©  8םכ‡   כ‡˜      8םכ‡’   כ‡˜       כ‡`   ©d mכ‡”   כ‡˜       mכ‡’   כ‡˜       כ‡`   ©  mכ‡   כ‡˜      mכ‡’   כ‡˜       כ‡`   ©d 8םכ‡”   כ‡˜      8םכ‡–   כ‡˜    כ‡`   §
׀‚K‏­כ‡    +תzhhhhhZÚ«kH¢†"  בh-כ‡₪   
:0ס:0נ€ך‹‹פכ‡˜   ¢T"  ב`‹‹פכ‡˜   ¢Y"  ב`ס   #ֹ  נֹ ׀‚Ýֹ ׀‚Vֹ ׀‚ם ‚„ÿ¥כ‡±      ¥
כ‡±   ¥כ‡µ   
H¢"  בhכ‡¯   HH­כ‡±      H­כ‡±   Hפ	 פ  פ ¢1"  בתתH¢"  ב­כ‡µ   	H¢"  ב כ‡¼   ¢"  ב­כ‡´   כ) iHHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  ב­כ‡´   )ÿ i,HHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  ב­כ‡´   
) €**HHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  ב© …‚­‏ס   
Boxes: Prefsס    כ‡¼   	‚”‏HHפפכ‡§  נÿÿÿ פכ‡§   ¢,"  ב
תת©ƒכ‡´   €<;[  ·¨§…„§כ‡´   +hhפ פHHפפכ‡§  נÿÿÿ פכ‡§   פכ‡£  נÿÿÿ פכ‡£   ¢*"  ב¢"  ב`H¢"  ב­כ‡µ   H¢"  בHHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  בh8י,כ‡´   HHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  בh8יכ
כ‡´   כ‡´   HHH­כ‡±      H­כ‡±   Hפ  פ ¢0"  ב¢"  בhנ	­כ‡´   	 €כ‡´   HHפפכ‡§  נÿÿÿ פכ‡§   -¢,"  ב°‚‡ תתHHפ  פ H¢"  בפ ¢	"  ב£כ‡£   £כ‡£      ;[  ·¨§…„­כ‡´   ‡+hh­כ‡£      H­כ‡£   Hפ פHHפÿÿפ¢"  ב£כ‡£   £כ‡£      ¢"  בפ­כ‡£      H­כ‡£   Hפכ‡§  נÿÿÿ פכ‡§   ¢-"  ב€<;[  ·¨§…„­כ‡´   ‡+hhפ פHHפפכ‡§  נÿÿÿ פכ‡§   פכ‡£  נÿÿÿ פכ‡£   ¢*"  ב¢"  ב­כ‡µ   +H¢
"  ב¢"  ב‚÷üdd¥׀¥ֹ ‚¨ü© …€צ  ldx #$2A1E
 jsl $E10000
 MEND
 MACRO
&lab _RMLoadNamedResource
&lab ldx #$2C1E
 jsl $E10000
 MEND
 MACRO
&lab _RMSetResourceName
&lab ldx #$2D1E
 jsl $E10000
 MEND
u üro w üas h ¼ere.HT¨„ü ©t  fע L /©- K  C *LßÿNupxCת‏4 f  ˜@WָÿפUO©”2D n  ¢0<©נ¡F(Hü /<INIT?< © $_ <  ’¥&H0<H"R0ÙQָÿü K0<©נ G K׀ü  K׀ü 0ü B¸¨שNm  Fo space & half on repeat...
	eor	#1
	sta	EvenByte
	beq	HdLeft
 	dec	XPosn
HdLeft	ldx	#0	;hard left
	dc	h'cf'
MedLeft	ldx	#50
	rts
DoKeyStop	ldx	#127
	rts
DoKeyRight	tya		;check repeat flag
	and	#$ff	;only low bits also
	beq	MedRight                        
	lda	EvenByte     ;go space-and-half right
	eor	#1
	sta	EvenByte
	bne	HdRight
	inc	XPosn
HdRight	ldx	#255
	dc	h'cf'
MedRight	ldx	#220
	rts
MsgColor	ds	2
	

	End