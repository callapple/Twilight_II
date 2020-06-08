
**************************************************
* FTA/DYA Three-D T2 Module "Impulse"            *
*                                                *
* Originally by FTA.                             *
* Enhanced by Jim Maricondo, DYA.                *
**************************************************
 lst off
 rel
 xc
 xc
 mx %00
 TR OFF

 USE MACROS
 USE MACROS2

 put t2common.equ

 case se

rele = 1

*=================================================
* Etalon = Zoom, Pnt = Ptr, VIT = SPEED
* BOU = LOOP, Comptuer = Counter, Calculateur =
* Calculator, Moins = Minus
*-------------------------------------------------
FPSCtlID = 1
DelayPopCtlID = 2
ShapePopCtlID = 3
MaxZoomCtlID = 8
CtlLst = 1
resourceToResource = 9

* Bits of ImpulseFlag...
fFPSCounter = 1
fBigShapes = 2

* SendRequest sendHow values
stopAfterOne equ $8000
sendToAll equ 0
sendToName equ 1
sendToUserID equ 2

* NewHandle attributes
attrNoPurge equ $0000 ; Handle Attribute Bits - Not purgeable
attrBank equ $0001 ; Handle Attribute Bits - fixed bank
attrAddr equ $0002 ; Handle Attribute Bits - fixed address
attrPage equ $0004 ; Handle Attribute Bits - page aligned
attrNoSpec equ $0008 ; Handle Attribute Bits - may not use speci
attrNoCross equ $0010 ; Handle Attribute Bits - may not cross ba
attrFixed equ $4000 ; Handle Attribute Bits - not movable
attrLocked equ $8000 ; Handle Attribute Bits - locked

Screen = $E12000
*-------------------------------------------------
 dum 1
****dp da 0
Bank db 0 ;This is how the stack is set up
rtlAddr adr 0 ;with DP at the top and Result
T2data2 adrl 0 ;occupying the top four bytes
T2data1 adrl 0
T2Message da 0
T2Result adrl 0
T2StackSize adrl 0
 dend
*-------------------------------------------------
 DUM $00
Max DS 2
Perspective DS 2
Zoom_Step DS 2
Zoom_Max DS 2
Curve_Pointer DS 2
L1 DS 2 ;Variable des routines de line
L2 DS 2 ;en entree L1,C1 et L2,C2
C1 DS 2 ;contiennent les coordonnees sur 16 bits
C2 DS 2 ;des 2 bouts (Origine en haut a gauche)
DY DS 2
DX DS 2
UT DS 2
ADR DS 2
NBR DS 2
Buf DS 2
RESULT DS 4 ;32 bits   RESULT = ENTER1 * ENTER2
INDEX DS 5 ;40 bits   Pointeur de calcul d'index
ENTER1 DS 2 ;16 bits
ENTER2 DS 2 ;16 bits
ANGX DS 2 ;9 bits
ANGY DS 2 ; "
ANGZ DS 2 ; "
Zoom DS 2 ; "
SGN_11 DS 2 ; <-bug!!!!
SGN_12 DS 2
SGN_21 DS 2
SGN_22 DS 2
SGN_23 DS 2
SGN_32 DS 2
VAL_11 DS 2
VAL_12 DS 2
VAL_21 DS 2
VAL_22 DS 2
VAL_23 DS 2
VAL_32 DS 2
NVAL_22 DS 2
NSGN_22 DS 2
NVAL_12 DS 2
NSGN_12 DS 2
NSGN_33 DS 2
NVAL_33 DS 2
NSGN_11 DS 2
NVAL_11 DS 2
NSGN_21 DS 2
NVAL_21 DS 2
NSGN_31 DS 2
NVAL_31 DS 2
NSGN_13 DS 2
NVAL_13 DS 2
NSGN_23 DS 2
NVAL_23 DS 2
NVAL_32 DS 2
SGN_33 DS 2
VAL_33 DS 2
SGN_13 DS 2
VAL_13 DS 2
Buf_SGN DS 2
Buf_VAL DS 2
Rx DS 2
Ry DS 2
Rz DS 2
Cx DS 2
Cy DS 2
OLD_L2 DS 2
OLD_C2 DS 2
Ptr DS 2
Pnt2 DS 2
Curve_Adr DS 2
SPEEDX DS 2
SPEEDY DS 2
SPEEDZ DS 2
Max_X DS 2
Max_Y DS 2
Max_Z DS 2
CorX DS 2
Result DS 2
Ptr_Clear DS 4
Ptr_Tsb DS 4
Ptr_Tsb2 DS 4
Old DS 2
Cur_Curve ds 2
ZoomOut ds 2
ZoomIn ds 2
fps_offset ds 2
fps_dir ds 2
Bank1Ptr ds 4
Bank2Ptr ds 4
Bank3Ptr ds 4
MovePtr ds 4
DestTick ds 4
 ERR *>$FF
 DEND
*=================================================
 mx %00

Start
 phb
 phk
 plb
 tdc
 sta OurDP

* brk 00

 lda T2Message,s
 cmp #BlankT2
 beq doBlank
 cmp #MakeT2
 beql doMake
 cmp #HitT2
 beql doHit
* cmp #KillT2
* beql doKill
 cmp #SaveT2
 beql doSave
 cmp #LoadSetupT2
 beql doLoadSetup
* cmp #UnloadSetupT2
* beql doUnloadSetup
 brl Bye

*-------------------------------------------------
doBlank = *
 LDX #$FE ; init our DP
]lp STZ $00,X
 DEX
 DEX
 BPL ]lp

 lda T2data1,s
 sta MovePtr ;save this in our own DP
 lda T2data1+2,s
 sta MovePtr+2

* lda T2data2,s
* sta RezFileID

 ~MMStartUp
 pla
 ora #$0100
 sta MyID

* lda T2data2+2,s ;our memory ID
* ora #$0100
* sta MyID

 lda #-1
 sta OneSecStarted


 jsr malloc
 bcc :allocOk
 tay ; save error number
 lda #1 ; not enough memory (requires 192k)
 brl ErrorMaker

:allocOk
 SEP #$30
 ldal $E0C035
 REP #$30
 and #$FF
 bit #$08
 beq :shadowOk
 ldy #0 ; error $0000
 lda #2 ; shadowing not available
 brl ErrorMaker

