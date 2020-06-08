 string
	PushWord #0	;unsigned integer
	_Int2Dec		;and convert to a string
	lda	TempString
	ora	#$2020
	sta	PrintSharks
	lda	TempString+1
	ora	#$2020
	sta	PrintSharks+1
	inc	Time
	PushWord	Time
	PushLlcl #TempString
	PushWord #4	;len of string
	PushWord #0	;unsigned integer
	_Int2Dec		;and convert to a string
	lda	TempString
	ora	#$2020
	sta	PrintTime
	lda	TempString+2
	ora	#$2020
	sta	PrintTime+2
	lda	#TextOut                                
	ldx	#$7800+16	;centered on 192nd line on screen

PrintTxt	dec	a
	sta	Msg
Print0	anop
LoopPrint2	stx	XValue
LoopPrint1	inc	Msg
	lda	|$0000
Msg	equ	*-2
	tay
	and	#$00FF
 	beq 	EndPrint
 	cmp 	#$0C
 	beq 	Change_Color
 	cmp 	#$0D
	beq 	NewLine
 	jsr 	Print_Char
 	bra 	LoopPrint1
Change_Color tya
 	xba
	Short	M
 	sta 	Color
	Long	M
 	inc 	Msg
	bra 	LoopPrint1
NewLine 	lda 	#0
XValue	equ	*-2
 	clc
	adc 	#8*$A0
 	tax
	bra 	LoopPrint2
EndPrint 	rts

Print_Char	sec
 	sbc 	#32
 	asl	a
	asl	a
 	asl	a
 	clc
	adc 	#Font
 	sta 	Font_Adr
	lda 	#8
LoopChar2 	pha
 	phx
	lda 	|$0000
Font_Adr	equ	*-2
	inc 	Font_Adr
 	ldy 	#4
LoopChar 	phy
 	pha
	ldy 	#0
 	bit 	#%00000010
 	beq 	No_Left
 	ldy 	#$0F
No_Left 	bit 	#%00000001
 	beq 	No_Right
 	tya
 	ora 	#$F0
 	tay
No_Right 	tya
	Short	M
 	and 	#$AA
Color	equ	*-1
	sta 	>$E12000,x
 	Long	M
	inx
 	pla
 	lsr	a
 	lsr	a
 	ply
	dey
 	bne 	LoopChar
 	pla
 	clc
	adc 	#$A0
 	tax
 	pla
	dec	a
 	bne	LoopChar2
 	txa
 	sec
 	sbc 	#8*$A0-4
 	tax
 	rts


WipeAllText	ldx	#$4FE
	lda	#0	;kill text at bottom
WipeText	sta	>$E19800,x
	dex
	dex
	bpl	WipeText
	rts

* Police de caracteres...

Font dc h'00000000000000000018181800180000'
 dc h'003636360000000000263E263E260000'
 dc h'003E1E3E383E0000002638181E260000'
 dc h'00182618263800000018181800000000'
 dc h'00380C0C0C380000001C3030301C0000'
 dc h'0026183E182600000018187E18180000'
 dc h'0000000018180C000000007E00000000'
 dc h'0000000018180000006030180C060000'
 dc h'007E6666667E00000018181818180000'
 dc h'007E607E067E0000007E6078607E0000'
 dc h'0066667E60600000007E067E607E0000'
 dc h'007E067E667E0000007E6030180C0000'
 dc h'007E667E667E0000007E667E60600000'
 dc h'00001800180000000000180018180C00'
 dc h'0030180C1830000000003E003E000000'
 dc h'000C1830180C0000003E203800000018'
 dc h'3F3F3F3F3F3F3F3F003C667E66660000'
 dc h'003E663E663E0000007C0606067C0000'
 dc h'003E6666663E0000007E063E067E0000'
 dc h'007E063E06060000007C0606663C0000'
 dc h'0066667E66660000007E1818187E0000'
 dc h'00606060667E00000066361E36660000'
 dc h'00060606067E000000667E7E66660000'
 dc h'00666E7E76660000003C6666663C0000'
 dc h'003E663E06060000003C6666366C0000'
 dc h'003E661E36660000007C063C603E0000'
 dc h'007E18181818000000666666663C0000'
 dc h'006666663C180000006666667E660000'
 dc h'00663C183C6600000066663C18180000'
 dc h'007E6018067E0000001E0606061E0000'
 dc h'0038183E183E0000003C3030303C0000'
 dc h'00183E18181800000018063E00000000'
 dc h'00000000000000000000000000000000'

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
*	cmp	#UnloadSetupT