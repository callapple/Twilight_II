
               msb off
               longa on
               longi on
               absaddr on
               mcopy power.mac
               mcopy 7/m16.msc
               mcopy 7/m16.util2
               mcopy 7/m16.quickdraw
*-----------------------------------------------------------------------------*
Letter         gequ  <0
Position       gequ  Letter+4
Stage          gequ  Position+2
lines          gequ  Stage+2
MasterID       gequ  lines+2
MyID           gequ  MasterID+2
twice          gequ  MyID+2
Speed          gequ  twice+2
bordercol      gequ  speed+2

topline        gequ  91
topline1       gequ  topline+1
topline2       gequ  topline1+1
topline3       gequ  topline2+1
topline4       gequ  topline3+1
topline5       gequ  topline4+1
topline6       gequ  topline5+1
topline7       gequ  topline6+1
topline8       gequ  topline7+1
topline9       gequ  topline8+1
topline10      gequ  topline9+1
topline11      gequ  topline10+1
topline12      gequ  topline11+1
topline13      gequ  topline12+1
topline14      gequ  topline13+1
topline15      gequ  topline14+1
topline16      gequ  topline15+1
topline18      gequ  topLine16+2

shrb           gequ  $E1E1
NewVideo       gequ  $E0C029
SHR            gequ  $E12000
SCBs           gequ  $E19D00
Palette0       gequ  $E19E00
Palette1       gequ  $E19E20
Gun            gequ  $E0C02E
Border         gequ  $E0C034
VBLWait        gequ  $E0C019            bit 7 = 1 if not VBL
CLRAN0         gequ  $C059              set annunciator 0
SETAN1         gequ  $C05A              clear annunciator 1
SETAN2         gequ  $C05C              clear annunciator 2
CLRAN2         gequ  $C05D              set annunciator 2
*-----------------------------------------------------------------------------*
PowerDemo      Start
               Using FontDATA

               case  off
               phb
               phk
               plb

*               brl   beginIt
*
*               dc    c'  Twilight PowerScroll Module 1.0.  '
*               dc    c'  January 19, 1991.  This module and all modules and '
*               dc    c'all other files distributed with Twilight 2.0 with the '
*               dc    c'exception of ColorStrobe are copyrighted 1991 by Jim '
*               dc    c'Maricondo and Jonah Stich.  All rights reserved.  '

beginIt        anop
*               LongResult
*               _GetPort
*               PullLong orgPort
*
*               PushLong #MyPort         Open a new grafPort
*               _OpenPort
*
*               PushLong #MyPortLoc      make it point to our memory
*               _SetPortLoc
*
*               PushLong #bounds
*               _SetPortRect
*
               shortm
               lda   #$C1               turn on/linearize SHR
               sta   >NewVideo
               longm

               shortm
               lda  >Border             save old border color and make border
               pha                       color now black
               and  #$0F
               sta  bordercol
               pla
               and  #$F0
               sta  >Border
               longm

               ldx   #$8000-2           zero shr display buffer
               lda   #0
zeroSHR        sta   >SHR,x
               dex
               dex
               bpl   zeroSHR

*               ldx   #0
*               txa
*scb2           sta   >SCBs,x
*               inx
*               inx
*               cpx   #144
*               blt   scb2

*               ldx   #0
*               lda   #$8181
*scb3           sta   >SCBs+144,x
*               inx
*               inx
*               cpx   #54
*               blt   scb3

*               lda   #$0000
*               sta   >Palette1

               ldx   #$20-2
palette        lda   PowerFontPal,x
               sta   >Palette0,x
               dex
               dex
               bpl   palette

*               PushWord #15             foreground color of text: white
*               _SetForeColor
*               PushWord #0              background color: black
*               _SetBackColor
*
*               PushWord #20             horizontal (x)
*               PushWord #160-6          vertical (y)
*               _MoveTo
*               PushLong #NameStr
*               _DrawString
*
*               PushWord #20             horizontal (x)
*               PushWord #169-6          vertical (y)
*               _MoveTo
*               PushLong #NameStr2
*               _DrawString

               DefineStack
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

               phd                      Right here we're doing several things..
               tsc                      First we're checking if the first 2
               tcd                       letters of the scroll text are "@@".
               lda   [TextPtr]           If they are, then we set flags to tell
               and   #$00FF              our draw and scroll routines to scroll
               sta   |length             slow.
               stz   noZIP
               stz   slowflag           Then we're getting the length byte of
               ldy   #1                  the pascal string of text that was
               lda   [TextPtr],y         passed to us.  We store it as the
               and   #$7F7F              length of the string for later use.
               msb   off                Lastly, we're taking the address of the
               cmp   #'%%'               textedit pascal string+1 and storing
               bne   noSlow              it directly to the operand field of a
               sta   slowflag            lda >Long opcode.  This way we can use
               lda   TextPtr,s
               inc   a                  add 1 to skip over length byte
               inc   a                  add 1 more to skip over %
               inc   a                  add 1 more to skip over %
               bra   noSlow2