:shadowOk

 PushLong #toT2String
 jsl init_random

 lda Bank1Ptr
 sta Rout_Tsb+1
 lda Bank1Ptr+1
 sta Rout_Tsb+2
 lda Bank3Ptr
 sta ClearFill+1
 lda Bank3Ptr+1
 sta ClearFill+2

 LDA #1 ; start filling in first operand
 STA Ptr_Clear
 STA Ptr_Tsb
 STA Ptr_Tsb2
 LDA Bank3Ptr+2 ; init pointers
 STA Ptr_Clear+2
 LDA Bank1Ptr+2
 STA Ptr_Tsb+2
 SEP #$20
 STA Rout_Tsb+3 ; patch in Tsb routine 1 to start
 REP #$20
 lda Bank2Ptr+2 ; init pointer
 STA Ptr_Tsb2+2

* fill in the opcodes into our rapidfast clear and show routines
* bank1 = tsb1
* bank2 = tsb2
* bank3 = clear

 ldy #0
]lp LDA #$9C ; STZ OP
 STA [Bank3Ptr],y ; clear
 LDA #$0C ; TSB OP
 sta [Bank1Ptr],y ; tsb1
 sta [Bank2Ptr],y ; tsb2
 iny
* LDA #0
* sta [Bank1Ptr],y
* sta [Bank2Ptr],y
* sta [Bank3Ptr],y
 iny
 iny
 cpy #$FF00
 BCC ]lp

 ldx #$8000-2 ; clear the shr shadowed memory area
 lda #0
]lp stal $012000,x
 dex
 dex
 bpl ]lp


 jsr Setup_3d
 jsr New_Curve

 stz Zoom
 lda #1
 sta ZoomIn

 lda ImpulseFlag
 and #fFPSCounter ; fps off/on
 beq :no_fps

 JSR Init_Counter ; init fps counter
:no_fps

 LDAL $E0C035 ; make sure shr shadowing is off
 ora #$08
 STAL $E0C035
 bra TOP

return = *
 lda ImpulseFlag
 and #fFPSCounter ; fps off/on
 beq no_fps2

 lda OneSecStarted
 bne :skip
 ~IntSource #7 ; disable 1sec

:skip lda #$0000
org_patch1 = *-2
 stal $E10054
 lda #$0000
org_patch2 = *-2
 stal $E10056

no_fps2
 ~DisposeAll MyID
 lda MyID
 and #$F0FF
 pha
 _MMShutDown

Bye = *
skip = *
 plb
 lda 1,s ; move up RTL address
 sta 1+10,s
 lda 2,s
 sta 2+10,s
 tsc ; Remove input parameters.
 clc
 adc #10
 tcs
 clc
 rtl
*-------------------------------------------------
TOP

 lda ZoomOut
 beq no_Zout



 LDA Zoom
 SEC
 SBC Zoom_Step
 BCS Not_Min



 lda ImpulseShapes
 cmp #1 ; all
 bne :nonew
 jsr New_Curve
:nonew


 stz ZoomOut
 lda #1
 sta ZoomIn
 lda #0
Not_Min STA Zoom


no_Zout lda ZoomIn
 beq no_Zin

 LDA Zoom
 CLC
 ADC Zoom_Step
 CMP Zoom_Max
 blt Not_Max
 stz ZoomIn


* multiply it by 10 to get seconds, then by 60 to get ticks, or by 600 for both
* 512+64+16+8 = 600
* 2^9 + 2^6 + 2^4 + 2^3 = 600

 lda ImpulseFlag ; delay in hi byte
 xba
 and #$FF
 asl ; x2
 asl ; x4
 asl  ; x8
 pha  ; 2^3
 asl  ; x16
 pha  ; 2^4
 asl  ; x32
 asl  ; x64
 pha  ; 2^6
 asl  ; x128
 asl  ; x256
 asl  ; x512 = 2^9
 clc
 adc 1,s ;       +2^6
 adc 3,s ;       +2^4
 adc 5,s ;       +2^3
 sta ticks+1
 plx
 _GetTick
 pla
 plx
 clc
ticks adc #1200
 sta DestTick
 txa
 adc #0
 sta DestTick+2
 lda Zoom_Max
Not_Max STA Zoom

no_Zin JSR Calculator ; calculate cos/sin's for current angles

 INC Cmpt_Frame ; increment frame count

 SEP #$30
 LDA Rout_Tsb+3
 cmp Bank1Ptr+2
 beq tsb2_nxt
 lda Bank1Ptr+2
 sta Rout_Tsb+3
Clear2 LDA #1
 STA Ptr_Tsb2
 STZ Ptr_Tsb2+1
 BRA Cont_Clear
tsb2_nxt lda Bank2Ptr+2
 sta Rout_Tsb+3
 LDA #1
 STA Ptr_Tsb
 STZ Ptr_Tsb+1

Cont_Clear REP #$30

 lda Curve_Adr
 cmp #Curve_Rebound
 bne not_rebound
 JSR Update_Rebound

not_rebound
 LDA #1 ; reinit operand offset into STZ routine
 STA Ptr_Clear

 STZ Old ; init last shr addr plotted variable

 LDA #14+2 ; init offset into shape to 14
 STA Buf ; (Start of the shape definition)

]loop LDY Buf
 LDA (Curve_Adr),Y
 AND #$00FF
 CMP #$00FF ; have we reached the end of the shape def?
 BEQ End_Cycle ; yes, so we're finished updating it this frame.
 BIT #%0000_0000_1000_0000 ; at the start of a new line element?
 BEQ No_New_Enter ; no, so connect this new point to the last.
 AND #%0000_0000_0111_1111 ; yes, so first and out the msb
 ASL  ; x2
 PHA  ; save X
 INY
 LDA (Curve_Adr),Y ; get Y of this point
 AND #$00FF
 ASL
 TAX
 INY
 LDA (Curve_Adr),Y ; get Z
 AND #$00FF
 ASL
 PLY
 JSR Calc_Curve ; find screen coordinates of X,Y,Z
 INC Buf ; move to next point
 INC Buf
 INC Buf
 BRA Cont ; move to connecting point.
No_New_Enter LDA OLD_L2 ; draw a line from the last point to this
 LDY OLD_C2 ; current point.
Cont STA L1 ; store the calculated screen coordinates of the
 STY C1 ; last point/current point.
 LDY Buf ; retrieve offset into shape
 LDA (Curve_Adr),Y ; get new X
 AND #$00FF
 ASL
 PHA
 INY
 LDA (Curve_Adr),Y ; get new Y
 AND #$00FF
 ASL
 TAX
 INY
 LDA (Curve_Adr),Y ; get new Z
 AND #$00FF
 ASL
 PLY
 JSR Calc_Curve ; find screen coordinates of X,Y,Z
 STA L2 ; store screen coordinates
 STA OLD_L2
 STY C2
 STY OLD_C2
