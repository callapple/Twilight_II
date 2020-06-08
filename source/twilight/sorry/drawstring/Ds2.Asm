
               mcopy DS2.Mac
               copy  DS2.Equ
*-----------------------------------------------------------------------------*
CLOCKCTL       gequ  $E0C034            clock control register

rC1InputString gequ  $8005
rConfiguration gequ  $0001
*-----------------------------------------------------------------------------*
DrawString     Start

               phb
               phk
               plb
               phd
               pha                      ; local space!
               pha
               tsc
               tcd

               DefineStack
TempDP         long                     ; temporary local space
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
ourPathname    long

               lda   MasterID,s
               ora   #$0A00
               sta   MyID

               lda   ourPathname,s
               sta   OurPath
               lda   ourPathname+2,s
               sta   OurPath+2

               LongResult               ; Set random seed
               LongResult
               _ReadTimeHex
               _SetRandSeed
               pla
               pla

               WordResult
               _GetCurResourceApp
               PullWord OldResourceApp

               WordResult
               _GetCurResourceFile
               PullWord OldResourceFile

               PushWord MyID
               _ResourceStartUp

*               PushWord MyID
*               _SetCurResourceApp

               WordResult
               PushWord #1              request read access
               PushLong #0              open a new file
               PushLong OurPath
               _OpenResourceFile
               plx
               stx   ResFileID
*               jcs   Error

               LongResult
               PushWord #rConfiguration
               PushLong #DelayRez
               _LoadResource
               makePdp
               lda   [3]
               sta   DelayTime
               killLdp

               LongResult
               PushWord #rC1InputString
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempDP
               plx
               stx   TempDP+2
*               jcs   error
               ldy   #2
               lda   [TempDP]
               tax
               lda   [TempDP],y
               sta   TempDP+2
               stx   TempDP

               lda   [TempDP]           ; make C1 string into a P-String
               xba
               sta   [TempDP]
               inc   TempDP

               lda   >CLOCKCTL
               and   #$000F
               sta   OldBorder
               lda   >CLOCKCTL
               and   #$FFF0
               sta   >CLOCKCTL

               lda   #$0000
               ldx   #$7D00-2
zero           sta   >$E12000,x
               dex
               dex
               bpl   zero

               lda   #640
               sta   Mode
               WordResult
               _GetMasterSCB
               pla
               sta   MasterSCB
               xba
               cmp   #$8000
               bge   ModeOK             bge
               lda   #320
               sta   Mode
ModeOK         anop

               PushWord #0
               PushWord #0
               _MoveTo
               pei   TempDP+2
               pei   TempDP
               PushLong #R_top
               _StringBounds
               LongResult
               _GetPort
               PullLong OldPort
               PushLong #OurPort
               _OpenPort
               PushLong #OurPort
               _SetPort
               PushLong #MyPortLoc
               _SetPortLoc
               PushWord #0
               _SetBackColor
               PushWord #$F
               _SetForeColor
               PushWord #0
               _SetSolidPenPat

loop           anop
               lda   R_top
               clc
               adc   horiz
               sta   r2_top
               lda   R_left
               clc
               adc   vert
               sta   r2_left
               lda   R_Bottom
               clc
               adc   horiz
               sta   r2_bottom
               lda   R_Right
               clc
               adc   vert
               sta   r2_right
               PushLong #r2_top
               _PaintRect

               WordResult
               WordResult
               WordResult
               _Random
               PushWord Mode
               _UDivide
               pla
               pla
               sta   vert

               WordResult
               WordResult
               WordResult
               _Random
               PushWord #199
               _UDivide
               pla
               pla
               sta   horiz

               PushWord vert
               PushWord horiz
               _MoveTo
               pei   TempDP+2
               pei   TempDP
               _DrawString

               ldy   DelayTime
d_loop         shortm
v1             lda   $E0C019
               bmi   v1
v2             lda   $E0C019
               bpl   v2
               longm
               lda   [MovePtr]
               bne   Exit
               dey
               bne   d_loop
               brl   loop

Exit           anop
               PushLong OldPort
               _SetPort
               PushLong #OurPort
               _ClosePort

               PushWord #3              ; purge level 3
               PushWord #rC1InputString
               PushLong #$00000001
               _ReleaseResource

               PushWord ResFileID
               _CloseResourceFile

               _ResourceShutDown

               PushWord OldResourceFile
               _SetCurResourceFile

               PushWord OldResourceApp
               _SetCurResourceApp

               PushWord MyID
               _DisposeAll

               lda   >CLOCKCTL          clock control register
               and   #$FFF0
               ora   OldBorder
               sta   >CLOCKCTL          clock control register

               pla                      ; kill locals
               pla
               pld
               plb

               lda   2,s
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs
               clc
               rtl

r2_top         ds    2
r2_left        ds    2
r2_bottom      ds    2
r2_right       ds    2

R_top          ds    2
R_left         ds    2
R_Bottom       ds    2
R_Right        ds    2

vert           ds    2
horiz          ds    2

OldBorder      ds    2
MyID           ds    2
OldPort        ds    4
OurPort        ds    $AA

MyPortLoc      anop
MasterSCB      ds    2                  ; portSCB
               dc    i4'$E12000'        ; ptrToPixImage
               dc    i'$A0'             ; byteWidth of each line in image
bounds         dc    i'0,0'             ; boundary rectangle
               dc    i'200'
Mode           ds    2

OurPath        ds    4
ResFileID      ds    2
OldResourceApp ds    2
OldResourceFile ds   2
DelayTime      ds    2

               End
*-----------------------------------------------------------------------------*