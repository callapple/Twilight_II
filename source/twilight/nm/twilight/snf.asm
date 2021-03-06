	Starve

	WordResult
	LongResult
	PushLong WindPtr
	PushLong	#6	;Prefs Popup
	_GetCtlHandleFromID
	_GetCtlValue
	pla
	sta	Prefs


* Now we're ready to save the data...

            LongResult         
            PushWord	#$1012
	PushLong	#rSNFStuff
	_RMLoadNamedResource
	jcc	HaveFishBreed
	plx
	plx

	LongResult
	PushLong	#12
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
	PushLong	#rSNFStuff	;ptr to name str
	_RMSetResourceName
	bra	createdFB

HaveFishBreed anop
	jsr	StorePrefs

	PushWord	#TRUE	;	changeflag:	true
	PushWord	#$1012	;	rtype

	LongResult
	PushWord	#$1012
	PushLong	#rSNFStuff
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
	cmp	#7
	blt	Enable
nothingHit	brl	Bye

enable	lda	#TRUE
	sta	T2Result
	bra	nothingHit
MyID	ds	2
WindPtr	ds	4
RezFileID	ds	2

StorePrefs	anop
	PullWord	Temp2
	jsr	makePdp
	lda	FishBreed
	sta	[3]
	ldy	#2
	lda	StNumFish
	sta	[3],y
	iny
	iny		;now 4
	lda	StNumSharks
	sta	[3],y
	iny
	iny		;now 6
	lda	SharkBreed
	sta	[3],y
	iny
	iny		;now 8
	lda	Starve
	sta	[3],y
	iny
	iny		;now 10
	lda	Prefs
	sta	[3],y
	killLdp
	PushWord	Temp2
	rts
Temp2	ds	2

makePdp     anop
TheHandle   equ   3

	plx                      ; yank return address
            phd
            tsc
            tcd
            ldy   #2
            lda   [TheHandle],y
            tay
            lda   [TheHandle]
            sta   <TheHandle
            sty   <TheHandle+2
            phx                      ; push back return address
            rts
	end
WATER1.PALCE      ��   � W
WATER2.PALCE      ��   � YYAAA.ACECEBr �     ��   � YREAD.MEPALCE      ��   � F!Tetrotr.ixC      ��          �!MYHSCNA.ME  �	MYHSCNAME   �!TETRODO.CUS   �TETRO.DOC.USj   �!Tetrotr.ix  �	Tetrotrix   �myhsc  �myhsc   �NIVO.St  �NIVO.S 
   �PHANT.S  �PHANT.S        ����nH( � � � � � h J , 	bmi	AnRts	;shark
	lda	NumFood
	phx		;save on stack
	asl	a
	tax		;place in field
	tya
	sta	FoodYPlaces,x
	pla
	sta	FoodXPlaces,x
	tax
	inc	NumFood
	rts
EmptySpace	lda	NumMoves
	phx		;save on stack
	asl	a
	tax		;place in field
	tya
	sta	FreeYPlaces,x
	pla
	sta	FreeXPlaces,x
	tax
	inc	NumMoves
AnRts	rts

SharkData	ds	2

DoShark	anop
	phx
	phy		;for safety
	sta	SharkData
	xba
	and	#$7F	;time until starve
	inc	a
	cmp	Starve	;dead?
	blt	NotDeadShark
	dec	NumSharks
	ply
	plx
	lda	#0
	jsr	DrawIt
	brl	PutInFieldC
	
NotDeadShark anop
	xba		;new starve value
	pha		;new value
            lda	SharkData
	and	#$80FF	;clear starve bits
	ora	1,s	;or-in starve value
	ora	#$8000	;force shark bits
	sta	SharkData
	jsr	PutInFieldC	;and save in field
	pla		;clean up stack
	jsr	EvalAround
	ldx	NumFood
	beq	NormalMove
	lda	SharkData
	and	#$80FF	;clear hungry bits
	sta	SharkData
	jsr	PutInFieldC
	dec	NumFish	;keep stats right
	jsr	RandomX
	asl	a
	tax		;offset in Table
	lda	FoodYPlaces,x
	tay
	lda	FoodXPlaces,x
	tax
	bra	NewSharkPos

#include "types.rez"
#include "t2common.rez"

// --- Flags resource

resource rT2ModuleFlags (moduleFlags) {
	fFadeOut+fFadeIn+fGrafPort320+fLeavesUsableScreen+fSetup,
        	$01,						// enabled flag (unimplemented)
        	$0110,					// minimum T2 version required
	NIL,						// reserved
	"Sharks And Fish"			// module name
};

// --- About text resource

resource rTextForLETextBox2 (moduleMessage) {
	TBLeftJust
	TBBackColor TBColorF
	TBForeColor TBColor1
	"Sharks And Fish"
	TBForeColor TBColor0
	" is a population dynamics simulation.\n"
	TBForeColor TBColor4
	"For more information, see Computer Recreations, "
        TBStyleItalic
        "Scientific American"
        TBStylePlain
        ", December 1984."
};

// --- Version resource

resource rVersion (moduleVersion) {
       {1,0,0,final,2},             // Version
       verUS,                         // US Version
       "T2 Sharks And Fish Module",     // program's name
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
		$"0F111111111111111111F0"
		$"0F111111111111311111F0"
		$"0F111111113111331111F0"
		$"0F111111111333333311F0"
		$"0F111111111333333331F0"
		$"0F111111113111111111F0"
		$"0F111111111111111111F0"
		$"0F111331311111331311F0"
		$"0F113113111113113111F0"
		$"0F111331311111331311F0"
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
 0x00000002,  /* control resource id */
 0x00000003,  /* control resource id */
 0x00000004,  /* control resource id */
 0x00000005,  /* control resource id */
 0x00000006,  /* control resource id */
 0x00000007,  /* control resource id */
 0x00000008,  /* control resource id */
 0x00000009,  /* control resource id */
 10,
 11,
};
};