noSlow         anop
               lda   TextPtr,s           >long,x addressing instead of [dp],y.
               inc   a                   [We're adding 1 to it to skip over the
noSlow2        sta   FillStr1+1           length byte at the beginning of it]
               sta   FillStr2+1
               sta   FillStr3+1
               lda   TextPtr+2,s
               sta   FillStr1+3
               sta   FillStr2+3
               sta   FillStr3+3
               shortm
               lda   #$EA
               sta   FillStr1+4
               sta   FillStr2+4
               sta   FillStr3+4
               longm
               pld

               stz   Speed              Here we're just initializing variables
               lda   slowFlag            and setting speed based on the first
               beq   fastok              speed flag set up above.
               sta   speed
fastok         anop
               stz   Stage
               stz   Position
               lda   #^No
               sta   Letter+2
               lda   #No
               sta   Letter

*               lda   >$BCFF00          check for TWGS
*               cmp   #$5754             cmp #"TW"
*               bne   speed_ok           no twgs
*               lda   >$BCFF02
*               cmp   #$5347             cmp #"GS"
*               bne   speed_ok           no twgs
*               lda   #-1
*               sta   noZIP
*speed_ok       anop
*
*CheckZip       anop
**               ldy   #$0000
**FindZip        lda   FindZip,y
**               dey
**               bne   FindZip
*               php                      THIS ROUTINE CHECKS FOR PRESENCE OF A
*               shortm                   ZIPGS
*               lda   #$5A
*               sta   >SETAN1            clear annunciator 1
*               sta   >SETAN1            clear annunciator 1
*               sta   >SETAN1            clear annunciator 1
*               sta   >SETAN1            clear annunciator 1
*               lda   >CLRAN0            set annunciator 0
*               eor   #$F8
*               sta   Temp1
*               sta   >CLRAN0            set annunciator 0
*               lda   >CLRAN0            set annunciator 0
*               cmp   Temp1
*               bne   noZip01
*               eor   #$F8
*               sta   >CLRAN0            set annunciator 0
*               lda   #$A5
*               sta   >SETAN1            clear annunciator 1
*               longm
*               lda   #-1
*               sta   noZip
*noZip01        plp
*
**               lda   noZIP
**               beq   skipZIP
**               shortm
**               lda   >$E0C036
**               and   #$7F
**               sta   >$E0C036
**               longm
**
**skipzip        anop
               phd
GetChar        anop
               pld

*               ldx   TabOffset          This is our color cycle routine.  It
*               cpx   #EndTab-ColTab      cycles the credits. :)
*               blt   ok
*               stz   TabOffset
*               ldx   #0
*ok             anop
*               lda   ColTab,x
*               sta   >Palette1+$6
*               sta   >Palette1+$E
*               sta   >Palette1+$16
*               sta   >Palette1+$1E
*               inc   TabOffset
*               inc   TabOffset

*               lda   noZIP
*               beq   skipZIP

*               shortm
*waitVBL        lda   >VBLWait
*               bmi   waitVBL
*wait2          lda   >VBLWait
*               bpl   wait2
*               longm
*               bra   SkipGUN

skipZIP        anop
               shortm
wait           lda   >Gun               We wait for the electron gun to be
               cmp   #(topline/2)+$80 ;was tl18 refreshing the line below the last
               bne   wait      ; was blt;  line of our scroll before we start
               longm                     redrawing, so the drawing won't tear.

skipGUN        jsr   Scroll             Scroll over our text!

CheckOther     anop                     Now check if a key was pressed, etc.
               phd
               tsc
               tcd
               lda   [MovePtr]
               beq   GetChar

               pld                      If so, quit.

*               lda   noZIP
*               beq   skipZIP2
*               shortm
*               lda   >$E0C036
*               ora   #$80
*               sta   >$E0C036
*               longm
*
*skipzip2       anop
               PushLong orgPort
               _SetPort                 restore original port

               shortm                   restore users border color
               lda  >Border
               and  #$F0
               ora  bordercol
               sta  >Border
               longmx

               plb
               lda   2,s                Move up RTL on stack..
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs
               clc
               rtl

Temp1          ds    2
noZip          ds    2

               End
*-----------------------------------------------------------------------------*
DrawNextStep   Start
               Using FontDATA

               lda   Speed              Check if speed flag says to go fast
               jeq   FAST                or slow.

SLOW           anop
               lda   Stage
               beq   Stage0_slow
               cmp   #1
               beq   Stage1_slow
               cmp   #2
               beq   Stage2_slow
               cmp   #3
               beq   Stage3_slow

Stage4_slow    anop
               ldy   #4*2               Draw last 1/4th of this letter.
               jsr   drawUpdate
               stz   Stage              Start at beginning of next letter.
               inc   Position           Move one letter over.
               rts

Stage0_slow    anop
               lda   length
               cmp   Position
               bge   contHere
               stz   Position
contHere       ldx   Position
fillStr1       entry
               lda   >String,x
               nop
               and   #$007F
               cmp   #$20
               bge   OkVar1
               inc   Position
               bra   stage0_slow

okVar1         anop
               cmp   #$7F
               blt   OkVar2
               inc   Position
               bra   stage0_slow

okVar2         anop
               sec
               sbc   #$20
               asl   a
               tax
               lda   LetterAddrTab,x
               sta   Letter

               ldy   #0*2
               jsr   drawUpdate
               lda   #1
               sta   Stage
               rts

Stage1_slow    anop
               ldy   #1*2
               jsr   drawUpdate
               lda   #2
               sta   Stage
               rts

