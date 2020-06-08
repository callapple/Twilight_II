
               longa on
               longi on
               mcopy anim1.mac
               mcopy 7:m16.util2
*-----------------------------------------------------------------------------*
! Illusions of Motion
! by Stephen P. Lepisto
! date: 1/22/90
! Assembler: Merlin-16+ v4.08+
*-----------------------------------------------------------------------------*
deref_ptr      gequ  0
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

NumEarths      gequ  46

Strobe         gequ  $E0C000
ClearStrobe    gequ  $E0C010
VBLWait        gequ  $E0C019            bit 7 = 1 if not VBL
MAXIMAGES      gequ  1                  # of images that can be handled
*-----------------------------------------------------------------------------*
Main           Start
               Using MainDATA

               phk
               plb

               jsr  dostartup
               bcs  shutdown            error in startup
               jsr  Animate
shutdown       jsr  doshutdown

               _Quit quitparms

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
wait2          lda   >VBLWait
               bmi   wait2
waitVBL        lda   >VBLWait           !
               bpl   waitVBL            !
               longm
               jsr  DrawEarth

               jsr  move_images         move all images

               lda   ShapeNum
               inc   a
               cmp   #NumEarths
               bne   keepIt
               lda   #0
keepIt         sta   ShapeNum

               shortm
               lda   >Strobe            if keypress, then quit
               bpl   event_loopL8

               lda   >ClearStrobe
               longm
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
DoStartUp      Start
               Using MainDATA

               _TLStartUp                     

               WordResult
               _MMStartUp                     
               pla
               sta  MasterID
               ora  #$100
               sta  MyID

               _MTStartUp                     

               LongResult               get direct page space for QuickDraw
               PushLong #$300
               pei   MyID
               PushWord #$C015
               PushLong #0
               _NewHandle
               PullLong deref_ptr
               bcs  xL25

               lda  [deref_ptr]
               pha
               PushWord #0              320 mode
               PushWord #0              screen width
               pei   MyID
               _QDStartUp                     
               bcs  xL25

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

               clc
xL25           rts

               End
*-----------------------------------------------------------------------------*
doShutDown     Start
               Using MainDATA

               _QDShutDown                   

               pei   MyID
               _DisposeAll

               pei   MasterID
               _MMShutDown

               _MTShutDown                    
               _TLShutDown                    
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

quitparms      dc   i4'0'
               dc   i'$0000'            not restartable
MasterID       ds   2
MyID           ds   2
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