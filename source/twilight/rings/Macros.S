_BLOCKMOVE MAC 
 Tool $2B02 
 <<< 
^DISPOSEALL MAC 
 PHW ]1 
 Tool $1102 
 <<< 
PEIL MAC 
 PEI ]1+2 
 PEI ]1 
 <<< 
QUIT_GS MAC 
 GSOS $2029;]1 
 <<< 
_STARTCYCLETIMING mac 
 pea 0 
 pea 0 
 pea 0 
 jsl StartCycleTiming 
 eom 
_CALCCYCLETIME mac 
 pea #^]1 
 pea #]1 
 jsl CalcCycleTime 
 eom 
_STARTREALTIMING mac 
 pea 0 
 pea 0 
 pea 0 
 jsl StartRealTiming 
 eom 
_CALCREALTIME mac 
 pea #^]1 
 pea #]1 
 jsl CalcRealTime 
 eom 
^BLOCKMOVE MAC 
 PxL ]1;]2;]3 
 Tool $2B02 
 <<< 
PXL MAC 
 DO ]0/1 
 PHL ]1 
 DO ]0/2 
 PHL ]2 
 DO ]0/3 
 PHL ]3 
 DO ]0/4 
 PHL ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
BNEL MAC 
 BEQ OV 
 BRL ]1 
OV <<< 
^HEXIT MAC 
 P2SW ]1 
 Tool $2A0B 
 <<< 
P2SW MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
printhex MAC ;format: printhex 'value:';value
 ~HexIt ]2
 pll Hascii
 printblock #HText
 bra x
HText asc ]1
HAscii asc '0000',00
x <<<
_INT2DEC MAC 
 Tool $260B 
 <<< 
_STARTTIMING mac 
 pea 0 
 pea 0 
 pea 0 
 jsl StartTiming 
 eom 
_CALCTIME mac 
 pea #^]1 
 pea #]1 
 jsl CalcTime 
 eom 
_DISPOSEHANDLE MAC 
 Tool $1002 
 <<< 
_TOTALMEM MAC 
 Tool $1D02 
 <<< 
CLOSE_GS MAC 
 GSOS $2014;]1 
 <<< 
OPEN_GS MAC 
 GSOS $2010;]1 
 <<< 
READ_GS MAC 
 GSOS $2012;]1 
 <<< 
GSOS MAC 
 jsl $E100A8 
 da ]1 
 adrl ]2 
 <<< 
_READTIMEHEX MAC 
 Tool $D03 
 <<< 
_TICKCOUNT MAC 
 Tool $1006 
 <<< 
_DISPOSEALL MAC 
 Tool $1102 
 <<< 
_SETHANDLESIZE MAC 
 Tool $1902 
 <<< 
_FINDHANDLE MAC 
 Tool $1A02 
 <<< 
_HLOCK MAC 
 Tool $2002 
 <<< 
BCCL MAC
 BCS OV
 BRL ]1
OV <<<
BLTL MAC 
 BGE OV 
 BRL ]1 
OV <<< 
SUB MAC 
 IF #=]2 
 IF #=]1 
 ERR 1 
 FIN 
 FIN 
 SEC 
 LDA ]1 
 SBC ]2 
 DO ]0/3 
 STA ]3 
 ELSE 
 IF #=]2 
 STA ]1 
 ELSE 
 STA ]2 
 FIN 
 FIN 
 IF MX>1 
 LDHI ]1 
 IF #=]2 
 SBC ]2/$100 
 ELSE 
 SBC ]2+1 
 FIN 
 DO ]0/3 
 STA ]3+1 
 ELSE 
 IF #=]2 
 STA ]1+1 
 ELSE 
 STA ]2+1 
 FIN 
 FIN 
 FIN 
 <<< 
LDHI MAC 
 IF #=]1 
 LDA ]1/$100 
 ELSE 
 LDA ]1+1 
 FIN 
 <<< 
^DISPOSEHANDLE MAC 
 PHL ]1 
 Tool $1002 
 <<< 
_UNPACKBYTES MAC 
 Tool $2703 
 <<<
_HEXIT MAC 
 Tool $2A0B 
 <<< 
_TEXTSTARTUP MAC 
 Tool $20C 
 <<< 
_TEXTSHUTDOWN MAC 
 Tool $30C 
 <<< 
^WRITECSTRING MAC 
 PHL ]1 
 Tool $200C 
 <<< 
ADD MAC 
 IF #=]2 
 IF #=]1 
 ERR 1 
 FIN 
 FIN 
 CLC 
 LDA ]1 
 ADC ]2 
 DO ]0/3 
 STA ]3 
 ELSE 
 IF #=]2 
 STA ]1 
 ELSE 
 STA ]2 
 FIN 
 FIN 
 IF MX>1 
 LDA ]1+1 
 IF #=]2 
 ADC ]2/$100 
 ELSE 
 ADC ]2+1 
 FIN 
 DO ]0/3 
 STA ]3+1 
 ELSE 
 IF #=]2 
 STA ]1+1 
 ELSE 
 STA ]2+1 
 FIN 
 FIN 
 FIN 
 <<< 
BCSL MAC
 BCC OV 
 BRL ]1 
OV <<< 
ADD4 MAC 
 CLC 
 DO ]0/3 
 IF #=]1 
 LDA #<]1 
 ELSE 
 LDA ]1 
 FIN 
 IF #=]2 
 ADC #<]2 
 ELSE 
 ADC ]2 
 FIN 
 STA ]3 
 IF #=]1 
 LDA #^]1 
 ELSE 
 LDA ]1+2 
 FIN 
 IF #=]2 
 ADC #^]2 
 ELSE 
 ADC ]2+2 
 FIN 
 STA ]3+2 
 ELSE 
 IF #=]1 
 ADC #<]1 
 ELSE 
 ADC ]1 
 FIN 
 STA ]2 
 IF #=]1 
 LDA #^]1 
 ELSE 
 LDA ]1+2 
 FIN 
 ADC #0 
 STA ]2+2 
 FIN 
 <<< 
