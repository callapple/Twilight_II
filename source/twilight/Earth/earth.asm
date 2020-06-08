
*-----------------------------------------------------------------------------*
! Twilight II Large Bouncing Earth Module.                                    !
!                                                                             !
!  By Jim Maricondo.                                                          !
!                                                                             !
! v1.0 for Twilight II - 10/24/92                                             !
! v1.0.1 - 1/3/93 JRM
!                                                                             !
! Copyright (c) 1991 Jim Maricondo.  All rights reserved.                     !
*-----------------------------------------------------------------------------*
*****************************************************************
* Jim:
*   This works fine on my system now. Try it on yours. I made a lot of little
*   changes. First: You were getting 'trash' instead of a globe sometimes
*   because you never initialized the variable ShapeNum, meaning that it
*   sometimes started at about $Cxxx (the times I ran it trhough the debugger)
*   which is a bit high when you only have 42 shapes. :) I added a stz ShapeNum
*   right before the jsr Animate to fix that. Then, the bigger problem--you
*   had the loop timed so that it would *-wait-draw-calculate-erase-goto*. For
*   all but the top few lines, this meant that it would erase the shape, then
*   wait, with it erased, then quickly draw and erase it again, then wait
*   with it erased, etc. That is waht was giving you the banding. So, I moved
*   the erase to right before the draw, like this: *-wait-erase-draw-calculate-
*   goto*. This had the problem that there wasn't enough time in the VBL
*   period to completely erase and redraw the thing--the band showed up on
*   about the top 20 lines. So, to fix this, I changed the wait loop to loop
*   on the VertCnt register ($E0C02E). I calculate where the bottom of the
*   shape is, and wait until the gun has passed that line. Then I start drawing.
*   As pointed out in TN IIGS #70, this gives you almost 1/30th of a second
*   to draw the shape, which is plenty of time. Also, one personal observation:
*   I think there's a little jerk in the ball. After it does a loop, it seems
*   to skip a frame or some such.... Oh ya, one more thing: what was the point
*   of grabbing a $7D00 hunk of memory, filling it wih zeros, then using dp
*   long indexed to get a 0, when you could have just done one lda #0 and
*   save yourself MANY cycles? It's not like you have a background to restore.
*   :) I changed this, but left the old stuff there, just commented out.
*   Enjoy!
*              --Jonah
*
*   ps. I'm adding this about 3 hours later: Don't ORA the master MemID
*   with $0100. I load the file in with a MemID of x1xx or x2xx, so the
*   ORA will do nothing, but the DisposeAll will be VERY uncool. Try $0A00
*   instead.... :)
*****************************************************************
               longa on
               longi on
               mcopy Earth.MAC
	copy	22:t2common.equ
	copy	22:dsdb.equ
	keep	earth.d
*-----------------------------------------------------------------------------*
MovePtr	gequ	<0
SLookUp        gequ  MovePtr+4
HiRes          gequ  SLookUp+4
Width          gequ  HiRes+4
Depth          gequ  Width+2
ShapeNum       gequ  Depth+2
y              gequ  ShapeNum+2
ztemp2         gequ  y+2
BackPtr        gequ  ztemp2+4
lasty          gequ  BackPtr+4
lastx          gequ  lasty+2
YCoord         gequ  lastx+2
back_Width     gequ  YCoord+2
back_depth     gequ  back_width+2
SHRPtr         gequ  back_depth+2
shape_bottom   gequ  SHRPtr+4

bWidth         gequ  18
NumEarths      gequ  42

MAXIMAGES      gequ  1                  ; # of images that can be handled

;debugSymbols   gequ  $BAD               ; Put in debugging symbols ?
;debugBreaks 	gequ  $BAD               ; Put in debugging breaks ?
*-----------------------------------------------------------------------------*
Large_Earth    Start
	kind  $1000	; no special memory
	debug	'Large_Earth'
               Using MainDATA
               Using EarthDATA

	copy	22:dsdb.asm

               phb                      Store old data bank
               phk
               plb
               phd
;	tdc
;	sta	OurDP
;               tsc
;               tcd

;	dbrk	$0f

               lda   T2Message,s         ; Get which setup procedure to call.
	cmp	#BlankT2
	bne	notSupported

	lda	T2data1,s	; movePtr
	sta	MovePtr
	lda	T2data1+2,s
	sta	MovePtr+2

               ldx   #32-2