* bcc skiphline
 JSR HLine ; draw a line between the last point and this one
* skiphline
 INC Buf ; move on to next point
 INC Buf
 INC Buf
 BRA ]loop

End_Cycle add ANGX;SPEEDX ; adjust our angles by the speeds
 add ANGY;SPEEDY
 add ANGZ;SPEEDZ

 sep $30
 ldal $E0C035
 and #$F7
 stal $E0C035 ; shr shadowing on
 rep $30

 DEC Ptr_Tsb ; move back ptrs from operand to opcode
 DEC Ptr_Tsb2
 DEC Ptr_Clear
 LDA #$6B ; RTL
 STA [Ptr_Clear] ; store it in all 3 routines at the end of the
 STA [Ptr_Tsb] ; filled in operands for this frame
 STA [Ptr_Tsb2]
 PHB
 PEA $0101
 PLB
 PLB
Rout_Tsb JSL $000000 ; update the next frame so we can see it onscreen
 PLB

 lda ZoomIn
 bne :skip
 lda ZoomOut
 bne :skip


 lda ImpulseShapes
 cmp #1 ; all
 bne :skip
 JSR Test_Key ; handle keypresses (time to zoom out?)
:skip lda [MovePtr]
 BNEL return

* LDA $C035 ; make sure shadowing is now OFF
* ORA #$801E ; (and insure fast speed while we're at it :)
* STA $C035

 ldal $E0C035
 ora #$08
 stal $E0C035

 PHB
 PEA $0101
 PLB
 PLB
ClearFill JSL $000000 ; erase lines from last frame
 PLB

 LDA #$9C ; put STZ opcode back over the RTL
 STA [Ptr_Clear]
 AND #$0F ; put TSB opcode back over the RTL (FTA;0C)
 STA [Ptr_Tsb]
 STA [Ptr_Tsb2]
 INC Ptr_Tsb
 INC Ptr_Tsb2

 BRL TOP ; next frame!

*=================================================
malloc = *

* brk $ff

* Get one bank of attrLocked+attrFixed+attrNoSpec+attrAddr memory

 ~NewHandle #$FFFF;MyID;#attrLocked+attrPage+attrFixed+attrNoSpec+attrNoCross;#$000000
 bcc :goodMem1
 plx
 plx
 sec
 rts

:goodMem1
 phd
 tsc
 tcd
 ldy #2
 lda [3]
 tax
 lda [3],y
 sta <5
 stx <3
 pld
 pla
 sta Bank1Ptr
 pla
 sta Bank1Ptr+2


* ~NewHandle #$010000;MyID;#$C00A;#$000000
* ~NewHandle #$FFFF;MyID;#attrLocked+attrFixed+attrNoSpec+attrAddr;#$000000
 ~NewHandle #$FFFF;MyID;#attrLocked+attrPage+attrFixed+attrNoSpec+attrNoCross;#$000000
 bcc :goodMem2
 plx
 plx
 sec
 rts

:goodMem2
 phd
 tsc
 tcd
 ldy #2
 lda [3]
 tax
 lda [3],y
 sta <5
 stx <3
 pld
 pla
 sta Bank2Ptr
 pla
 sta Bank2Ptr+2


* Get one bank of attrLocked+attrFixed+attrNoSpec+attrAddr memory

* ~NewHandle #$010000;MyID;#$C00A;#$000000
* ~NewHandle #$FFFF;MyID;#attrLocked+attrFixed+attrNoSpec+attrAddr;#$000000
 ~NewHandle #$FFFF;MyID;#attrLocked+attrPage+attrFixed+attrNoSpec+attrNoCross;#$000000
 bcc :goodMem3
 plx
 plx
 sec
 rts

:goodMem3
 phd
 tsc
 tcd
 ldy #2
 lda [3]
 tax
 lda [3],y
 sta <5
 stx <3
 pld
 pla
 sta Bank3Ptr
 pla
 sta Bank3Ptr+2
 clc
 rts

*-------------------------------------------------
* take the data from the shape header and stuff
* it in the right variables

Get_Curve = *

 lda ImpulseFlag
 bit #fBigShapes
 bne :yes

 ldy #02
 LDA (Curve_Adr)
 bra :no

:yes LDY #02
 LDA (Curve_Adr),Y
:no STA Zoom_Max
 STA Zoom
 LSR
 LSR
 LSR
 LSR
 LSR
 LSR
 AND #%0000_0011_1111_1111
 STA Zoom_Step
 INY
 INY
 LDA (Curve_Adr),Y
 STA Max_X
 INY
 INY
 LDA (Curve_Adr),Y
 STA Max_Y
 INY
 INY
 LDA (Curve_Adr),Y
 STA Max_Z
 INY
 INY
 LDA (Curve_Adr),Y
 STAL $E19E1E
 INY
 INY
 LDA (Curve_Adr),Y
 STAL $E19E02
 INY
 INY
 LDA (Curve_Adr),Y
 STA Perspective
 LDA Max_X
 CMP Max_Y
 BCC XMax0
 LDA Max_Y
XMax0 CMP Max_Z
 BCS YMax0
 LDA Max_Z
YMax0 XBA
 AND #$FF00
 ASL
 STA Max
 RTS

*-------------------------------------------------

Setup_3d = *

 LDA #0-2 ; init speeds and angles
 STA SPEEDX
 LDA #0-4
 STA SPEEDY
 LDA #0+2
 STA SPEEDZ
 STZ ANGX
 STZ ANGY
 STZ ANGZ
 rts

*-------------------------------------------------

Update_Rebound PHP
 SEP #$30
 LDX #0
Pos_Rebond = *-1
 LDA Rebond_Sol,X
 STA AltSol0
 STA AltSol1
 LDA #s
 SEC
 SBC Rebond_Obj,X
 STA AltObj1
 STA AltObj2
 STA AltObj3
 STA AltObj4
 STA AltObj5
 STA AltObj6
 STA AltObj7
 STA AltObj8
 ORA #%1000_0000
 STA AltObj0
 SEC
 SBC #4
 STA AltBas0
 STA AltBas1
 STA AltBas2
 STA AltBas3
 INX
 CPX #20
 BCC No_DepRebond
 LDX #0
No_DepRebond STX Pos_Rebond
 PLP
 RTS
 mx %00

*-------------------------------------------------

Calc_Curve = *
 STA Rz
 STY Rx
 STX Ry
 LDA Perspective
 BEQ Calcul_Perspective
 BRL Calc_CurveOld