Stage2_slow    anop
               ldy   #2*2
               jsr   drawUpdate
               lda   #3
               sta   Stage
               rts

Stage3_slow    anop
               ldy   #3*2
               jsr   drawUpdate
               lda   #4
               sta   Stage
               rts

DrawUpdate     anop
               lda   #17                # of lines of each character
               sta   lines
               ldx   #0
s4_loop_slow   lda   [Letter],y
               sta   >(topLine*$A0)+SHR+$8E,x
               tya
               clc
               adc   #10                width in bytes of each character
               tay
               txa
               clc
               adc   #$A0               length in bytes of a SHR line
               tax
               dec   lines
               bne   s4_loop_slow
               rts



FAST           anop
               lda   Stage
               beq   Stage0
               cmp   #1
               beq   Stage1
               cmp   #2
               beq   Stage2
               cmp   #3
               beq   Stage3

Stage4         anop
               ldy   #6                 Draw last 1/6th of this pair of letters.
               jsr   DrawLong
               stz   Stage              Start at beginning of next letter.
               inc   Position           Move one letter over.
               rts


Stage0         anop               
               lda   length
               cmp   Position
               bge   contHere2
               stz   Position
contHere2      ldx   Position
fillStr2       entry
               lda   >String,x
               nop
               and   #$007F
               cmp   #$20
               bge   OkVar3
               inc   Position
               bra   stage0

okVar3         anop
               cmp   #$7F
               blt   OkVar4
               inc   Position
               bra   stage0

okVar4         anop
               sec
               sbc   #$20
               asl   a
               tax
               lda   LetterAddrTab,x
               sta   Letter

               ldy   #0
               jsr   DrawLong
               lda   #1
               sta   Stage
               rts


Stage1         anop
               ldy   #4
               jsr   DrawLong
               lda   #2
               sta   Stage
               rts


Stage3         anop
               ldy   #2
               jsr   DrawLong
               lda   #4
               sta   Stage
               rts


Stage2         anop
               ldy   #8
               lda   #17                # of lines of each character
               sta   lines
               ldx   #0
s6_loop        lda   [Letter],y
               sta   >(topline*$A0)+SHR+$8C,x
               tya
               clc
               adc   #10                width in bytes of each character
               tay
               txa
               clc
               adc   #$A0               length in bytes of a SHR line
               tax
               dec   lines
               bne   s6_loop

               inc   Position
loooop         anop
               lda   length
               cmp   Position
               bge   contHere3          ;bne
               stz   Position
contHere3      ldx   position
fillStr3       entry
               lda   >String,x
               nop
               and   #$007F
               cmp   #$20
               bge   OkVar5
               inc   Position
               bra   loooop

okVar5         anop
               cmp   #$7F
               blt   OkVar6
               inc   Position
               bra   loooop

okVar6         anop
               sec
               sbc   #$20
               asl   a
               tax
               lda   LetterAddrTab,x
               sta   Letter

               ldy   #0
               lda   #17                # of lines of each character
               sta   lines
               ldx   #0
s7_loop        lda   [Letter],y
               sta   >(topline*$A0)+SHR+$8E,x
               tya
               clc
               adc   #10                width in bytes of each character
               tay
               txa
               clc
               adc   #$A0               length in bytes of a SHR line
               tax
               dec   lines
               bne   s7_loop

               lda   #3
               sta   Stage
               rts


DrawLong       anop
               lda   #17                # of lines of each character
               sta   lines
               ldx   #0
s4_loop        lda   #2
               sta   twice
s5_loop        lda   [Letter],y
               sta   >(topLine*$A0)+SHR+$8C,x
               iny
               iny
               inx
               inx
               dec   twice
               bne   s5_loop
               tya
               clc
               adc   #10-4              width in bytes of each character
               tay
               txa
               clc
               adc   #$A0-4             length in bytes of a SHR line
               tax
               dec   lines
               bne   s4_loop
               rts

               End
*-----------------------------------------------------------------------------*
Scroll         Start
               Using FontDATA

               pea   SHRb
               plb
               plb

               lda   Speed
               bne   SLOW_Scroll

               ldx   #(topline*$A0)+16       1
               jsr   ScrollIt
               ldx   #(topline1*$A0)+16      2
               jsr   ScrollIt
               ldx   #(topline2*$A0)+16      3
               jsr   ScrollIt
               ldx   #(topline3*$A0)+16      4
               jsr   ScrollIt
               ldx   #(topline4*$A0)+16      5
               jsr   ScrollIt
               ldx   #(topline5*$A0)+16      6
               jsr   ScrollIt
               ldx   #(topline6*$A0)+16      7
               jsr   ScrollIt
               ldx   #(topline7*$A0)+16      8
               jsr   ScrollIt
               ldx   #(topline8*$A0)+16      9
               jsr   ScrollIt
               ldx   #(topline9*$A0)+16      10
               jsr   ScrollIt
               ldx   #(topline10*$A0)+16     11
               jsr   ScrollIt
               ldx   #(topline11*$A0)+16     12
               jsr   ScrollIt
               ldx   #(topline12*$A0)+16     13
               jsr   ScrollIt
               ldx   #(topline13*$A0)+16     14
               jsr   ScrollIt
               ldx   #(topline14*$A0)+16     15
               jsr   ScrollIt
               ldx   #(topline15*$A0)+16     16
               jsr   ScrollIt
               ldx   #(topline16*$A0)+16     17
               jsr   ScrollIt

               phk
               plb
               jsr   DrawNextStep
               rts


