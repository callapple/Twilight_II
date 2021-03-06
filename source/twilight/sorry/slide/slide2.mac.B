 MACRO
&lab _HideCursor
&lab ldx #$9004
 jsl $E10000
 MEND
 MACRO
&LAB JCS &BP
&LAB BCC *+5
 BRL &BP
 MEND
 MACRO
&lab pushlong &addr,&offset
&lab ANOP
 LCLC &C
 LCLC &REST
&C AMID &addr,1,1
 AIF "&C"="#",.immediate
 AIF "&C"="[",.zeropage
 AIF C:&offset=0,.nooffset
 AIF "&offset"="s",.stack
 pushword &addr+2,&offset
 pushword &addr,&offset
 MEXIT
.nooffset
 pushword &addr+2
 pushword &addr
 MEXIT
.immediate
&REST AMID &addr,2,L:&addr-1
 dc I1'$F4',I2'(&REST)|-16'
 dc I1'$F4',I2'&REST'
 MEXIT
.stack
 pushword &addr+2,s
 pushword &addr+2,s
 MEXIT
.zeropage
 ldy #&offset+2
 pushword &addr,y
 ldy #&offset
 pushword &addr,y
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
&lab longm
&lab ANOP
 rep #%00100000
 longa on
 MEND
 MACRO
&lab shortm
&lab ANOP
 sep #%00100000
 longa off
 MEND
 MACRO
&lab wordresult
&lab phd
 MEND
 MACRO
&lab longresult
&lab phd
 phd
 MEND
 MACRO
&lab _NewHandle
&lab ldx #$0902
 jsl $E10000
 MEND
 MACRO
&lab _DisposeAll
&lab ldx #$1102
 jsl $E10000
 MEND
 MACRO
&lab _UnPackBytes
&lab ldx #$2703
 jsl $E10000
 MEND
 MACRO
&lab _CloseGS &params
&lab jsl $E100A8
 dc i2"$2014"
 dc i4"&params"
 MEND
 MACRO
&lab _OpenGS &params
&lab jsl $E100A8
 dc i2"$2010"
 dc i4"&params"
 MEND
 MACRO
&lab _ReadGS &params
&lab jsl $E100A8
 dc i2"$2012"
 dc i4"&params"
 MEND
 MACRO
&lab GSStr &GSstring
&lab dc i2'L:&GSstring',C'&GSstring'
 MEND
 MACRO
&lab _Int2Hex
&lab ldx #$220B
 jsl $E10000
 MEND
 MACRO
&lab _WriteCString
&lab ldx #$200C
 jsl $E10000
 MEND
 MACRO
&lab _DisposeHandle
&lab ldx #$1002
 jsl $E10000
 MEND
 MACRO
&lab _GetDirEntryGS &params
&lab jsl $E100A8
 dc i2"$201C"
 dc i4"&params"
 MEND
 MACRO
&LAB JCC &BP
&LAB BCS *+5
 BRL &BP
 MEND
 MACRO
&LAB JNE &BP
&LAB BEQ *+5
 BRL &BP
 MEND
 MACRO
&lab _Multiply
&lab ldx #$090B
 jsl $E10000
 MEND
 MACRO
 DefineStack
 GBLA &DummyPC
&DummyPC SETA 1
 MEND
 MACRO
&lab BYTE
&lab equ &DummyPC
&DummyPC SETA &DummyPC+1
 MEND
 MACRO
&lab LONG
&lab equ &DummyPC
&DummyPC SETA &DummyPC+4
 MEND
 MACRO
&lab BLOCK &Value
 AIF C:&lab=0,.skiplab
&lab equ &DummyPC
.skiplab
&DummyPC SETA &DummyPC+&Value
 MEND
 MACRO
&lab _InitCursor
&lab ldx #$CA04
 jsl $E10000
 MEND
