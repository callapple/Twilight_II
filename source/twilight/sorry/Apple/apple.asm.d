
               longa on
               longi on
               mcopy apple.mac
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
y              gequ  Depth+2
bordercol      gequ  y+2
image_index    gequ  bordercol+1
temp           gequ  image_index+2

BWidth         gequ  20                 width in bytes of the shape

BORDER         gequ  >$E0C034           border color/real time clock register
VERTCNT        gequ  >$E0C02E
SHR            gequ  >$E12000
SCBs           gequ  >$E19D00
PALETTES       gequ  >$E19E00
VBLWait        gequ  >$E0C019           bit 7 = 1 if not VBL
*-----------------------------------------------------------------------------*
Main           Start
               Using MainDATA

               phb                      Store old data bank
               phk
               plb

               shortm
               lda  BORDER              save old border color and make border
               pha                       color now black
               and  #$0F
               sta  bordercol
               pla
               and  #$F0
               sta  BORDER
               longm

               lda   #0
               ldx   #$8000-2
blank          sta   SHR,x
               dex
               dex
               bpl   blank

               ldx   #32-2
pal            lda   |Apple_Pal,x
               sta   PALETTES,x
               dex
               dex
               bpl   pal

               LongResult
               PushWord #1
               _GetAddress
               PullLong SLookUp         

!               DefineStack
!oldBank        byte
!returnAddress  block 3
!MasterID       word
!MovePtr        long
!TextPtr        long
!
!               lda   MasterID,s
!               ora   #$0A00
!               sta   MyID

               jsr  Animate

!               pei   MyID
!               _DisposeAll

               shortm                   restore users border color
               lda  BORDER
               and  #$F0
               ora  bordercol
               sta  BORDER
               longmx 

               plb
               lda   2,s
               sta   12,s
               lda   1,s
               sta   11,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs
               clc
               rtl
               
               End
*-----------------------------------------------------------------------------*
Animate        Start
               Using MainDATA

               lda   #$E1
               sta   HiRes+2

               lda   top_boundary
               sta   yposition
               lda   left_boundary
               sta   xposition

event_loopL8   anop
               lda   yposition
               inc   a
               inc   a
               lsr   a
               clc
               adc   #$80
               sta   temp
               shortm
wait00         lda   VERTCNT
               cmp   temp
               bne   wait00
               longm
*               shortm
*wait2          lda   VBLWait
*               bmi   wait2
*waitVBL        lda   VBLWait
*               bpl   waitVBL
*               longm
               jsr   DrawApple

               jsr   move_images        move all images

               DefineStack
oldDirectPage  word
rtsAddress     word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

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
DrawApple      Start
               Using MainDATA

               longa on
               longi on

               stz   image_index        init an index into the shape data
               lda   yposition          Y coord.. down!
               sta   y                  X coord.. across!
               lda   image_height       depth of shape
               sta   depth

               PushWord #0              ; starting Y value
yloop          anop
               lda   image_wordwidth    width (in words) of shape
               sta   width
               lda   y                  y = y coordinate
               asl   a                  multipy by 2 to get index into table
               tay
               lda   [SLookUp],y        get address from table
               clc                      add x to base address
               adc   xposition          x = horizontal position (in bytes)
               sta   fillPtr+1

               ldx   #0
               ply
cLoop          lda   |Apple,y
fillPtr        sta   SHR,x
               inx
               inx
               iny
               iny
               dec   WIDTH
               bne   cLoop
               phy

               inc   y                  ; go to next line

               dec   depth              ; see if we've done all the lines
               bne   yLoop

               ply
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

* Motion boundaries (in pixels)
left_boundary  dc    i'0'               motion boundaries in pixels
right_boundary dc    i'bWidth+160'
top_boundary   dc    i'02'              ;11;15
bottom_boundary dc    i'198'

* Image arrays
xvelocity      dc    i'1'
yvelocity      dc    i'1'
xposition      dc    i'0'
yposition      dc    i'0'
image_width    dc    i'bWidth*2'
image_bytewidth dc    i'bWidth'
image_wordwidth dc    i'bWidth/2'
image_height   dc    i'37'

taboffset      ds    2

apple_pal      anop
               dc   h'0000 000a b000 0c00 000d e000'
               dc   h'0f00 2a05 500d 2c07 700f 0f0b'
               dc   h'd00d f00f dd0d ff0f'

apple          anop  ;1111222233334444555566667777888899990000
               dc   h'0000000000000000000000000000000000000000'        1
               dc   h'0000000000000000000000022250000000000000'        2
               dc   h'0000000000000000000002225550000000000000'        3
               dc   h'0000000000000000000022255550000000000000'        4
               dc   h'0000000000000000000225555550000000000000'        5
               dc   h'0000000000000000000225555500000000000000'        6
               dc   h'0000000000000000002255555000000000000000'        7
               dc   h'0000000000000000002255500000000000000000'        8
               dc   h'0000000000000000000255000000000000000000'        9
               dc   h'0000000002222222000000000055555550000000'        0
               dc   h'0000000222222222222222255555555555500000'        1
               dc   h'0000002222222222255555555555555555550000'        2
               dc   h'0000022222222225555555555555555555555000'        3
               dc   h'0000222222222255555555555555555555555000'        4
               dc   h'0000cccccccccdddddddddddddddddddddddd000'        5
               dc   h'000cccccccccddddddddddddddddddddddddd000'        6
               dc   h'000cccccccccddddddddddddddddddddddd00000'        7
               dc   h'000ccccccccdddddddddddddddddddddd0000000'        8
               dc   h'00cccccccccddddddddddddddddddddd00000000'        9
               dc   h'0088888888aaaaaaaaaaaaaaaaaaaaa000000000'        0
               dc   h'0088888888aaaaaaaaaaaaaaaaaaaaa000000000'        1 2
               dc   h'0088888888aaaaaaaaaaaaaaaaaaaaa000000000'        3
               dc   h'0088888888aaaaaaaaaaaaaaaaaaaaa000000000'        4
               dc   h'0001111111444444444444444444444000000000'        5
               dc   h'0001111111444444444444444444444400000000'        6
               dc   h'0001111111444444444444444444444440000000'        7
               dc   h'0000111111144444444444444444444444400000'        8
               dc   h'0000111111114444444444444444444444444000'        9
               dc   h'0000077777779999999999999999999999999000'        0
               dc   h'0000007777777799999999999999999999990000'        1
               dc   h'0000000777777779999999999999999999900000'        2
               dc   h'0000000077777777799999999999999999000000'        3
               dc   h'0000000003333333366666666666666660000000'        4
               dc   h'0000000000333333333366666666666000000000'        5
               dc   h'0000000000003333333333336666600000000000'        6
               dc   h'0000000000000033333333333336000000000000'        7
               dc   h'0000000000000000000000000000000000000000'        8

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