SLOW_Scroll    anop
               ldx   #(topline*$A0)+16       1
               jsr   ScrollItSlow
               ldx   #(topline1*$A0)+16      2
               jsr   ScrollItSlow
               ldx   #(topline2*$A0)+16      3
               jsr   ScrollItSlow
               ldx   #(topline3*$A0)+16      4
               jsr   ScrollItSlow
               ldx   #(topline4*$A0)+16      5
               jsr   ScrollItSlow
               ldx   #(topline5*$A0)+16      6
               jsr   ScrollItSlow
               ldx   #(topline6*$A0)+16      7
               jsr   ScrollItSlow
               ldx   #(topline7*$A0)+16      8
               jsr   ScrollItSlow
               ldx   #(topline8*$A0)+16      9
               jsr   ScrollItSlow
               ldx   #(topline9*$A0)+16      10
               jsr   ScrollItSlow
               ldx   #(topline10*$A0)+16     11
               jsr   ScrollItSlow
               ldx   #(topline11*$A0)+16     12
               jsr   ScrollItSlow
               ldx   #(topline12*$A0)+16     13
               jsr   ScrollItSlow
               ldx   #(topline13*$A0)+16     14
               jsr   ScrollItSlow
               ldx   #(topline14*$A0)+16     15
               jsr   ScrollItSlow
               ldx   #(topline15*$A0)+16     16
               jsr   ScrollItSlow
               ldx   #(topline16*$A0)+16     17
               jsr   ScrollItSlow

               phk
               plb
               jsr   DrawNextStep
               rts


ScrollIt       anop
               lda   |$2000,x
               sta   |$2000-4,x

               lda   |$2002,x
               sta   |$2000-2,x
               lda   |$2004,x
               sta   |$2002-2,x
               lda   |$2006,x
               sta   |$2004-2,x
               lda   |$2008,x
               sta   |$2006-2,x
               lda   |$200A,x
               sta   |$2008-2,x
               lda   |$200C,x
               sta   |$200A-2,x
               lda   |$200E,x
               sta   |$200C-2,x
               lda   |$2010,x
               sta   |$200E-2,x

               lda   |$2012,x
               sta   |$2010-2,x
               lda   |$2014,x
               sta   |$2012-2,x
               lda   |$2016,x
               sta   |$2014-2,x
               lda   |$2018,x
               sta   |$2016-2,x
               lda   |$201A,x
               sta   |$2018-2,x
               lda   |$201C,x
               sta   |$201A-2,x
               lda   |$201E,x
               sta   |$201C-2,x
               lda   |$2020,x
               sta   |$201E-2,x

               lda   |$2022,x
               sta   |$2020-2,x
               lda   |$2024,x
               sta   |$2022-2,x
               lda   |$2026,x
               sta   |$2024-2,x
               lda   |$2028,x
               sta   |$2026-2,x
               lda   |$202A,x
               sta   |$2028-2,x
               lda   |$202C,x
               sta   |$202A-2,x
               lda   |$202E,x
               sta   |$202C-2,x
               lda   |$2030,x
               sta   |$202E-2,x

               lda   |$2032,x
               sta   |$2030-2,x
               lda   |$2034,x
               sta   |$2032-2,x
               lda   |$2036,x
               sta   |$2034-2,x
               lda   |$2038,x
               sta   |$2036-2,x
               lda   |$203A,x
               sta   |$2038-2,x
               lda   |$203C,x
               sta   |$203A-2,x
               lda   |$203E,x
               sta   |$203C-2,x
               lda   |$2040,x
               sta   |$203E-2,x

               lda   |$2042,x
               sta   |$2040-2,x
               lda   |$2044,x
               sta   |$2042-2,x
               lda   |$2046,x
               sta   |$2044-2,x
               lda   |$2048,x
               sta   |$2046-2,x
               lda   |$204A,x
               sta   |$2048-2,x
               lda   |$204C,x
               sta   |$204A-2,x
               lda   |$204E,x
               sta   |$204C-2,x
               lda   |$2050,x
               sta   |$204E-2,x

               lda   |$2052,x
               sta   |$2050-2,x
               lda   |$2054,x
               sta   |$2052-2,x
               lda   |$2056,x
               sta   |$2054-2,x
               lda   |$2058,x
               sta   |$2056-2,x
               lda   |$205A,x
               sta   |$2058-2,x
               lda   |$205C,x
               sta   |$205A-2,x
               lda   |$205E,x
               sta   |$205C-2,x
               lda   |$2060,x
               sta   |$205E-2,x

               lda   |$2062,x
               sta   |$2060-2,x
               lda   |$2064,x
               sta   |$2062-2,x
               lda   |$2066,x
               sta   |$2064-2,x
               lda   |$2068,x
               sta   |$2066-2,x
               lda   |$206A,x
               sta   |$2068-2,x
               lda   |$206C,x
               sta   |$206A-2,x
               lda   |$206E,x
               sta   |$206C-2,x


               lda   |$2070,x
               sta   |$206E-2,x
               lda   |$2072,x
               sta   |$2070-2,x
               lda   |$2074,x
               sta   |$2072-2,x
               lda   |$2076,x
               sta   |$2074-2,x
               lda   |$2078,x
               sta   |$2076-2,x
               lda   |$207A,x
               sta   |$2078-2,x
               lda   |$207C,x
               sta   |$207A-2,x
               lda   |$207E,x
               sta   |$207C-2,x
               rts


