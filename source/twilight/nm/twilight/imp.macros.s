 MACRO
&lab _GetTick
&lab ldx #$2503
 jsl $E10000
 MEND
 MACRO
&LAB LONG &A,&B
 LCLB &I
 LCLB &M
&A AMID &A,1,1
&M SETB ("&A"="M").OR.("&A"="m")
&I SETB ("&A"="I").OR.("&A"="i")
 AIF C:&B=0,.A
&B AMID &B,1,1
&M SETB ("&B"="M").OR.("&B"="m").OR.&M
&I SETB ("&B"="I").OR.("&B"="i").OR.&I
.A
&LAB REP #&M*32+&I*16
 AIF .NOT.&M,.B
 LONGA ON
.B
 AIF .NOT.&I,.C
 LONGI ON
.C
 MEND
 MACRO
&LAB SHORT &A,&B
 LCLB &I
 LCLB &M
&A AMID &A,1,1
&M SETB ("&A"="M").OR.("&A"="m")
&I SETB ("&A"="I").OR.("&A"="i")
 AIF C:&B=0,.A
&B AMID &B,1,1
&M SETB ("&B"="M").OR.("&B"="m").OR.&M
&I SETB ("&B"="I").OR.("&B"="i").OR.&I
.A
&LAB SEP #&M*32+&I*16
 AIF .NOT.&M,.B
 LONGA OFF
.B
 AIF .NOT.&I,.C
 LONGI OFF
.C
 MEND
 MACRO
&lab WordResult
&lab pha
 MEND
 MACRO
&lab LongResult
&lab pha
 pha
 MEND
 MACRO
&lab _LineTo
&lab ldx #$3C04
 jsl $E10000
 MEND
 MACRO
&lab _MoveTo
&lab ldx #$3A04
 jsl $E10000
 MEND
 MACRO
&lab _Random
&lab ldx #$8604
 jsl $E10000
 MEND
 MACRO
&lab _SetSolidPenPat
&lab ldx #$3704
 jsl $E10000
 MEND
 MACRO
&lab pushword &SYSOPR
&lab ANOP
 AIF C:&SYSOPR=0,.b
 LCLC &C
&C AMID "&SYSOPR",1,1
 AIF ("&C"="#").AND.(S:LONGA),.immediate
 lda &SYSOPR
 pha
 MEXIT
.b
 pha
 MEXIT
.immediate
 LCLC &REST
 LCLA &BL
&BL ASEARCH "&SYSOPR"," ",1
 AIF &BL>0,.a
&BL SETA L:&SYSOPR+1
.a
&REST AMID "&SYSOPR",2,&BL-2
 dc I1'$F4',I2'&REST'
 MEND
 MACRO
&lab _ShowPen
&lab ldx #$2804
 jsl $E10000
 MEND
                                                                                                                          � � � � � � � r ^ J 6 " 	]2
Cont_Calc0	STA	]4	;	*
	EOM


Plot1	MAC
	txa
	bmi	]aa
	cmp	#$7d01
	bcs	]aa
	LDAL	$012000-1,X
	HEX	0901F1
	STAL	$012000-1,X
]aa	TXA
	ADC	#$2000-1
	CMP	Old
	BEQ	No_Store
	STA	Old
	cmp	#$9d00+1
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
	ADC	#$2000
	CMP	Old
	BEQ	No_Store
	STA	Old
	cmp	#$9d00
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


BCSL	MAC
	BCC	Here
	BRL	]1
Here	EOM

BCCL	MAC
	BCS	Here
	BRL	]1
Here	EOM

BNEL	MAC
	BEQ	Here
	BRL	]1
Here	EOM

BMIL	MAC
	BPL	Here
	BRL	]1
Here	EOM

bcsl	MAC
	BCC	Here
	BRL	]1
Here	EOM

bccl	MAC
	BCS	Here
	BRL	]1
Here	EOM

bnel	MAC
	BEQ	Here
	BRL	]1
Here	EOM

beql	MAC
	BNE	Here
	BRL	]1
Here	EOM

bmil	MAC
	BPL	Here
	BRL	]1
Here	EOM

*=================================================