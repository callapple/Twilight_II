
*-----------------------------------------------------------------------------*
! Twilight II Little Bouncing Earth Module.                                   !
!                                                                             !
!  By Jim Maricondo.                                                          !
!                                                                             !
! Copyright (c) 1991 Jim Maricondo.  All rights reserved.                     !
*-----------------------------------------------------------------------------*
               longa on
               longi on
               mcopy Earth1.MAC
*-----------------------------------------------------------------------------*
deref_ptr      gequ  <0
screen_ptr     gequ  deref_ptr+4
SLookUp        gequ  screen_ptr+4
image_ptr      gequ  SLookUp+4
MyID           gequ  image_ptr+4
MasterID       gequ  MyID+2
HiRes          gequ  MasterID+2
Width          gequ  HiRes+4
Depth          gequ  Width+2
ShapeNum       gequ  Depth+2
y              gequ  ShapeNum+2
bordercol      gequ  y+2

NumEarths      gequ  46

CLOCKCTL       gequ  >$E0C034           border color / rtc register
RDVBLBAR       gequ  >$E0C019           bit 7 = 1 if not VBL
MAXIMAGES      gequ  1                  # of images that can be handled
*-----------------------------------------------------------------------------*
Little_Earth   Start
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
               longm

               lda   #0
               ldx   #$8000-2
blank          sta   $E12000,x
               dex
               dex
               bpl   blank

               ldx   #32-2
pal            lda   Earth_Pal,x
               sta   $E19E00,x
               dex
               dex
               bpl   pal

               LongResult
               PushWord #1
               _GetAddress
               PullLong SLookUp         

               jsr  Animate

               plb
               lda   2,s
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+OurPathname)
               tcs
               shortm                   restore users border color
               lda   CLOCKCTL
               and   #$F0
               ora   bordercol
               sta   CLOCKCTL
               longmx 
               clc
               rtl
               
               End
*-----------------------------------------------------------------------------*
Animate        Start
               Using MainDATA

               stz  left_boundary       init boundaries
               stz  top_boundary
               lda  #170
               sta  right_boundary
               lda  #200
               sta  bottom_boundary
               stz   ShapeNum
               lda   #$E1
               sta   HiRes+2

event_loopL8   shortm
w1             lda   RDVBLBAR
               bmi   w1
w2             lda   RDVBLBAR
               bpl   w2
               longm
               jsr  DrawEarth

               jsr  move_images         move all images

               lda   ShapeNum
               inc   a
               cmp   #NumEarths
               bne   keepIt
               lda   #0
keepIt         sta   ShapeNum

               DefineStack
oldDirectPage  word
rtsAddress     word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
ourPathname    long

               phd
               tsc
               tcd
               lda   [MovePtr]
               bne   done
               pld
               bra   event_loopL8

done           anop
               pld
               rts

               End
*-----------------------------------------------------------------------------*
! Apply velocities to all images to cause them to move.
! Bounce them off the motion boundaries as needed.
move_images    Start
               Using MainDATA

               lda  xposition
               clc
               adc  xvelocity
               bmi  Z1L9                way past left
               cmp  left_boundary
               bge  Z2L9                not on left edge
Z1L9           jsr  invert_xvel         else bounce it
               lda  left_boundary
               bra  Z2L9
Z2L9           pha
               clc
               adc  image_width
               cmp  right_boundary
               pla
               blt  Z3L9                not on right edge
               jsr  invert_xvel         else bounce it
               lda  right_boundary
               sec
               sbc  image_width
Z3L9           sta  xposition
               
               lda  yposition
               clc
               adc  yvelocity
               bmi  Z4L9                     ;way above top
               cmp  top_boundary
               bge  Z5L9                     ;below top edge
Z4L9           jsr  invert_yvel              ;else bounce it
               lda  top_boundary
               bra  Z6L9
Z5L9           pha
               clc
               adc  image_height
               cmp  bottom_boundary
               pla
               blt  Z6L9                     ;above bottom edge
               jsr  invert_yvel              ;else bounce it
               lda  bottom_boundary
               sec
               sbc  image_height
Z6L9           sta  yposition
               rts


! Invert X velocity to give the illusion of a bounce.
invert_xvel    lda  xvelocity
               eor  #$ffff
               inc  a
               sta  xvelocity
               rts

! Invert Y velocity to give the illusion of a bounce.
invert_yvel    lda  yvelocity
               eor  #$ffff
               inc  a
               sta  yvelocity
               rts

               End
*-----------------------------------------------------------------------------*
DrawEarth      Start
               Using MainDATA
               Using EarthDATA

               longa on
               longi on

               stz   image_index        init an index into the shape data

               lda   yposition          Y coord.. down!
               sta   y                  X coord.. across!

               lda   shapeNum
               asl   a                  x 2 to get shape number
               tax
               lda   EarthTable,x       shape data
               sta   fill2+1
               lda   image_height       depth of shape
               sta   depth

yloop          anop

               lda   image_wordwidth    width (in words) of shape
               sta   width
               lda   y                  y = y coordinate
               asl   a                  multipy by 2 to get index into table
               tay
               lda   [SLookUp],y        get address from table
               clc                      add x to base address
               adc   xposition          x = horizontal position (in bytes)
               sta   HiRes
               ldy   #0                 use Y as a horizontal offset
               ldx   image_index

xloop          anop

fill2          lda   |$0000,x           get byte of shape
               sta   [HiRes],y
               iny                      move over a word to the right
               iny
               inx                      increment index into shape's data
               inx

               dec   width              see if done with this line
               bne   xloop

               stx   image_index

               inc   y                  go to next line
               dec   depth              see if done all lines
               bne   yloop

               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

number_of_images dc   i'MAXIMAGES'      # of images handled
image_index    ds   2                   loop index

! Motion boundaries (in pixels)
left_boundary  ds    2
right_boundary ds    2
top_boundary   ds    2
bottom_boundary ds    2

! Image arrays
xvelocity      dc    i'1'
yvelocity      dc    i'1'
xposition      dc    i'0'
yposition      dc    i'0'
image_width    dc    i'20'
image_bytewidth dc    i'10'
image_wordwidth dc    i'5'
image_height   dc    i'17'

Earth_Pal          anop     
                   dc h'0000 0B00 0F00 000F F00F F000 700F 6000 0000 1101 5505'                   dc h'77079909DD0DFF'
                   dc h'6606 7707 9909 DD0D FF0F'

               End
*-----------------------------------------------------------------------------*
               copy  earthdata2.asm