Calcul_Perspective LDX Rz
 LDA Table_31,X
 CLC
 LDX Rx
 ADC Table_21,X
 LDX Ry
 ADC Table_11,X
 ADC Max
 STA CorX
 LDX Rz
 LDA Table_32,X
 LDX Rx
 CLC
 ADC Table_22,X
 LDX Ry
 ADC Table_12,X
 BPL Positif_Y
Negatif_Y
 EOR #$FFFF ;Divise Abs(Y) par CorX
 INC
 STZ Result
 LUP 6
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 ASL
 --^
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 LDA #161
 SEC
 SBC Result
 BRA SuiteZ

Positif_Y STZ Result ;Divise Abs(Y) par CorX
 LUP 6
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 ASL
 --^
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 LDA #161
 CLC
 ADC Result
SuiteZ TAY

 LDX Rz
 LDA Table_33,X
 LDX Rx
 CLC
 ADC Table_23,X
 LDX Ry
 ADC Table_13,X
 BPL Positif_Z
Negatif_Z
 EOR #$FFFF ;Divise Abs(Z) par CorX
 INC
 STZ Result
 LUP 6
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 ASL
 --^
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 LDA #100
 SEC
 SBC Result
 do 0
 cmp #100
 bcs nodraw
 sec
 RTS
nodraw clc
 fin
 rts

Positif_Z STZ Result ;Divise Abs(Y) par CorX
 LUP 6
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 ASL
 --^
 CMP CorX
 BCC *+4
 SBC CorX
 ROL Result
 LDA #100
 CLC
 ADC Result ; Lgn
 do 0
 cmp #100
 fin
 RTS

*-------------------------------------------------

Test_Key = *
 ~GetTick
 pla
 plx
 cpx DestTick+2
 blt notYet
 cmp DestTick
 blt notYet
 lda ZoomOut
 bne notYet ; already zooming (not needed)
 do 0
 inc Cur_Curve
 fin
 lda #1
 sta ZoomOut ; ZoomOut = TRUE
 stz ZoomIn ; ZoomIn = FALSE
notYet rts

 do 0
Test_Key SEP #$20
 LDAL $E0C000
 STAL $E0C010
 REP #$20
 AND #$00FF
 CMP #"0"
 BNE No_Zero
 STZ ANGX
 STZ ANGZ
 STZ SPEEDX
 STZ SPEEDZ
 LDA #0-4
 STA SPEEDY
 RTS
No_Zero CMP #"7"
 BNE No_7
 DEC SPEEDZ
 RTS
No_7 CMP #"8"
 BNE No_8
 STZ SPEEDZ
 RTS
No_8 CMP #"9"
 BNE No_9
 INC SPEEDZ
 RTS
No_9 CMP #"4"
 BNE No_4
 DEC SPEEDY
 RTS
No_4 CMP #"5"
 BNE No_5
 STZ SPEEDY
 RTS
No_5 CMP #"6"
 BNE No_6
 INC SPEEDY
 RTS
No_6 CMP #"1"
 BNE No_1
 DEC SPEEDX
 RTS
No_1 CMP #"2"
 BNE No_2
 STZ SPEEDX
 RTS
No_2 CMP #"3"
 BNE No_3
 INC SPEEDX
 RTS
No_3 CMP #"+"
 BNE No_Plus
Zoom_In LDA Zoom
 CLC
 ADC Zoom_Step
 CMP Zoom_Max ; implement this later ?
No_Max STA Zoom
 RTS
No_Plus CMP #"-"
 BNE No_Minus
Zoom_Off LDA Zoom
 SEC
 SBC Zoom_Step
 BCS No_Min
 LDA #0
No_Min STA Zoom
 RTS
No_Minus CMP #"*"
 bne No_Star
 lda ZoomOut
 bne alreadyzooming
 inc Cur_Curve
 lda #1
 sta ZoomOut ; ZoomOut = TRUE
alreadyzooming stz ZoomIn ; ZoomIn = FALSE
 rts
No_Star cmp #$1B
 bne No_Esc
 sta Escape ; escape = TRUE
No_Esc rts
 fin

*-------------------------------------------------

Calc_CurveOld = *
 LDX Rz
 LDA Table_31,X
 CLC
 LDX Rx
 ADC Table_21,X
 LDX Ry
 ADC Table_11,X
 ADC #161*128
 LSR
 LSR
 LSR
 LSR
 LSR
 LSR
 LSR
 AND #%0000_0001_1111_1111
 TAY
 LDX Rz
 LDA Table_32,X
 LDX Rx
 CLC
 ADC Table_22,X
 LDX Ry
 ADC Table_12,X
 ADC #100*128
 LSR
 LSR
 LSR
 LSR
 LSR
 LSR
 LSR
 AND #%0000_0001_1111_1111
 RTS

*-------------------------------------------------

Calculator = *
 REP #$30

 LDA ANGX
 ASL
 TAX
 LDA Table_Cos+$400,X
 STA SGN_11
 STA NSGN_22
 LDA Table_Cos,X
 LDY Zoom
 JSR FOIS
 STA VAL_11 ; En premier la ligne
 STA NVAL_22
 LDA ANGX
 ASL
 TAX
 LDA Table_Sin+$400,X
 STA SGN_21
 EOR #1
 STA NSGN_12
 LDA Table_Sin,X
 LDY Zoom
 JSR FOIS
 STA VAL_21
 STA NVAL_12

