
*=================================================
*	Macros

add	MAC
	LDA	]1
	CLC
	ADC	]2
	BPL	Positive
	CLC
	ADC	#512
	BRA	Cont_Add
Positive	CMP	#512
	BCC	Cont_Add
	SEC
	SBC	#512
Cont_Add	STA	]1
	EOM

TABLE_SPECIAL	MAC
	MX	%00
	LDA	]1	;	Pas	Elementaire
	LSR
	LDX	Perspective
	BNE	Div2_Only
*	LSR
	LSR	;	Divise	par	2
;	pour	recuperer	un	bit	de	precision
Div2_Only	LDX	]2	;	Signe	Pas	elementaire
	BEQ	No_Inversaga
	EOR	#$FFFF
	INC
No_Inversaga	=	*
	STA	Buf_VAL	;	Valeur
	LDA	]4
	ASL
	CLC
	ADC	#]3
	STA	Patch0
	LDA	]4
	ASL
	STA	Patch2
	LDX	#0
	LDA	#0
]lp	STA	!$0000,X
Patch0	=	*-2
	CLC
	ADC	Buf_VAL
	CPX	#0
Patch2	=	*-2
	BEQ	Patch1
	INX
	INX
	BRA	]lp
Patch1	DEX
	DEX
	BMI	Here	;	Cas	ou	la	dim	=	0
	LDA	#0
]lp	SEC
	SBC	Buf_VAL
	STA	]3,X
	DEX
	DEX
	BPL	]lp
Here	EOM

TABLE	MAC
	MX	%00
	LDA	]1	;	Pas	Elementaire
	LSR	;	Divise	par	2
;	pour	recuperer	un	bit	de	precision
	LDX	]2	;	Signe	Pas	elementaire
	BEQ	No_Inversaga
	EOR	#$FFFF
	INC
No_Inversaga	=	*
	STA	Buf_VAL	;	Valeur
	LDA	]4
	ASL
	CLC
	ADC	#]3
	STA	Patch0
	LDA	]4
	ASL
	STA	Patch2
	LDX	#0
	LDA	#0
]lp	STA	!$0000,X
Patch0	=	*-2
	CLC
	ADC	Buf_VAL
	CPX	#0
Patch2	=	*-2
	BEQ	Patch1
	INX
	INX
	BRA	]lp
Patch1	DEX
	DEX
	BMI	Here	;	Cas	ou	la	dim	=	0
	LDA	#0
]lp	SEC
	SBC	Buf_VAL
	STA	]3,X
	DEX
	DEX
	BPL	]lp
Here	EOM

Add	MAC
	CPY	]1
	BEQ	Same_Signe0
	SEC
	SBC	]2
	DEY
	BEQ	First_Negatif0
	BCC	Inverse_Value0
	BRA	Cont_Calc0
Inverse_Value0	EOR	#$FFFF
	INC
	INC	]3
	BRA	Cont_Calc0
First_Negatif0	BCS	Cont_Calc0
	EOR	#$FFFF
	INC	;	Change	le	signe
	STZ	]3
	BRA	Cont_Calc0
Same_Signe0	CLC
	ADC	]2
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
	INC	Ptr