ScrollItSlow   anop
               lda   |$2000-2,x
               sta   |$2000-4,x
               lda   |$2000,x
               sta   |$2000-2,x

               lda   |$2002,x
               sta   |$2000,x
               lda   |$2004,x
               sta   |$2002,x
               lda   |$2006,x
               sta   |$2004,x
               lda   |$2008,x
               sta   |$2006,x
               lda   |$200A,x
               sta   |$2008,x
               lda   |$200C,x
               sta   |$200A,x
               lda   |$200E,x
               sta   |$200C,x
               lda   |$2010,x
               sta   |$200E,x

               lda   |$2012,x
               sta   |$2010,x
               lda   |$2014,x
               sta   |$2012,x
               lda   |$2016,x
               sta   |$2014,x
               lda   |$2018,x
               sta   |$2016,x
               lda   |$201A,x
               sta   |$2018,x
               lda   |$201C,x
               sta   |$201A,x
               lda   |$201E,x
               sta   |$201C,x
               lda   |$2020,x
               sta   |$201E,x

               lda   |$2022,x
               sta   |$2020,x
               lda   |$2024,x
               sta   |$2022,x
               lda   |$2026,x
               sta   |$2024,x
               lda   |$2028,x
               sta   |$2026,x
               lda   |$202A,x
               sta   |$2028,x
               lda   |$202C,x
               sta   |$202A,x
               lda   |$202E,x
               sta   |$202C,x
               lda   |$2030,x
               sta   |$202E,x

               lda   |$2032,x
               sta   |$2030,x
               lda   |$2034,x
               sta   |$2032,x
               lda   |$2036,x
               sta   |$2034,x
               lda   |$2038,x
               sta   |$2036,x
               lda   |$203A,x
               sta   |$2038,x
               lda   |$203C,x
               sta   |$203A,x
               lda   |$203E,x
               sta   |$203C,x
               lda   |$2040,x
               sta   |$203E,x

               lda   |$2042,x
               sta   |$2040,x
               lda   |$2044,x
               sta   |$2042,x
               lda   |$2046,x
               sta   |$2044,x
               lda   |$2048,x
               sta   |$2046,x
               lda   |$204A,x
               sta   |$2048,x
               lda   |$204C,x
               sta   |$204A,x
               lda   |$204E,x
               sta   |$204C,x
               lda   |$2050,x
               sta   |$204E,x

               lda   |$2052,x
               sta   |$2050,x
               lda   |$2054,x
               sta   |$2052,x
               lda   |$2056,x
               sta   |$2054,x
               lda   |$2058,x
               sta   |$2056,x
               lda   |$205A,x
               sta   |$2058,x
               lda   |$205C,x
               sta   |$205A,x
               lda   |$205E,x
               sta   |$205C,x
               lda   |$2060,x
               sta   |$205E,x

               lda   |$2062,x
               sta   |$2060,x
               lda   |$2064,x
               sta   |$2062,x
               lda   |$2066,x
               sta   |$2064,x
               lda   |$2068,x
               sta   |$2066,x
               lda   |$206A,x
               sta   |$2068,x
               lda   |$206C,x
               sta   |$206A,x
               lda   |$206E,x
               sta   |$206C,x
               lda   |$2070,x
               sta   |$206E,x

               lda   |$2072,x
               sta   |$2070,x
               lda   |$2074,x
               sta   |$2072,x
               lda   |$2076,x
               sta   |$2074,x
               lda   |$2078,x
               sta   |$2076,x
               lda   |$207A,x
               sta   |$2078,x
               lda   |$207C,x
               sta   |$207A,x
               lda   |$207E,x
               sta   |$207C,x
               rts

               End
*-----------------------------------------------------------------------------*
FontDATA       Data

*ColTab         anop
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$111,$111,$111'
*               dc    i'$222,$222,$222'
*               dc    i'$333,$333,$333'
*               dc    i'$444,$444,$444'
*               dc    i'$555,$555,$555'
*               dc    i'$666,$666,$666'
*               dc    i'$777,$777,$777'
*               dc    i'$888,$888,$888'
*               dc    i'$999,$999,$999'
*               dc    i'$aaa,$aaa,$aaa'
*               dc    i'$bbb,$bbb,$bbb'
*               dc    i'$ccc,$ccc,$ccc'
*               dc    i'$ddd,$ddd,$ddd'
*               dc    i'$eee,$eee,$eee'
*               dc    i'$fff,$fff,$fff'
*               dc    i'$eee,$eee,$eee'
*               dc    i'$ddd,$ddd,$ddd'
*               dc    i'$ccc,$ccc,$ccc'
*               dc    i'$bbb,$bbb,$bbb'
*               dc    i'$aaa,$aaa,$aaa'
*               dc    i'$999,$999,$999'
*               dc    i'$888,$888,$888'
*               dc    i'$777,$777,$777'
*               dc    i'$666,$666,$666'
*               dc    i'$555,$555,$555'
*               dc    i'$444,$444,$444'
*               dc    i'$333,$333,$333'
*               dc    i'$222,$222,$222'
*               dc    i'$111,$111,$111'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*               dc    i'$0000,$0000,$0000,$0000,$0000,$0000,$0,$0,$0,$0'
*EndTab         anop