* Actif : VAL_11,NVAL_12,VAL_21,NVAL_22            33=Zoom

 LDA ANGY
 ASL
 TAX
 LDA Table_Cos+$400,X
 PHA
 STA NSGN_33
 EOR SGN_11
 STA NSGN_11
 PLA
 EOR SGN_21
 STA NSGN_21
 LDA Table_Cos,X
 PHA
 LDY VAL_11
 JSR FOIS
 STA NVAL_11 ; *
 LDA $01,S
 LDY Zoom
 JSR FOIS
 STA NVAL_33
 PLA
 LDY VAL_21
 JSR FOIS
 STA NVAL_21  ; *
 LDA ANGY
 ASL
 TAX
 LDA Table_Sin+$400,X
 STA NSGN_31
 EOR #1
 PHA
 EOR SGN_11
 STA NSGN_13
 PLA
 EOR SGN_21
 STA NSGN_23
 LDA Table_Sin,X
 PHA
 LDY VAL_11
 JSR FOIS
 STA NVAL_13
 LDA $01,S
 LDY VAL_21
 JSR FOIS
 STA NVAL_23
 PLA
 LDY Zoom
 JSR FOIS
 STA NVAL_31 ; *

 LDA ANGZ
 ASL
 TAX
 LDA Table_Sin+$400,X
 PHA
 EOR NSGN_33
 STA SGN_32
 PLA
 EOR NSGN_13
 STA Buf_SGN
 LDA Table_Sin,X
 PHA
 LDY NVAL_33
 JSR FOIS
 STA VAL_32 ; *
 PLA
 LDY NVAL_13
 JSR FOIS
 STA Buf_VAL
 LDA ANGZ
 ASL
 TAX
 LDA Table_Cos+$400,X
 EOR NSGN_12
 STA SGN_12
 PHA
 LDA Table_Cos,X
 LDY NVAL_12
 JSR FOIS
 PLY
 Add Buf_SGN;Buf_VAL;SGN_12;VAL_12
 LDA ANGZ
 ASL
 PHA
 TAX
 LDA Table_Sin+$400,X
 EOR NSGN_23
 STA Buf_SGN
 LDA Table_Sin,X
 LDY NVAL_23
 JSR FOIS
 STA Buf_VAL
 PLX
 LDA Table_Cos+$400,X
 EOR NSGN_22
 STA SGN_22
 PHA
 LDA Table_Cos,X
 LDY NVAL_22
 JSR FOIS
 PLY
 Add Buf_SGN;Buf_VAL;SGN_22;VAL_22

 TABLE_SPECIAL NVAL_11;NSGN_11;Table_11;Max_X
 TABLE_SPECIAL NVAL_21;NSGN_21;Table_21;Max_Y
 TABLE_SPECIAL NVAL_31;NSGN_31;Table_31;Max_Z

 TABLE VAL_12;SGN_12;Table_12;Max_X
 TABLE VAL_22;SGN_22;Table_22;Max_Y
 TABLE VAL_32;SGN_32;Table_32;Max_Z


 LDA Perspective
 BEQ Calc_Z

 RTS
Calc_Z = *

 LDA ANGZ
 ASL
 TAX
 LDA Table_Sin+$400,X
 EOR #1
 EOR NSGN_12
 STA Buf_SGN
 LDA Table_Sin,X
 LDY NVAL_12
 JSR FOIS
 STA Buf_VAL
 LDA ANGZ
 ASL
 TAX
 LDA Table_Cos+$400,X
 PHA
 EOR NSGN_33
 STA SGN_33 ; *
 PLA
 EOR NSGN_13
 STA SGN_13
 PHA
 LDA Table_Cos,X
 PHA
 LDY NVAL_33
 JSR FOIS
 STA VAL_33 ; *
 PLA
 LDY NVAL_13
 JSR FOIS
 PLY
 Add Buf_SGN;Buf_VAL;SGN_13;VAL_13

 LDA ANGZ
 ASL
 PHA
 TAX
 LDA Table_Sin+$400,X
 EOR #1
 EOR NSGN_22
 STA Buf_SGN
 LDA Table_Sin,X
 LDY NVAL_22
 JSR FOIS
 STA Buf_VAL
 PLX
 LDA Table_Cos+$400,X
 EOR NSGN_23
 STA SGN_23
 PHA
 LDA Table_Cos,X
 LDY NVAL_23
 JSR FOIS
 PLY
 Add Buf_SGN;Buf_VAL;SGN_23;VAL_23

 TABLE VAL_13;SGN_13;Table_13;Max_X
 TABLE VAL_23;SGN_23;Table_23;Max_Y
 TABLE VAL_33;SGN_33;Table_33;Max_Z

 RTS

*-------------------------------------------------
***********************************
*            Multiply             *
* 16 bit x 16 bit = 32 bit result *
* - Call with input in A and Y    *
* - Returns with output in result *
***********************************


FOIS = *
Multiply
 php
 rep $30

 lr
 pha
 phy
 ldx #$090b ; multiply
 jsl $e10000
 plx
 pla
 bcc ]noerr
 lda #0
 tax
]noerr stx RESULT
 sta RESULT+2

 do 0
 stz RESULT
 sta multiplic
 ldx #16
 tya
:mult1 lsr
 lda RESULT
 bcc :mult2
 clc
 adc multiplic
:mult2 ror
 sta RESULT
 tya
 ror
 tay
 dex
 bne :mult1
 sty RESULT+2
 cpy #0
 bne :overflow
 lda RESULT+2 ;RESULT
 fin
 plp
 rts

 do 0
:overflow brk $FF
 lda #0
 sta RESULT
 sta RESULT+2
 plp
 rts
multiplic ds 2
 fin

*-------------------------------------------------
* HLine - FTA's famous line routine.
* On entry:
* L1 - line of first point
* C1 - column of first point (in bytes)
* L2 - line of second point
* C2 - column of second point
* The routine will connect the two points with a line.
*
 MX %00

HLine = *

* STA L2
* STY C2

 LDA L1
 CMP L2
 BCC ZNO_INV2
 LDY L2
 STA L2
 STY L1
 LDA C1
 LDY C2
 STY C1
 STA C2
ZNO_INV2 = *
 LDA L1 ;Calcule l'adresse base de trace
 ASL
 ASL
 ADC L1
 ASL
 ASL
 ASL
 ASL
 ASL
 ASL
 ADC C1
 STA ADR

 LDA L2
 SEC
 SBC L1
 STA DY
 LDA C1
 CMP C2
 BCCL ZFDIR
ZFINDIR SBC C2
 STA DX
 CMP DY
 BCC ZFINDIR3
 BRL ZFINDIR2

ZFINDIR3 LDA DY
 TAY
 LSR
 EOR #$FFFF
 INC
]LOOP STA UT
 LDA ADR
 LSR
 TAX
 BCC ZP_GAU1
 CLC
 BRA *+4

]LOOP2 STA UT
 Plot0
 DEY
 BMI ZFIN1
 TXA
 ADC #$A0
 TAX
 LDA DX
 ADC UT
 BMI ]LOOP2
 SBC DY

]LOOP STA UT
ZP_GAU1 = *
 Plot1
 DEY
 BMI ZFIN1
 TXA
 ADC #$A0
 TAX
 LDA DX
 ADC UT
 BMI ]LOOP
 SBC DY
 DEX
 BRL ]LOOP2
ZFIN1 RTS

ZFDIR LDA C2
 SEC
 SBC C1
 STA DX
 CMP DY
 BCSL ZFDIR2
