
               mcopy fader.mac
               mcopy 18:m16.util2
               absaddr on
*-----------------------------------------------------------------------------*
Palette0       gequ  $E19E00
Border         gequ  $E0C034            border color / rtc register
NewVideo       gequ  $E0C029
VBLWait        gequ  $E0C019            bit 7 = 1 if not VBL
Text           gequ  $E0C022

bordercol      gequ  0                  user's original border color
textcol        gequ  bordercol+2        user's original text/background colors
*-----------------------------------------------------------------------------*
Fader          Start
               Using MainDATA

               phb                      Store old data bank
               phk
               plb

               brl   beginIt

               dc    c'  Twilight Fader Module.  '
               dc    c'  January 19, 1991.  '
               dc    c'The executable instructions in this module and '
               dc    c'all other files distributed with Twilight 2.0 with the '
               dc    c'exception of ColorStrobe are copyrighted 1991 by Jim '
               dc    c'Maricondo and Jonah Stich.  All rights reserved.  '
               dc    c'  Fade routines in this module originally inspired by '
               dc    c'an article by Kent Dicky, but since then they have been'
               dc    c' extensively hacked to the point where they bear little'
               dc    c' resembelance to their original counterparts.  '

beginIt        anop
               shortm
               lda   >Border             save old border color and make border
               pha                        color now black
               and   #$0F
               sta   <bordercol
               pla
               and   #$F0
               sta   >Border
               lda   >Text
               sta   <textcol
               lda   #0
               sta   >text
               longmx

               ldx   #$200-2            save original screen colors
copy01         lda   >Palette0,x
               sta   |OrgPalette,x
               dex
               dex
               bpl   copy01

               jsr   FadeOut            fade out screen

               shortm
               lda   #0
               sta   >text
               longmx

               DefineStack
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

               phd                      wait for user activity
               tsc
               tcd
getAction      lda   [MovePtr]
               beq   getAction
               pld

               shortm
               lda   #0
               sta   >text
               longmx

               ldx   #$200-2            restore original palette
copy02         lda   |OrgPalette,x
               sta   >Palette0,x
               dex
               dex
               bpl   copy02
               jsr   FadeIn             fade back in the original picture

               plb                      restore caller's dbr

               lda   2,s                transfer rtl up stack
               sta   12,s
               lda   1,s
               sta   11,s

               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs

               shortm                   restore user's display colors
               lda   >Border
               and   #$F0
               ora   <bordercol
               sta   >Border
               lda   <textcol
               sta   >Text
               longmx
               clc
               rtl                      and exit back to twilight
               
               End
*-----------------------------------------------------------------------------*
FadeIn         Start
               Using MainDATA

               php                      save old processor status register
               longi on
               shortm
               lda   #$41               linearize (and turn off) SHR screen
               sta   >NewVideo

               ldx   #$01FF
               ldy   #$03FF
repeat0        lda   >Palette0,x        copy palettes into buffer
               and   #$F0
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   buffer2,y
               dey
               lda   >Palette0,x
               and   #$0F
               sta   buffer2,y
               asl   a
               asl   a
               asl   a
               asl   a
               dey
               dex
               bpl   repeat0

               lda   #16
               sta   amount

               longm
               lda   #0                 black out all SHR palettes
               ldx   #$200
zero           sta   >Palette0-2,x
               dex
               dex
               bne   zero
               shortm

               lda   #$C1
               sta   >NewVideo

fade           anop
               jsr   prepare            fade palettes in buffer
               jsr   fadeIt             store buffer data to palettes
               dec   amount             done 16 times yet?
               bne   fade

quit           plp                      restore old processor status register
               rts

prepare        ldy   #$03FF
repeat         lda   buffer1,y
               clc
               adc   buffer2,y
               sta   buffer1,y
               dey
               bpl   repeat
               rts

fadeIt         anop
waitVBL        lda   >VBLWait
               bpl   waitVBL
wait2          lda   >VBLWait
               bmi   wait2

               ldx   #$01FF
               ldy   #$03FE
more           lda   buffer1,y
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   temp
               lda   buffer1+1,y
               and   #$F0
               ora   temp
               sta   >Palette0,x
               dey
               dey
               dex
               bpl   more
               rts

               End
*-----------------------------------------------------------------------------*
FadeOut        Start
               Using MainDATA

               longi on
               php
               shortm
               lda   #$C1
               sta   >NewVideo

               ldx   #$01FF
               ldy   #$03FF
repeat0        lda   >Palette0,x
               and   #$F0
               sta   buffer1,y
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   buffer2,y
               dey
               lda   >Palette0,x
               and   #$0F
               sta   buffer2,y
               asl   a
               asl   a
               asl   a
               asl   a
               sta   buffer1,y
               dey
               dex
               bpl   repeat0

               lda   #16
               sta   amount

fade           jsr   prepare
               jsr   fadeIt
               dec   amount
               bne   fade

quit           lda   #$41
               sta   >NewVideo
               plp
               rts

prepare        ldy   #$03FF
repeat         lda   buffer1,y
               sec
               sbc   buffer2,y
               sta   buffer1,y
               dey
               bpl   repeat
               rts

fadeIt         anop
waitVBL        lda   >VBLWait
               bpl   waitVBL
wait2          lda   >VBLWait
               bmi   wait2

               ldx   #$01FF
               ldy   #$03FE
more           lda   buffer1,y
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   temp
               lda   buffer1+1,y
               and   #$F0
               ora   temp
               sta   >Palette0,x
               dey
               dey
               dex
               bpl   more
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

buffer1        ds    $400
buffer2        ds    $400
OrgPalette     ds    $200
temp           ds    2
amount         ds    2

               End
*-----------------------------------------------------------------------------*