SUB4 MAC 
 SEC 
 DO ]0/3 
 IF #=]1 
 LDA #<]1 
 ELSE 
 LDA ]1 
 FIN 
 IF #=]2 
 SBC #<]2 
 ELSE 
 SBC ]2 
 FIN 
 STA ]3 
 IF #=]1 
 LDA #^]1 
 ELSE 
 LDA ]1+2 
 FIN 
 IF #=]2 
 SBC #^]2 
 ELSE 
 SBC ]2+2 
 FIN 
 STA ]3+2 
 ELSE 
 IF #=]1 
 SBC #<]1 
 ELSE 
 SBC ]1 
 FIN 
 STA ]2 
 IF #=]1 
 LDA #^]1 
 ELSE 
 LDA ]1+2 
 FIN 
 SBC #0 
 STA ]2+2 
 FIN 
 <<< 
_OPEN MAC 
 DOS16 $10;]1 
 <<< 
_NEWLINE MAC 
 DOS16 $11;]1 
 <<< 
_READ MAC 
 DOS16 $12;]1 
 <<< 
_CLOSE MAC 
 DOS16 $14;]1 
 <<< 
_GET_EOF MAC 
 DOS16 $19;]1 
 <<< 
^NEWHANDLE MAC 
 P2SL ]1 
 PxW ]2;]3 
 PHL ]4 
 Tool $902 
 <<< 
PXW MAC 
 DO ]0/1 
 PHW ]1 
 DO ]0/2 
 PHW ]2 
 DO ]0/3 
 PHW ]3 
 DO ]0/4 
 PHW ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
P2SL MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
BGT MAC 
 BEQ OV 
 BGE ]1 
OV <<< 
^MTSTARTUP MAC 
 Tool $203 
 <<< 
^MTSHUTDOWN MAC 
 Tool $303 
 <<< 
^MMSTARTUP MAC 
 PHA 
 Tool $202 
 <<< 
^MMSHUTDOWN MAC 
 PHW ]1 
 Tool $302 
 <<< 
_QUIT MAC 
 DOS16 $29;]1 
 <<< 
DOS16 MAC 
 JSL $E100A8 
 DA ]1 
 ADRL ]2 
 <<< 
TOOL MAC 
 LDX #]1 
 JSL $E10000 
 <<< 
**************************************************
key MAC
 ldal $E0C000
 bmi x
 brl ]1
x
 stal $E0C010
 <<<
check MAC  check string exactly
 mvl #Input_Buffer;String_Source
 mvl ]1;String_Object
 jsr Check_String
 bcsl ]2 if not, then goto ]2
 <<<
find MAC  find string occurance
 mvl #Input_Buffer;String_Source
 mvl ]1;String_Object
 jsr Find_String
 bcsl ]2 if not, then goto ]2
 <<<
request MAC
 printxy ]1;]2;]3
 mvl #Input_Buffer;String_Source
 jsr get_String
 <<<
printxy MAC
 mvw ]1;XLoc
 mvw ]2;YLoc
 mvl #s;String_Source
 jsr Draw_Text
 bra x
s asc ]3,00
x <<<
print MAC
 mvl #s;String_Source
 jsr Draw_Text
 bra x
s asc ]1,00
x <<<
printblockxy MAC  draw shr text characters
 mvw ]1;XLoc
 mvw ]2;YLoc
 mvl ]3;string_source
 jsr Draw_Text
 <<<
printblock MAC  draw shr text characters
 mvl ]1;string_source
 jsr Draw_Text
 <<<
phw MAC  push word
 if #=]1
 pea ]1
 else
 if MX/2
 lda ]1+1
 pha
 fin
 lda ]1
 pha
 fin
 <<< 
plw MAC  pull word
 pla
 sta ]1
 <<<
mvw MAC  move word
 lda ]1
 DO ]0/2
 STA ]2
 DO ]0/3
 STA ]3
 DO ]0/4
 STA ]4
 FIN
 FIN
 FIN
 <<<
mvl MAC  move long
 lda ]1
 do ]0/2
 sta ]2
 do ]0/3
 sta ]3
 do ]0/4
 sta ]4
 fin
 fin
 fin
 if #=]1
 lda ^]1
 else
 lda ]1+2
 fin
 do ]0/2
 sta ]2+2
 do ]0/3
 sta ]3+2
 do ]0/4
 sta ]4+2
 fin
 fin
 fin
 <<<
phl MAC  push long
 if #=]1
 pea ^]1
 else
 phw ]1+2
 fin
 phw ]1
 <<<
PLL MAC
 PLA
 DO ]0/1
 STA ]1
 DO ]0/2
 STA ]2
 DO ]0/3
 STA ]3
 DO ]0/4
 STA ]4
 FIN
 FIN
 FIN
 FIN
 PLA
 DO ]0/1
 STA ]1+2
 DO ]0/2
 STA ]2+2
 DO ]0/3
 STA ]3+2
 DO ]0/4
 STA ]4+2
 FIN
 FIN
 FIN
 FIN
 <<<
BEQL MAC 
 BNE OV 
 BRL ]1 
OV <<< 
_MMSHUTDOWN MAC 
 Tool $302 
 <<< 