String         anop

LetterAddrTab  anop
               dc    a'lspace,lexp,no,no,no,no,no,lapos,lshift9,lshift0,no,no'
               dc    a'lcom,ldash,lper,lslash'
               dc    a'l0,l1,l2,l3,l4,l5,l6,l7,l8,l9,lcol,lscol,no,no,no'
               dc    a'lquest,no,la'
               dc    a'lb,lc,ld,le,lf,lg,lh,li,lj,lk,ll,lm,ln,lo,lp,lq,lr,ls'
               dc    a'lt,lu,lv,lw,lx,ly,lz,no,lslash2'
               dc    a'no,no,no,no,la,lb,lc,ld,le,lf,lg,lh,li,lj,lk,ll,lm,ln'
               dc    a'lo,lp,lq,lr,ls,lt,lu,lv,lw,lx,ly,lz,no,no,no,no'

*               c' !"#$%&'()*+,-./'
*               c'0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\'
*               c']^_`abcdefghijklmnopqrstuvwxyz{|}~'

PowerFontPal   anop
               dc    h'0000 0500 0700 0a00 0c00 0f00'
               dc    h'f00f 0004 0008 0009 000a 000b'
               dc    h'000c 000d 000e 000f'

no             anop
lspace         anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'

lshift9             ANOP
                    dc h'00000001255555500000'
                    dc h'00000025500000400000'
                    dc h'00000250000000400000'
                    dc h'00001500000000400000'
                    dc h'00002500000144400000'
                    dc h'00005000014400000000'
                    dc h'00005000040000000000'
                    dc h'00005000040000000000'
                    dc h'00005000040000000000'
                    dc h'00005000040000000000'
                    dc h'00005000040000000000'
                    dc h'00005000015400000000'
                    dc h'00002500000155500000'
                    dc h'00001500000000400000'
                    dc h'00000250000000400000'
                    dc h'00000025500000400000'
                    dc h'00000001254444400000'

lshift0             ANOP
                    dc h'00005555552100000000'
                    dc h'00005000005520000000'
                    dc h'00005000000042000000'
                    dc h'00005000000004100000'
                    dc h'00005441000004200000'
                    dc h'00000004410000400000'
                    dc h'00000000040000400000'
                    dc h'00000000040000400000'
                    dc h'00000000040000400000'
                    dc h'00000000040000400000'
                    dc h'00000000040000400000'
                    dc h'00000004510000400000'
                    dc h'00005551000004200000'
                    dc h'00005000000004100000'
                    dc h'00005000000042000000'
                    dc h'00005000004420000000'
                    dc h'00005444442100000000'
lA             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444420000040'
               dc    h'00000000000052000040'
               dc    h'55555555555554000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000444444442000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000000444440'

lB             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000140'
               dc    h'50000000000000000400'
               dc    h'50000000000000000140'
               dc    h'50000444444442000040'
               dc    h'50000400000005000040'
               dc    h'50000455555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'

lC             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555500000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000255555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000040'
               dc    h'02444444444444444440'

lD             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555500000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000455555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'

lE             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000444444444444440'
               dc    h'50000400000000000000'
               dc    h'50000455555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

lF             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000444444444444440'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'54444400000000000000'

lG             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555500000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000005555550'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000255555555000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000140'
               dc    h'25000000000000001420'
               dc    h'02444444444444444200'

lH             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005000040'
               dc    h'00000000000005000040'
               dc    h'55555555555555000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000444444444000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005444440'

lI             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'00000055555550000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'55555550000044444440'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

lJ             anop
               dc    h'00000000000005555550'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'55555500000005000040'
               dc    h'40000500000005000040'
               dc    h'40000500000005000040'
               dc    h'40000510000005000040'
               dc    h'40000255555552000040'
               dc    h'40000000000000000040'
               dc    h'41000000000000000140'
               dc    h'24100000000000001420'
               dc    h'02444444444444444200'

lK             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000400000015000040'
               dc    h'50000400000024000040'
               dc    h'54444400000151000140'
               dc    h'00000000001520000230'
               dc    h'55555555554200001410'
               dc    h'50000000000000014200'
               dc    h'50000000000000042000'
               dc    h'50000000000000014200'
               dc    h'50000444444200001410'
               dc    h'50000400001420000230'
               dc    h'50000400000141000140'
               dc    h'50000400000023000040'
               dc    h'50000400000014000040'
               dc    h'50000400000004000040'
               dc    h'54444400000004444440'

lL             anop
               dc    h'55555500000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'54444400000000000000'
               dc    h'00000000000000000000'
               dc    h'55555500000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000455555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

lM             anop
               dc    h'02555555202555555200'
               dc    h'25000000425000000420'
               dc    h'50000000252000000040'
               dc    h'50000000000000000040'
               dc    h'54444442000000000040'
               dc    h'00000005000242000040'
               dc    h'55555505000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405444405000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005444440'