pal            lda   Earth2_Pal,x
               sta   $E19E00,x
               dex
               dex
               bpl   pal

	~GetAddress #1
               PullLong SLookUp         

               stz  ShapeNum
               jsr  Animate

notSupported   pld
               plb
               lda   1,s                ; move up RTL address
               sta   1+10,s
               lda   2,s
               sta   2+10,s
               tsc                      ; Remove input parameters.
               clc
               adc   #10
               tcs
	clc
               rtl

               End
*-----------------------------------------------------------------------------*
Animate        Start
	debug	'Animate'
               Using MainDATA

               lda   #1
               sta   left_boundary       init boundaries
               sta   xposition
               lda   #1
               sta   top_boundary
               sta   yposition
               lda   #160+bWidth-1
               sta   right_boundary
               lda   #200-1
               sta   bottom_boundary

               lda   #$2000
               sta   SHRPtr  
	sta	HiRes	; new!

	shortm
	lda	SHADOW
	longm
	bit	#$08	; bit 3 = 1 = inhibit SHR shadowing
	bne	bankE1
	lda   #$01
               sta   SHRPtr+2   
	sta	HiRes+2
	bra	bankSet
bankE1         lda   #$E1
               sta   SHRPtr+2   
	sta	HiRes+2
bankSet	anop

event_loopL8   anop
               lda   yposition
               clc
               adc   image_height
               lsr   a
               clc
               adc   #$80
               sec                      ;it was getting stuck at shape_bottom
               sbc   #4                 ; = $E1, so I subtract a few to move
               sta   shape_bottom       ; it up. Why was it getting stuck?!
               shortm
wait2          lda   >VERTCNT
               cmp   shape_bottom
               bne   wait2
               longm

               jsr   fixback
               jsr   DrawEarth

               lda   yposition
               sta   lasty
               lda   xposition
               sta   lastx

               jsr   move_images         move all images

               lda   ShapeNum
               inc   a
               cmp   #(NumEarths*2)
               blt   keepIt
	lda	#0
keepIt         sta   ShapeNum

	lda   [MovePtr]
           	beq	event_loopL8
               rts

               End
*-----------------------------------------------------------------------------*
! Apply velocities to all images to cause them to move.
! Bounce them off the motion boundaries as needed.
move_images    Start
	debug	'move_images'
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
	debug	'drawEarth'
               Using MainDATA
               Using EarthDATA

               longa on
               longi on

               stz   image_index        init an index into the shape data

               lda   yposition          Y coord.. down!
               sta   y                  X coord.. across!

               lda   shapeNum
	and	#$FFFE
;               asl   a                  x 2 to get shape number
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
FixBack        Start
	debug	'fixBack'
               Using MainDATA

               longa on
               longi on

               lda   lasty              Y coord.. down!
               sta   YCoord             X coord.. across!
               lda   image_height       depth of shape
               sta   back_depth

yloop          anop
               lda   #bWidth/2          width (in words) of shape
               sta   back_Width
               lda   YCoord             y = y coordinate
               asl   a                  multipy by 2 to get index into table
               tay
               lda   [SLookUp],y        get address from table
               clc                      add x to base address
               adc   lastx              x = horizontal position (in bytes)
               sec                      convert it into offset into SHR instead
               sbc   #$2000              of offset into bank E1     
               tay
               lda   #0
xloop          anop
;              lda   [BackPtr],y        get byte of shape
               sta   [SHRPtr],y   
               iny                      move over a word to the right
               iny
               dec   back_width         see if done with this line
               bne   xloop

               inc   YCoord             go to next line
               dec   back_depth         see if done all lines
               bne   yloop
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

earth2_pal          ANOP
                    dc h'0000 000f 2300 3400 4500 5600'
                    dc h'6700 9a08 bb09 cd0a ee0c ff0f'
                    dc h'a000 8000 6000 4000'

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
image_width    dc    i'bWidth*2'
image_bytewidth dc    i'bWidth'
image_wordwidth dc    i'bWidth/2'
image_height   dc    i'32'

               End
*-----------------------------------------------------------------------------*
               copy  e1.15