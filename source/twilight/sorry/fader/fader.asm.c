
*-----------------------------------------------------------------------------*
! Twilight II Fader Module.                                                   !
!                                                                             !
!  By Jim Maricondo.                                                          !
!                                                                             !
! Copyright (c) 1991 Jim Maricondo.  All rights reserved.                     !
*-----------------------------------------------------------------------------*
               mcopy fader.mac
               absaddr on
*-----------------------------------------------------------------------------*
PALETTES       gequ  >$E19E00
CLOCKCTL       gequ  >$E0C034           border color / rtc register
NEWVIDEO       gequ  >$E0C029
RDVBLBAR       gequ  >$E0C019           bit 7 = 1 if not VBL
TBCOLOR        gequ  >$E0C022

bordercol      gequ  <0                 user's original border color
textcol        gequ  bordercol+2        user's original text/background colors
*-----------------------------------------------------------------------------*
Fader          Start
               Using MainDATA

               phb                      Store old data bank
               phk
               plb

               shortm
               lda   CLOCKCTL           save old border color and make border
               pha                      color now black
               and   #$0F
               sta   bordercol
               pla
               and   #$F0
               sta   CLOCKCTL
               lda   TBCOLOR
               sta   textcol
               lda   NEWVIDEO
               ora   #$40
               sta   NEWVIDEO
               longmx

               ldx   #$200-2            save original screen colors
copy01         lda   PALETTES,x
               sta   |OrgPalette,x
               dex
               dex
               bpl   copy01

               jsr   FadeOut            fade out screen

               DefineStack
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
ourPathname    long

               phd                      wait for user activity
               tsc
               tcd
getAction      lda   [MovePtr]
               beq   getAction
               pld

               jsr   FadeIn             fade back in the original picture

               plb                      restore caller's dbr
               lda   2,s                transfer rtl up stack
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs
               shortm                   restore user's display colors
               lda   CLOCKCTL
               and   #$F0
               ora   bordercol
               sta   CLOCKCTL
               lda   textcol
               sta   TBCOLOR
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
               ldx   #$01FF
               ldy   #$03FF
repeat0        lda   |OrgPalette,x      copy palettes into buffer
               and   #$F0
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   buffer2,y
               dey
               lda   |OrgPalette,x
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
zero           sta   PALETTES-2,x
               dex
               dex
               bne   zero
               shortm

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
w1             lda   RDVBLBAR
               bmi   w1
w2             lda   RDVBLBAR
               bpl   w2

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
               sta   PALETTES,x
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
               ldx   #$01FF
               ldy   #$03FF
repeat0        lda   PALETTES,x
               and   #$F0
               sta   buffer1,y
               lsr   a
               lsr   a
               lsr   a
               lsr   a
               sta   buffer2,y
               dey
               lda   PALETTES,x
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

quit           anop
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
w1             lda   RDVBLBAR
               bmi   w1
w2             lda   RDVBLBAR
               bpl   w2

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
               sta   PALETTES,x
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