lN             anop
               dc    h'55555500000005555550'
               dc    h'50000040000005000040'
               dc    h'50000004000005000040'
               dc    h'50000000400005000040'
               dc    h'54444444440005000040'
               dc    h'00000000000005000040'
               dc    h'55555555555005000040'
               dc    h'50000000000405000040'
               dc    h'50000000000045000040'
               dc    h'50000000000005000040'
               dc    h'50000444400000000040'
               dc    h'50000400050000000040'
               dc    h'50000400005000000040'
               dc    h'50000400000500000040'
               dc    h'50000400000050000040'
               dc    h'50000400000005000040'
               dc    h'54444400000001444440'

lO             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555500000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000255555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000420'
               dc    h'02444444444444444200'

lP             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'50000444444444444200'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'50000400000000000000'
               dc    h'54444400000000000000'

lQ             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000520'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'54444400000005000040'
               dc    h'50000400000525000040'
               dc    h'50000400005045000040'
               dc    h'50000400050005000040'
               dc    h'50000400500000000040'
               dc    h'50000400250000000040'
               dc    h'50000255555000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000040'
               dc    h'02444444444444444440'

lR             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'50000004444444444200'
               dc    h'05000000400000000000'
               dc    h'00500000040000000000'
               dc    h'00050000004000000000'
               dc    h'00005000000400000000'
               dc    h'00000500000040000000'
               dc    h'00000054444444000000'

lS             anop
               dc    h'02555555555555555550'
               dc    h'25000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'25000000000000000040'
               dc    h'02444444444442000040'
               dc    h'00000000000004000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'

lT             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'00000055555550000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000054444440000000'

lU             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005000040'
               dc    h'00000000000005000040'
               dc    h'55555500000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000255555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000420'
               dc    h'02444444444444444200'

lV             anop
               dc    h'55555500000000005550'
               dc    h'50000400000000050040'
               dc    h'50000400000000500040'
               dc    h'50000400000005000040'
               dc    h'54444400000050000040'
               dc    h'00000000000500000040'
               dc    h'55555500005000000400'
               dc    h'50000400050000004000'
               dc    h'50000400500000040000'
               dc    h'50000405000000400000'
               dc    h'50000450000004000000'
               dc    h'50000400000040000000'
               dc    h'50000000000400000000'
               dc    h'50000000004000000000'
               dc    h'50000000040000000000'
               dc    h'50000000400000000000'
               dc    h'54444444000000000000'

lW             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005000040'
               dc    h'00000000000005000040'
               dc    h'55555505555505000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000405000405000040'
               dc    h'50000252000252000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000242000000040'
               dc    h'25000000405000000420'
               dc    h'02444444202444444200'

lX             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000410000015000040'
               dc    h'50000320000024000040'
               dc    h'54444441000151000140'
               dc    h'00000000001520000230'
               dc    h'15555555554200001410'
               dc    h'02410000000000014200'
               dc    h'00240000000000042000'
               dc    h'02510000000000014200'
               dc    h'15100002454200001410'
               dc    h'42000024101520000230'
               dc    h'51000141000151000140'
               dc    h'50000320000024000040'
               dc    h'50000410000015000040'
               dc    h'50000400000005000040'
               dc    h'54444400000005444440'

lY             anop
               dc    h'55555500000005555550'
               dc    h'50000400000005000040'
               dc    h'50000410000015000040'
               dc    h'50000320000024000040'
               dc    h'54444441000151000140'
               dc    h'00000000001520000230'
               dc    h'15555555554200001410'
               dc    h'02500000000000004200'
               dc    h'00250000000000142000'
               dc    h'00015100000001410000'
               dc    h'00000520000014000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000055444440000000'

lZ             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000400'
               dc    h'54444444444444444000'
               dc    h'00000000000000000000'
               dc    h'00000005555555500000'
               dc    h'00000050000004000000'
               dc    h'00000500000040000000'
               dc    h'00005000000400000000'
               dc    h'00050000004000000000'
               dc    h'00500000040000000000'
               dc    h'05000000455555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

l0             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555500055505555550'
               dc    h'50000400500405000040'
               dc    h'50000405000405000040'
               dc    h'50000450000405000040'
               dc    h'50000400000405000040'
               dc    h'50000000004005000040'
               dc    h'50000000045552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000420'
               dc    h'02444444444444444200'

l1             anop
               dc    h'00000555555550000000'
               dc    h'00005000000040000000'
               dc    h'00050000000040000000'
               dc    h'00500000000040000000'
               dc    h'05444444444440000000'
               dc    h'00000000000000000000'
               dc    h'00000055555550000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'00000050000040000000'
               dc    h'55555550000044444440'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

l2             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'02555555555555555550'
               dc    h'25000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'50000244444444444200'
               dc    h'50000400000000000000'
               dc    h'50000255555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'

l3             anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000140'
               dc    h'50000000000000000410'
               dc    h'50000000000000000140'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'
                                             
l4             anop
               dc    h'00000555555505555550'
               dc    h'00005000004005000040'
               dc    h'00050000040005000040'
               dc    h'00500000400005000040'
               dc    h'05444444000005000040'
               dc    h'00000000000005000040'
               dc    h'55555555555555000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005000040'
               dc    h'00000000000005444440'

l5             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'25000000000000000040'
               dc    h'02444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'