ZFDIR3 LDA DY
 TAY
 INC
 LSR
 EOR #$FFFF
 INC
]LOOP STA UT
 LDA ADR
 LSR
 TAX
 BCC ZP_GAU2
 CLC
 BRA *+4

]LOOP2 STA UT
 Plot0
 DEY
 BMI ZFIN2
 TXA
 ADC #$A0
 TAX
 LDA DX
 ADC UT
 BMI ]LOOP2
 SBC DY
 INX

]LOOP STA UT
ZP_GAU2 = *
 Plot1
 DEY
 BMI ZFIN2
 TXA
 ADC #$A0
 TAX
 LDA DX
 ADC UT
 BMI ]LOOP
 SBC DY
 BRL ]LOOP2
ZFIN2 RTS

ZFDIR2 LDA DX
 TAY
 LSR
 EOR #$FFFF
 INC
 STA UT
 LDA ADR
 LSR
 TAX
 BCC ZP_GAU4
 CLC
 BRA *+4

]LOOP2 STA UT
 Plot0
 DEY
 BMI ZFIN4
 INX
 LDA DY
 ADC UT
 BMI ZP_GAU4-2
 SBC DX
 STA UT
 TXA
 ADC #$A0
 TAX
 BRA *+4

 STA UT
ZP_GAU4 = *
 Plot1
 DEY
 BMI ZFIN4
 LDA DY
 ADC UT
 BMIL ]LOOP2
 SBC DX
 STA UT
 TXA
 ADC #$A0
 TAX
 BRL ]LOOP2+2
ZFIN4 RTS


ZFINDIR2 LDA DX
 TAY
 LSR
 EOR #$FFFF
 INC
]LOOP STA UT
 LDA ADR
 LSR
 TAX
 BCC ZP_GAU3
 CLC
 BRA *+4

]LOOP2 STA UT
 Plot0
 DEY
 BMI ZFIN3
 LDA DY
 ADC UT
 BMI ZP_GAU3-2
 SBC DX
 STA UT
 TXA
 ADC #$A0
 TAX
 BRA *+4

 STA UT
ZP_GAU3 = *
 Plot1
 DEY
 BMI ZFIN3
 DEX
 LDA DY
 ADC UT
 BMIL ]LOOP2
 SBC DX
 STA UT
 TXA
 ADC #$A0
 TAX
 BRL ]LOOP2+2
ZFIN3 RTS

*=================================================

* -------------------- *
* Counter de Frame... *
* -------------------- *

* Position du compteur sur l'ecran

Adr_Screen = $E12000+$84 ;;;$8A

* Variable a incrementer a chaque 'cycle' d'animation

Cmpt_Frame DS 2

* Initialisation du compteur

Init_Counter PHP
 REP #$30

 ldal $E10054
 sta org_patch1
 ldal $E10056
 sta org_patch2

 HEX A9
 HEX 5C
 DFB #<Inter_1Sec
 STAL $E10054
 HEX A9
 DFB #>Inter_1Sec
 DFB #^Inter_1Sec
 STAL $E10056
 do 0
 DFB $A9,$5C,<Inter_1Sec
 STAL $E10054
 dfb $a9,>Inter_1Sec
 LDA #^Inter_1Sec ;;;;/$100
 STAL $E10056
 fin
 STZ Cmpt_Second
 STZ Cmpt_Frame
 LDX #$1E
]lp LDAL $E19E00,X
 STAL $E19FE0,X
 DEX
 DEX
 BPL ]lp
 LDA #$0400
 STAL $E19FE8
 LDA #$0C00
 STAL $E19FEC
 SEP #$30
 LDX #6
 LDA #$0F
]lp STAL $E19D00,X
 DEX
 BPL ]lp
 rep $30

 ~GetIRQEnable
 pla
 and #%10000 ; 1 second interrupts - bit 4
 sta OneSecStarted
 bne :alreadyOn

 ~IntSource #6 ; enable 1sec
:alreadyOn PLP
 RTS

*-------------------------------------------------
OneSecStarted ds 2
Cmpt_Second DS 2
*-------------------------------------------------

Inter_1Sec PHP
 PHB
 phd
 PHK
 PLB
 REP #$30
 lda OurDP
 tcd
 INC Cmpt_Second
 LDA Cmpt_Second
 CMP #2
 BNE Not_Enough
 JSR Show_NbFrame
 STZ Cmpt_Second
 STZ Cmpt_Frame
 lda fps_dir
 bne left
right inc fps_offset
 lda fps_offset
 cmp #14
 blt nochange
 sta fps_dir
 bra nochange
left dec fps_offset
 lda fps_offset
 bne nochange
 stz fps_dir
nochange
Not_Enough SEP #$20
 ldal $E0C032
 and #%1011_1111
 stal $E0C032
 pld
 PLB
 PLP
 CLC
 RTL

Show_NbFrame SEP #$30

 LDA #"0"
 STA Res+5
 LDA #";"
 STA Res+4
 LDA Cmpt_Frame
 LSR
 BCC No5
 LDX #"5"
 STX Res+5
No5 JSR Convert
 REP #$30
 LDX #1
 STZ Pos_Cmpt
]loopaga PHX
 LDA Res,X
 AND #$00FF
 SEC
 SBC #$B0
 TAX
 LDA Table_Digit,X
 AND #$00FF
 TAY
* LDX Pos_Cmpt
 LDa Pos_Cmpt
 clc
 adc fps_offset
 tax

]A = 0
 LUP 7
 LDA {]A*2}+Digit,Y
 STAL ]A*$A0+Adr_Screen,X
 LDA #0
 STAL ]A*$A0+Adr_Screen+2,X
]A = ]A+1
 --^
 LDA Pos_Cmpt
 INC
 INC
 INC
 STA Pos_Cmpt
 PLX
 INX
 CPX #6
 BEQ End_LgnCompteur
 BRL ]loopaga
End_LgnCompteur RTS

*-------------------------------------------------

Pos_Cmpt DS 2

Table_Digit DFB 0
 DFB 14
 DFB 14*2
 DFB 14*3
 DFB 14*4
 DFB 14*5
 DFB 14*6
 DFB 14*7
 DFB 14*8
 DFB 14*9
 DFB 14*10
 DFB 14*11

*-------------------------------------------------

 MX %11
Convert = *

 STA VALUE

 LDX #":" ; Led Off
 STX Res

Positif LDX #2 ; Nb de chiffre max en resultat
 STX LEAD0
 STZ VALUE+1

 LDY #1 ; Counter
PRTI1 LDA #":" ; Off
 STA Res,Y

 LDA #"0"
 STA DIGIT