resource rControlTemplate (0x00000001) {
 0x00000001,  /* control id */ 
{0x002D,0x0060,0x0000,0x000},  /* control rectangle */
      PopUpControl{{   /* control type */
 0x0000,  /* flags */
 0x1002+fDrawPopDownIcon,   /* more flags */
 0,        /* ref con */
 0, /* title width */
 0x00000002, /* menu reference */
 0x0000,  /* inital value */
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
 0x0000000D,    /* item reference */
 0x0000000E,    /* item reference */
 0x0000000F,    /* item reference */
 0x00000010,    /* item reference */
 0x00000011,    /* item reference */
 0x00000012,    /* item reference */
 0x00000013,    /* item reference */
 0x00000014,    /* item reference */
 0x00000015,    /* item reference */
 0x00000016,    /* item reference */
 0x00000017,    /* item reference */
 0x00000018,    /* item reference */
 0x00000019,    /* item reference */
 0x0000001A,    /* item reference */
 0x0000001B,    /* item reference */
 0x0000001C,    /* item reference */
 0x0000001D,    /* item reference */
 0x0000001E,    /* item reference */
 0x0000001F,    /* item reference */
 0x00000020,    /* item reference */
 0x00000021,    /* item reference */
 0x00000022,    /* item reference */
};};
resource rPString (0x00000002) { 
"Initial Number: "};
resource rMenuItem (0x0000000A) {
 0x012C, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000A,    /* title reference */
};
resource rPString (0x0000000A) { 
"20"};
resource rMenuItem (0x0000000B) {
 0x012D, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000B,    /* title reference */
};
resource rPString (0x0000000B) { 
"40"};
resource rMenuItem (0x0000000C) {
 0x012E, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000C,    /* title reference */
};
resource rPString (0x0000000C) { 
"60"};
resource rMenuItem (0x0000000D) {
 0x012F, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000D,    /* title reference */
};
resource rPString (0x0000000D) { 
"80"};
resource rMenuItem (0x0000000E) {
 0x0130, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000E,    /* title reference */
};
resource rPString (0x0000000E) { 
"100"};
resource rMenuItem (0x0000000F) {
 0x0131, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000000F,    /* title reference */
};
resource rPString (0x0000000F) { 
"120"};
resource rMenuItem (0x00000010) {
 0x0132, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000010,    /* title reference */
};
resource rPString (0x00000010) { 
"140"};
resource rMenuItem (0x00000011) {
 0x0133, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000011,    /* title reference */
};
resource rPString (0x00000011) { 
"160"};
resource rMenuItem (0x00000012) {
 0x0134, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000012,    /* title reference */
};
resource rPString (0x00000012) { 
"180"};
resource rMenuItem (0x00000013) {
 0x0135, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000013,    /* title reference */
};
resource rPString (0x00000013) { 
"200"};
resource rMenuItem (0x00000014) {
 0x0136, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000014,    /* title reference */
};
resource rPString (0x00000014) { 
"220"};
resource rMenuItem (0x00000015) {
 0x0137, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000015,    /* title reference */
};
resource rPString (0x00000015) { 
"240"};
resource rMenuItem (0x00000016) {
 0x0138, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000016,    /* title reference */
};
resource rPString (0x00000016) { 
"260"};
resource rMenuItem (0x00000017) {
 0x0139, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000017,    /* title reference */
};
resource rPString (0x00000017) { 
"280"};
resource rMenuItem (0x00000018) {
 0x013A, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000018,    /* title reference */
};
resource rPString (0x00000018) { 
"300"};
resource rMenuItem (0x00000019) {
 0x013B, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000019,    /* title reference */
};
resource rPString (0x00000019) { 
"320"};
resource rMenuItem (0x0000001A) {
 0x013C, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001A,    /* title reference */
};
resource rPString (0x0000001A) { 
"340"};
resource rMenuItem (0x0000001B) {
 0x013D, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001B,    /* title reference */
};
resource rPString (0x0000001B) { 
"360"};
resource rMenuItem (0x0000001C) {
 0x013E, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001C,    /* title reference */
};
resource rPString (0x0000001C) { 
"380"};
resource rMenuItem (0x0000001D) {
 0x013F, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001D,    /* title reference */
};
resource rPString (0x0000001D) { 
"400"};
resource rMenuItem (0x0000001E) {
 0x0140, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001E,    /* title reference */
};
resource rPString (0x0000001E) { 
"420"};
resource rMenuItem (0x0000001F) {
 0x0141, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000001F,    /* title reference */
};
resource rPString (0x0000001F) { 
"440"};
resource rMenuItem (0x00000020) {
 0x0142, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000020,    /* title reference */
};
resource rPString (0x00000020) { 
"460"};
resource rMenuItem (0x00000021) {
 0x0143, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000021,    /* title reference */
};
resource rPString (0x00000021) { 
"480"};
resource rMenuItem (0x00000022) {
 0x0144, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000022,    /* title reference */
};
resource rPString (0x00000022) { 
"500"};


resource rControlTemplate (0x00000002) {
 0x00000002,  /* control id */ 
{0x003B,0x0060,0x0000,0x0000},  /* control rectangle */
      PopUpControl{{   /* control type */
 0x0000,  /* flags */
 0x1002+fDrawPopDownIcon,   /* more flags */
 0,        /* ref con */
 0, /* title width */
 0x00000003, /* menu reference */
 0x012C,  /* inital value */
 0x00000000    /* color table id */
}};
};
resource rMenu (0x00000003) {
0x0020,  /* id of menu */
 RefIsResource*MenuTitleRefShift+RefIsResource*ItemRefShift+fAllowCache,
 0x00000003,  /* id of title string */
 {
 0x00000023,    /* item reference */
 0x00000024,    /* item reference */
 0x00000025,    /* item reference */
 0x00000026,    /* item reference */
 0x00000027,    /* item reference */
 0x00000028,    /* item reference */
 0x00000029,    /* item reference */
 0x0000002A,    /* item reference */
 0x0000002B,    /* item reference */
 0x0000002C,    /* item reference */
 0x0000002D,    /* item reference */
 0x0000002E,    /* item reference */
 0x0000002F,    /* item reference */
 0x00000030,    /* item reference */
 0x00000031,    /* item reference */
};};
resource rPString (0x00000003) { 
"Breeding Time: "};
resource rMenuItem (0x00000023) {
 0x012C, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000023,    /* title reference */
};
resource rPString (0x00000023) { 
"1"};
resource rMenuItem (0x00000024) {
 0x012D, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000024,    /* title reference */
};
resource rPString (0x00000024) { 
"2"};
resource rMenuItem (0x00000025) {
 0x012E, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000025,    /* title reference */
};
resource rPString (0x00000025) { 
"3"};
resource rMenuItem (0x00000026) {
 0x012F, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000026,    /* title reference */
};
resource rPString (0x00000026) { 
"4"};
resource rMenuItem (0x00000027) {
 0x0130, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000027,    /* title reference */
};
resource rPString (0x00000027) { 
"5"};
resource rMenuItem (0x00000028) {
 0x0131, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000028,    /* title reference */
};
resource rPString (0x00000028) { 
"6"};
resource rMenuItem (0x00000029) {
 0x0132, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000029,    /* title reference */
};
resource rPString (0x00000029) { 
"7"};
resource rMenuItem (0x0000002A) {
 0x0133, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002A,    /* title reference */
};
resource rPString (0x0000002A) { 
"8"};
resource rMenuItem (0x0000002B) {
 0x0134, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002B,    /* title reference */
};
resource rPString (0x0000002B) { 
"9"};
resource rMenuItem (0x0000002C) {
 0x0135, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002C,    /* title reference */
};
resource rPString (0x0000002C) { 
"10"};
resource rMenuItem (0x0000002D) {
 0x0136, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002D,    /* title reference */
};
resource rPString (0x0000002D) { 
"11"};
resource rMenuItem (0x0000002E) {
 0x0137, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002E,    /* title reference */
};
resource rPString (0x0000002E) { 
"12"};
resource rMenuItem (0x0000002F) {
 0x0138, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000002F,    /* title reference */
};
resource rPString (0x0000002F) { 
"13"};
resource rMenuItem (0x00000030) {
 0x0139, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000030,    /* title reference */
};
resource rPString (0x00000030) { 
"14"};
resource rMenuItem (0x00000031) {
 0x013A, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000031,    /* title reference */
};
resource rPString (0x00000031) { 
"15"};


resource rControlTemplate (0x00000003) {
 0x00000003,  /* control id */ 
{0x0049,0x0060,0x0000,0x0000},  /* control rectangle */
      PopUpControl{{   /* control type */
 0x0000,  /* flags */
 0x1002+fDrawPopDownIcon,   /* more flags */
 0,        /* ref con */
 0, /* title width */
 0x00000004, /* menu reference */
 0x012C,  /* inital value */
 0x00000000    /* color table id */
}};
};
resource rMenu (0x00000004) {
0x0022,  /* id of menu */
 RefIsResource*MenuTitleRefShift+RefIsResource*ItemRefShift+fAllowCache,
 0x00000004,  /* id of title string */
 {
 0x00000032,    /* item reference */
 0x00000033,    /* item reference */
 0x00000034,    /* item reference */
 0x00000035,    /* item reference */
 0x00000036,    /* item reference */
 0x00000037,    /* item reference */
 0x00000038,    /* item reference */
 0x00000039,    /* item reference */
 0x0000003A,    /* item reference */
 0x0000003B,    /* item reference */
 0x0000003C,    /* item reference */
 0x0000003D,    /* item reference */
 0x0000003E,    /* item reference */
 0x0000003F,    /* item reference */
 0x00000040,    /* item reference */
};};
resource rPString (0x00000004) { 
"Initial Number: "};
resource rMenuItem (0x00000032) {
 0x012C, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000032,    /* title reference */
};
resource rPString (0x00000032) { 
"10"};
resource rMenuItem (0x00000033) {
 0x012D, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000033,    /* title reference */
};
resource rPString (0x00000033) { 
"20"};
resource rMenuItem (0x00000034) {
 0x012E, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000034,    /* title reference */
};
resource rPString (0x00000034) { 
"30"};
resource rMenuItem (0x00000035) {
 0x012F, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000035,    /* title reference */
};
resource rPString (0x00000035) { 
"40"};
resource rMenuItem (0x00000036) {
 0x0130, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000036,    /* title reference */
};
resource rPString (0x00000036) { 
"50"};
resource rMenuItem (0x00000037) {
 0x0131, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000037,    /* title reference */
};
resource rPString (0x00000037) { 
"60"};
resource rMenuItem (0x00000038) {
 0x0132, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000038,    /* title reference */
};
resource rPString (0x00000038) { 
"70"};
resource rMenuItem (0x00000039) {
 0x0133, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000039,    /* title reference */
};
resource rPString (0x00000039) { 
"80"};
resource rMenuItem (0x0000003A) {
 0x0134, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003A,    /* title reference */
};
resource rPString (0x0000003A) { 
"90"};
resource rMenuItem (0x0000003B) {
 0x0135, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003B,    /* title reference */
};
resource rPString (0x0000003B) { 
"100"};
resource rMenuItem (0x0000003C) {
 0x0136, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003C,    /* title reference */
};
resource rPString (0x0000003C) { 
"110"};
resource rMenuItem (0x0000003D) {
 0x0137, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003D,    /* title reference */
};
resource rPString (0x0000003D) { 
"120"};
resource rMenuItem (0x0000003E) {
 0x0138, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003E,    /* title reference */
};
resource rPString (0x0000003E) { 
"130"};
resource rMenuItem (0x0000003F) {
 0x0139, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x0000003F,    /* title reference */
};
resource rPString (0x0000003F) { 
"140"};
resource rMenuItem (0x00000040) {
 0x013A, /* item id number */
 "","",       /* hot key*/
 0,       /* check character */
 RefIsResource*ItemTitleRefShift+fXOR,
 0x00000040,    /* title reference */
};
resource rPString (0x00000040) { 
"150"};


resource rControlTemplate (0x00000004) {
 0x00000004,  /* contro