l6             anop
               dc    h'02555555555555555550'
               dc    h'25000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000444444442000040'
               dc    h'50000400000005000040'
               dc    h'50000455555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000420'
               dc    h'02444444444444444200'

l7             anop
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000400'
               dc    h'54444444444444444000'
               dc    h'00000000000000000000'
               dc    h'00000005555555500000'
               dc    h'00000050000004000000'
               dc    h'00000500000040000000'
               dc    h'00005000000400000000'
               dc    h'00050000004000000000'
               dc    h'00500000040000000000'
               dc    h'05000000400000000000'
               dc    h'50000004000000000000'
               dc    h'50000040000000000000'
               dc    h'50000400000000000000'
               dc    h'54444000000000000000'

l8             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'51000000000000000140'
               dc    h'04000000000000000400'
               dc    h'51000000000000000140'
               dc    h'50000244444442000040'
               dc    h'50000400000005000040'
               dc    h'50000255555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000420'
               dc    h'02444444444444444200'

l9             anop
               dc    h'02555555555555555200'
               dc    h'25000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000244444442000040'
               dc    h'50000400000005000040'
               dc    h'50000255555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'25000000000000000040'
               dc    h'02444444444442000040'
               dc    h'00000000000005000040'
               dc    h'55555555555552000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000420'
               dc    h'54444444444444444200'

lexp           anop
               dc    h'00000005555550000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005444440000000'
               dc    h'00000000000000000000'
               dc    h'00000005555550000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005444440000000'

ldash          anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'55555555555555555550'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444444444440'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'

lcol           anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000005555550000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005444440000000'
               dc    h'00000000000000000000'
               dc    h'00000005555550000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005444440000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'

lapos          anop
               dc    h'00000055555500000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000054400400000000'
               dc    h'00000000500400000000'
               dc    h'00000000504200000000'
               dc    h'00000000542000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'

lcom           anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000055555500000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000054400400000000'
               dc    h'00000000500400000000'
               dc    h'00000000504200000000'
               dc    h'00000000542000000000'

lscol          anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000055555500000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000054444400000000'
               dc    h'00000000000000000000'
               dc    h'00000055555500000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000050000400000000'
               dc    h'00000054400400000000'
               dc    h'00000000500400000000'
               dc    h'00000000504200000000'
               dc    h'00000000542000000000'

lper           anop
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000000000000000000'
               dc    h'00000005555550000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005000040000000'
               dc    h'00000005444440000000'

lSlash         anop
               dc    h'00000000000005555550'
               dc    h'00000000000050000040'
               dc    h'00000000000500000040'
               dc    h'00000000005000000400'
               dc    h'00000000055444444000'
               dc    h'00000000000000000000'
               dc    h'00000005555555400000'
               dc    h'00000050000004000000'
               dc    h'00000500000040000000'
               dc    h'00005000000400000000'
               dc    h'00050000004000000000'
               dc    h'00500000040000000000'
               dc    h'05000000400000000000'
               dc    h'50000004000000000000'
               dc    h'50000040000000000000'
               dc    h'50000400000000000000'
               dc    h'54444000000000000000'

lslash2        anop
               dc    h'55555500000000000000'
               dc    h'50000040000000000000'
               dc    h'50000004000000000000'
               dc    h'05000000400000000000'
               dc    h'00544444440000000000'
               dc    h'00000000000000000000'
               dc    h'00005555555500000000'
               dc    h'00000500000040000000'
               dc    h'00000050000004000000'
               dc    h'00000005000000400000'
               dc    h'00000000500000040000'
               dc    h'00000000050000004000'
               dc    h'00000000005000000400'
               dc    h'00000000000500000040'
               dc    h'00000000000050000040'
               dc    h'00000000000005000040'
               dc    h'00000000000000544440'

lquest         anop
               dc    h'55555555555555555200'
               dc    h'50000000000000000420'
               dc    h'50000000000000000040'
               dc    h'50000000000000000040'
               dc    h'54444444444442000040'
               dc    h'00000000000005000040'
               dc    h'00000025555552000040'
               dc    h'00000250000000000040'
               dc    h'00000500000000000040'
               dc    h'00000500000000000420'
               dc    h'00000544444444444200'
               dc    h'00000000000000000000'
               dc    h'00000555555000000000'
               dc    h'00000500004000000000'
               dc    h'00000500004000000000'
               dc    h'00000500004000000000'
               dc    h'00000544444000000000'

               msb off
*NameStr        entry
*               str   'Twilight PowerScroll 1.0 module.       '
*
*NameStr2       entry
*               str   'by Jim Maricondo, Matt Keller, and Jonah Stich.        '

length         entry
               ds    2
slowflag       entry
               ds    2
noZip          entry
               ds    2
taboffset      ds    2

MyPortLoc      anop
SCB            dc    i'$0080'           portSCB
Pix            dc    i4'$E12000'        ptrToPixImage
               dc    i'$00A0'           width in bytes of each line in image
bounds         dc    i'0,0'             boundary rectangle
mode           dc    i'200,640'         was reverse!
MyPort         ds    $AA
orgPort        ds    4

               End
*-----------------------------------------------------------------------------*
*MemoryError    Start
*
*               pha
*               PushLong #0
*               _SysFailMgr
*
*               End
*----------------------------