PRTI2 SEC
 LDA VALUE
 SBC TBL_LO,X
 PHA
 LDA VALUE+1
 SBC TBL_HI,X
 BCC PRTI3

 STA VALUE+1
 PLA
 STA VALUE
 INC DIGIT
 JMP PRTI2

PRTI3 PLA
 LDA DIGIT
 CPX #0
 BEQ PRTI5
 CMP #"0"
 BEQ PRTI4
 STA LEAD0

PRTI4 BIT LEAD0
 BPL PRTI6
PRTI5 LDA DIGIT
 STA Res,Y
PRTI6 INY
 DEX
 BPL PRTI1
 RTS

Res DS 7

LEAD0 DS 2
DIGIT DS 2
VALUE DS 2

OurDP ds 2

TBL_LO DFB #1
 DFB #10
 DFB #100
 DFB #1000
 DFB #10000

TBL_HI DFB #>1
 DFB #>10
 DFB #>100
 DFB #>1000
 DFB #>10000


Digit HEX 06606006600604406006600606600440
 HEX 40064006044040064006044006604006
 HEX 40060660600460040660066040064006
 HEX 06604006400606600440600660060660
 HEX 40064006044006606004600406604006
 HEX 40060660066060046004066060066006
 HEX 06600660400640060440400640060440
 HEX 06606006600606606006600606600660
 HEX 600660060660400640060660

 do 0
 HEX 0440 ; Off
 HEX 4004
 HEX 4004
 HEX 0440
 HEX 4004
 HEX 4004
 HEX 0440
 fin

 HEX 0000 ; Off
 HEX 0000
 HEX 0000
 HEX 0000
 HEX 0000
 HEX 0000
 HEX 0000

 HEX 0440 ; .
 HEX 4004
 HEX 4004
 HEX 0440
 HEX 4004
 HEX 4004
 HEX 0460

*-------------------------------------------------
 PUT CURVES
Table_Cos = * ; Sur 16bits, 1=$10000
Table_Sin = *+$800
 PUT TABLE.COS

Table_11 ds $100
Table_21 ds $100
Table_31 ds $100
Table_12 ds $100
Table_22 ds $100
Table_32 ds $100
Table_13 ds $100
Table_23 ds $100
Table_33 ds $100
 LST OFF

*-------------------------------------------------
MyID ds 2
WindPtr ds 4
RezFileID ds 2
*=================================================
 mx %00
*=================================================
* Hit
*
* handle item hits

doHit = *

 lda #0
 sta T2Result+2,s
 sta T2Result,s
 lda T2data2+2,s ; ctlID hi word must be zero
 bne :nothingHit
 lda T2data2,s ; get ctlID
 cmp #FPSCtlID
 beq :enable
 cmp #DelayPopCtlID
 beq :enable
 cmp #ShapePopCtlID
 beq :enable
 cmp #MaxZoomCtlID
 beq :enable
:nothingHit brl Bye

:enable lda #TRUE
 sta T2Result,s
 bra :nothingHit

*=================================================
*
* Create all the buttons in the window
*
doMake = *

* brk $11
 lda T2data1+2,s
 sta WindPtr+2
 lda T2data1,s
 sta WindPtr
 lda T2data2,s
 sta RezFileID
* lda T2data2+2,s
* sta MyID
 ~MMStartUp
 pla
 sta MyID

 ~NewControl2 WindPtr;#resourceToResource;#CtlLst
 plx
 plx

* make sure setup is loaded..

 ~GetCurResourceFile
 ~SetCurResourceFile RezFileID
 jsr load_setup
 _SetCurResourceFile

 lda ImpulseFlag
 and #fFPSCounter ; fps off/on
 pha
 ~GetCtlHandleFromID WindPtr;#FPSCtlID
 _SetCtlValue

 lda ImpulseFlag
 and #fBigShapes ; large shapes off/on
 lsr
* eor #1
 pha
 ~GetCtlHandleFromID WindPtr;#MaxZoomCtlID
 _SetCtlValue

 lda ImpulseFlag
 and #$FF00
 xba
 pha
 ~GetCtlHandleFromID WindPtr;#DelayPopCtlID
 _SetCtlValue

 lda ImpulseShapes
 pha
 ~GetCtlHandleFromID WindPtr;#ShapePopCtlID
 _SetCtlValue

 lda #8
 sta T2Result,s
 brl Bye

*=================================================

* ImpulseFlag:
* (fFPSCounter) bit 0: 0 = fps off (default), 1 = fps on
* (fBigShapes) bit 1: 0 = big shapes off (default), 1 = big shapes on
* bits 8-15: delay.  multiply by 10 to turn into seconds

ImpulseFlag ds 2

* ImpulseShape:
* 1 = All
* 2 = random
* else, = shape + 2 (so shape 1 would = 3)

ImpulseShapes ds 2

temp ds 4

rImpulseFlag str 'Impulse: Flags'
rImpulseShapes str 'Impulse: Shapes'

toT2String str 'DYA~Twilight II~'
*=================================================
doLoadSetup = *

* brk $22
 jsr load_setup
 brl Bye

load_setup = *

* brk $33

* Load the fps/maxzoom/delay resource.

 ~RMLoadNamedResource #rT2ModuleWord;#rImpulseFlag
 bcc :flagThere
 plx
 plx ;setup not saved yet...
 lda #$0200 ; 20 second delay, no fps, no large shapes
 sta ImpulseFlag
 bra :noFlag

:flagThere
 jsr makePdp
 lda [3]
 sta ImpulseFlag
 killLdp

 do rele
 PushWord #3
 PushWord #rT2ModuleWord ;rtype for release
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseFlag;#temp ;rID
 _ReleaseResource
 fin

:noFlag

* Load the shapes resource.

 ~RMLoadNamedResource #rT2ModuleWord;#rImpulseShapes
 bcc :shapesThere
 plx
 plx ; setup not saved yet...
 lda #1
 sta ImpulseShapes ; all shapes
 bra :noShapes

:shapesThere
 jsr makePdp
 lda [3]
 sta ImpulseShapes
 killLdp

 do rele
 PushWord #3
 PushWord #rT2ModuleWord ;rtype for release
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseShapes;#temp ;rID
 _ReleaseResource
 fin

:noShapes
 rts

*=================================================
doSave = *

* brk $44
 ~GetCurResourceFile
 ~SetCurResourceFile RezFileID

 do 0
FPSCtlID = 1
DelayPopCtlID = 2
ShapePopCtlID = 3
MaxZoomCtlID = 8
 fin

* stz ImpulseFlag


 wr
 ~GetCtlHandleFromID WindPtr;#DelayPopCtlID
 _GetCtlValue
 pla
 xba
