
               mcopy DS.Mac
*-----------------------------------------------------------------------------*
CLOCKCTL       gequ  $E0C034            clock control register
*-----------------------------------------------------------------------------*
DrawString     Start

               phb
               phk
               plb
               phd
               tsc
               tcd
               pha                      ; local space!
               pha

               DefineStack
TempDP         long                     ; temporary local space
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

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
               pei   TextPtr+2
               pei   TextPtr
               PushLong #R_top
               _StringBounds
               LongResult
               _GetPort
               PushLong #OurPort
               _OpenPort
               PushLong #OurPort
               _SetPort
               PushLong #MasterSCB
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
               pei   TextPtr+2
               pei   TextPtr
               _DrawString

               ldx   #$0004
more_delay     ldy   #$FFFF
delay          dey
               lda   [MovePtr]
               bne   Exit
               cpy   #$0000
               bne   delay
               dex
               bne   more_delay
               brl   loop

Exit           anop
               _SetPort
               PushLong #OurPort
               _ClosePort

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

Mode           ds    2
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

OurPort        ds    $AA
MasterSCB      ds    2
               dc    i4'$00E12000'
               dc    i2'$00A0'
               dc    i4'$00000000'
               dc    i2'$00C8'

               End
*-----------------------------------------------------------------------------*