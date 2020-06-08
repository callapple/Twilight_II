
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
MovePtr ds 4
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

 ~MMStartUp
 pla
 ora #$0100
 sta MyID


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
:skip lda [MovePtr]
 BNEL return
 BRL TOP ; next frame!

*=================================================
*-------------------------------------------------
* HLine - FTA's famous line routine.
*
* DO NOT DISTRIBUTE!!!!!!!!!!!!!!!!!!!!!!!!!!
*
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

 lda T2data1+2,s
 sta WindPtr+2
 lda T2data1,s
 sta WindPtr
 lda T2data2,s
 sta RezFileID
 ~MMStartUp
 pla
 sta MyID

 ~NewControl2 WindPtr;#resourceToResource;#CtlLst
 plx
 plx

* Make sure we're dealing with the T2pref file.

 ~GetCurResourceFile
 ~SetCurResourceFile RezFileID

 jsr load_setup

:noShapes
:moveon _SetCurResourceFile

 lda ImpulseFlag
 and #fFPSCounter ; fps off/on
 pha
 ~GetCtlHandleFromID WindPtr;#FPSCtlID
 _SetCtlValue

 lda ImpulseFlag
 and #fBigShapes ; large shapes off/on
 lsr
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
*=================================================
doLoadSetup = *

 jsr load_setup
 brl Bye

load_setup = *

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

 PushWord #3
 PushWord #rT2ModuleWord ;rtype for release
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseFlag;#temp ;rID
 _ReleaseResource

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

 PushWord #3
 PushWord #rT2ModuleWord ;rtype for release
 ~RMFindNamedResource #rT2ModuleWord;#rImpulseShapes;#temp ;rID
 _ReleaseResource

:noShapes
 rts

*=================================================
doSave = *

 ~GetCurResourceFile
 ~SetCurResourceFile RezFileID


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
 ~GetCtlHandleFromID WindPtr;#ShapePopCtlID
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

:created2


 ~UpdateResourceFile RezFileID
 _SetCurResourceFile

 brl Bye
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