* ora ImpulseFlag
 sta ImpulseFlag


 wr
 ~GetCtlHandleFromID WindPtr;#FPSCtlID
 _GetCtlValue
 pla
 beq :fpsoff
 lda #fFPSCounter
 tsb ImpulseFlag

:fpsoff
 wr
 ~GetCtlHandleFromID WindPtr;#MaxZoomCtlID
 _GetCtlValue
 pla
 beq :bigoff
 lda #fBigShapes
 tsb ImpulseFlag

:bigoff


 ~RMLoadNamedResource #rT2ModuleWord;#rImpulseFlag
 bcc :flagFound
 plx
 plx


 lr
 PushLong #2
 ~GetCurResourceApp
* PushWord MyID
 PushWord #attrNoCross+attrNoSpec
 phd
 phd
 _NewHandle
 lda 1,s
 sta temp
 lda 1+2,s
 sta temp+2
 jsr makePdp
 lda ImpulseFlag
 sta [3]
 killLdp

 PushLong temp ; handle
 PushWord #attrNoSpec+attrNoCross ; attr
 PushWord #rT2ModuleWord ; rtype
 ~UniqueResourceID #$FFFF;#rT2ModuleWord ; rID
 lda 1,s
 sta temp
 lda 1+2,s
 sta temp+2
 _AddResource

 PushWord #rT2ModuleWord ; rType
 PushLong temp ; rID
 PushLong #rImpulseFlag ; ptr to name str
 _RMSetResourceName
 bra :created1

:flagFound
 jsr makePdp
 lda ImpulseFlag
 sta [3]
 killLdp

 PushWord #TRUE ; changeflag: true
 PushWord #rT2ModuleWord ; rtype
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseFlag;#temp ; rID
 _MarkResourceChange
* _WriteResource

:created1



 wr
 ~GetCtlHandleFromID WindPtr;#ShapePopCtlID
 _GetCtlValue
 pla
 sta ImpulseShapes

 ~RMLoadNamedResource #rT2ModuleWord;#rImpulseShapes
 bcc :shapesFound
 plx
 plx

 lr
 PushLong #2
* PushWord MyID
 ~GetCurResourceApp
 PushWord #attrNoCross+attrNoSpec
 phd
 phd
 _NewHandle
 lda 1,s
 sta temp
 lda 1+2,s
 sta temp+2
 jsr makePdp
 lda ImpulseShapes
 sta [3]
 killLdp

 PushLong temp ; handle
 PushWord #attrNoSpec+attrNoCross ; attr
 PushWord #rT2ModuleWord ; rtype
 ~UniqueResourceID #$FFFF;#rT2ModuleWord ; rID
 lda 1,s
 sta temp
 lda 1+2,s
 sta temp+2
 _AddResource

 PushWord #rT2ModuleWord ; rType
 PushLong temp ; rID
 PushLong #rImpulseShapes ; ptr to name str
 _RMSetResourceName
 bra :created2

:shapesFound
 jsr makePdp
 lda ImpulseShapes
 sta [3]
 killLdp

 PushWord #TRUE ; changeflag: true
 PushWord #rT2ModuleWord ; rtype
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseShapes;#temp ; rID
 _MarkResourceChange
* _WriteResource

:created2


 ~UpdateResourceFile RezFileID
 _SetCurResourceFile

 brl Bye
*=================================================
init_random = *

rtlAdr equ 1
targetStr equ rtlAdr+3

 lda targetStr+2,s
 tax
 lda targetStr,s

 PushWord #t2PrivGetProcs
 PushWord #stopAfterOne+sendToName
 phx
 pha
 PushLong #8
 PushLong #dataOut
 _SendRequest
 jsl set_random_seed

 lda 1,s
 sta 1+4,s
 lda 2,s
 sta 2+4,s
 plx
 plx
 rtl

dataOut
 ds 2
set_random_seed = *
 rtl
 ds 3
random = *
 rtl
 ds 3
*=================================================
New_Curve = *

 lda ImpulseShapes
 cmp #3
 blt :special
 sec
 sbc #3
:go asl
 tax
 lda Curve_Table,x
 sta Curve_Adr
 jsr Get_Curve ; read/act on shape header
 jsr Setup_3d
 rts

:special
* cmp #2
* beq :random
:all ; shape = 1 = all

:random  ; shape = 2 = random

 jsr do_rnd
 bra :go

do_rnd = *

:findNew
 lr
 jsl random
 pha
 pea 16+1 ; number of shapes
 _UDivide
 plx
 pla  ; remainder
* inc a
 cmp Cur_Curve
 beq :findNew
 sta Cur_Curve
 rts
*=================================================
* ErrorMaker.. get the appropriate error string into a
* format acceptable by T2.
*
* Accumulator:
* error 1 = Not enough memory.
* error 2 = Shadow screen not available.
*
* Y Register: error code
*
ErrorMaker = *

 dec  ;make that 0 through 1
 asl
 tax
 phx ;save this for a moment

 lr
 phy
 _HexIt
 pla
 sta error1
 pla
 sta error1+2

 lda 1,s
 tax

 lr
 pea 0
 lda Errorlengths,x ;size
 pha
 lda MyID
 ora #$0F00
 pha ;memory ID
 PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
 phd
 phd
 _NewHandle
 PullLong ErrorHand

 plx
 pea #^Errors
 lda Errors,x
 pha ;pointer
 PushLong ErrorHand ;handle
 pea 0
 lda Errorlengths,x
 pha  ;size
 _PtrToHand  ;copy the string into the handle

 lda ErrorHand
 sta T2Result,s
 lda ErrorHand+2
 sta T2Result+2,s

 brl return

* errors that can be returned

ErrorHand adrl 0

Errors da memoryErr
 da screenErr

Errorlengths
 da screenErr-memoryErr
 da endoferrors-screenErr

memoryErr asc 'Impulse 3-D Fatal Memory Error: $'
error1 asc '????'0D
 asc 'Could not allocate 192k continuous free memory.'00
screenErr asc 'Impulse 3-D Fatal Shadow Error:'0D
 asc 'Shadow screen unavailable.  Try again later.'00
endoferrors

**************************************************
 put makepdp.asm
 SAV impulse.l


 do 0
*-------------------------------------------------

New_Curve = *
 lda Cur_Curve
 asl
 tax
 lda Curve_Table,x
 bne not_end
 stz Cur_Curve
 bra New_Curve
not_end sta Curve_Adr
 jsr Get_Curve ; read/act on shape header
 jsr Setup_3d
 rts

*-------------------------------------------------
 fin
