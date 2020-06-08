
*-----------------------------------------------------------------------------*
! Twilight II SKULLey Module.                                                 !
!                                                                             !
!  By Jim Maricondo.                                                          !
!                                                                             !
! Copyright (c) 1991 Jim Maricondo.  All rights reserved.                     !
*-----------------------------------------------------------------------------*
               mcopy skulley.mac
               absaddr on
               case  off
*-----------------------------------------------------------------------------*
! TO TOGGLE:
!
! * SOUND
! * ACCELERATOR PRESENT
sculley        gequ  <0
SLookUp        gequ  sculley+4
MyID           gequ  SLookUp+4
HiRes          gequ  MyID+2
Width          gequ  HiRes+4
Depth          gequ  Width+2
y              gequ  Depth+2
bordercol      gequ  y+2
image_index    gequ  bordercol+1
inactive       gequ  image_index+2
stage          gequ  inactive+2
byte_offset    gequ  stage+2
bullet_offset  gequ  byte_offset+2
bul_off_temp   gequ  bullet_offset+2
shots          gequ  bul_off_temp+2
HandleLoc      gequ  shots+2
ztemp1         gequ  shots+2
ToolsDP        gequ  HandleLoc+4
ShutItDown     gequ  ToolsDP+2
NoSound        gequ  shutItDown+2
TempHandle     gequ  NOSound+2
tempPtr        gequ  TempHandle+4
bas1           gequ  tempPtr+4
bas2           gequ  bas1+4
bas22          gequ  bas2+4
ourPath        gequ  bas22+4

BWidth         gequ  30
Height         gequ  75
NumBullets     gequ  4

CLOCKCTL       gequ  >$E0C034           border color / rtc register
RDVBLBAR       gequ  >$E0C019
MAXIMAGES      gequ  1                  # of images that can be handled
rSculley       gequ  $32F1
rPalette       gequ  $32F2
rSound         gequ  $32F3
*-----------------------------------------------------------------------------*
SKULLey        Start
               Using MainDATA

               phb                      Store old data bank
               phk
               plb

               bra   beginIt

               dc    c'  ][ Infinitum.  '

beginIt        anop
               shortm
               lda   CLOCKCTL           save old border color and make border
               pha                       color now black
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

               stz   ShutItDown

               LongResult
               PushWord #1
               _GetAddress
               PullLong SLookUp         

               DefineStack
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
ourPathname    long

               lda   MasterID,s
               ora   #$0A00
               sta   MyID

               lda   ourPathname,s
               sta   ourPath
               lda   ourPathname+2,s
               sta   ourPath+2

               WordResult
               _GetCurResourceApp
               PullWord OldResourceApp

               WordResult
               _GetCurResourceFile
               PullWord OldResourceFile

               pei   MyID
               _ResourceStartUp

*               pei   MyID
*               _SetCurResourceApp

               WordResult
               PushWord #1              request read access
               PushLong #0              open a new file
               pei   ourPath+2
               pei   ourPath
               _OpenResourceFile
               plx
               stx   ResFileID
               jcs   Error

               LongResult
               PushWord #rPalette
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempHandle
               plx
               stx   TempHandle+2
               jcs   error
               deref TempPtr,TempHandle

               ldx   #32-2              set skulley palette
pal            txy
               lda   [TempPtr],y
               sta   $E19E00,x
               dex
               dex
               bpl   pal

               LongResult
               PushWord #rSound
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempHandle
               plx
               stx   TempHandle+2
               jcs   error
               deref SoundPtr,TempHandle

               LongResult
               pei   TempHandle+2
               pei   TempHandle
               _GetHandleSize
               PullLong SoundSize

               LongResult
               PushWord #rSculley
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempHandle
               plx
               stx   TempHandle+2
               jcs   error
               deref Bas1,TempHandle
               PushWord #rSculley
               PushLong #$00000001
               _DetachResource

               LongResult
               PushWord #rSculley
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempHandle
               plx
               stx   TempHandle+2
               jcs   error
               deref (Bas2,Sculley,Bas22),TempHandle

               lda   Bas22              ; Bas22 = Bas2+2220
               clc
               adc   #2220
               bcc   noInc
               inc   Bas22+2
noInc          sta   Bas22

               PushWord #rSculley
               PushLong #$00000001
               _DetachResource

               WordResult
               _SoundToolStatus
               pla
               bne   Active             if nonzero, tool is active

               LongResult
               PushLong #$100           1 page of direct page space
               pei   MyID
               PushWord #$C005          locked/fixed/page aligned/specific bank
               PushLong #0              specify bank 0
               _NewHandle
               plx
               stx   HandleLoc
               plx
               stx   HandleLoc+2
               bcs   Error              if error, exit module

               lda   [HandleLoc]        dereference handle to get & and save
               sta   ToolsDP             location of direct page

               pei   ToolsDP            bnk $0 start addr of 1 page direct page
               _SoundStartUp

               lda   #1
               sta   ShutItDown

Active         anop
               lda   SoundSize+1
               sta   Pages

               stz   NoSound

               WordResult
               _FFSoundStatus
               pla
               and   #%10000000
               beq   good               gen 7 is inactive, so sound is enabled
               lda   #1
               sta   NoSound            else sound is disabled

good           anop
               jsr   Animate
               bra   noErr

Error          anop
               sta   $E12000

noErr          plb
               lda   2,s
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+ourPathname)
               tcs
               shortm                   restore users border color
               lda  CLOCKCTL
               and  #$F0
               ora  bordercol
               sta  CLOCKCTL
               longmx 

               PushWord #%10000000
               _FFStopSound             Make sure Generator 7 is off
                                   
               lda   ShutItDown         if it was started in the first place,
               beq   nope                leave it started up

               _SoundShutDown

nope           anop
               PushWord ResFileID
               _CloseResourceFile

               _ResourceShutDown

               PushWord OldResourceFile
               _SetCurResourceFile

               PushWord OldResourceApp
               _SetCurResourceApp

               pei   MyID
               _DisposeAll
               clc
               rtl
               
               End
*-----------------------------------------------------------------------------*
Animate        Start
               Using MainDATA

               WordResult
               _GetMasterSCB
               pla
               bmi   Shadowing_On

               lda   #$E1
               sta   HiRes+2
               bra   cont

Shadowing_On   anop
               lda   #$01
               sta   HiRes+2

cont           anop
               stz   shots

               jsr   Randomize          ; set a new random seed

event_loopL8   anop
*               shortm                  ; for ACCELERATOR ONLY !
*v1             lda   RDVBLBAR
*               bmi   v1
*v2             lda   RDVBLBAR
*               bpl   v2
*               longm
               jsr   DrawSculley

               lda   shots
               cmp   #20
               blt   no_reset

               stz   shots
               ldy   #75*30
recopy         lda   [bas1],y
               sta   [bas2],y
               dey
               dey
               bpl   recopy

               lda   #0
               ldy   #BWidth
zero00         sta   [Bas2],y
               dey
               dey
               bpl   zero00

no_reset       anop
               jsr   move_images         move all images

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

               inc   shots
               jsr   DrawBullet
               rts

! Invert Y velocity to give the illusion of a bounce.
invert_yvel    lda  yvelocity
               eor  #$ffff
               inc  a
               sta  yvelocity

               inc   shots
               jsr   DrawBullet
               rts

               End
*-----------------------------------------------------------------------------*
PlaySound      Start
               using MainDATA

               lda   NoSound            if nosound is true, then don't do any
               beq   good                sound effects
               rts

good           anop
               PushWord #%10000000
               _FFStopSound             Make sure Generator 7 is off
                                   
               jsr   Random
               bmi   right_speaker

               PushWord #$1701          1=left spkr; 7=gen 7; 0=reserved; 1=FF
               PushLong #PlayParms      Pointer to the SoundParms
               _FFStartSound            Start playing sound (continuously)

               rts

right_speaker  anop
               PushWord #$0701          0=right spkr; 7=gen7; 0=reserved; 1=FF
               PushLong #PlayParms      Pointer to the SoundParms
               _FFStartSound            Start playing sound (continuously)

               rts

               End
*-----------------------------------------------------------------------------*
* This should draw Sculley a lot faster.
* Just set "Sculley" to the address of the shape (32 bits) and this routine
* should draw it.  ("Sculley" should be in the Direct Page.)
* Also: It should not cross banks!  I don't think it did originally so it
* shouldn't be a problem.
* -- Derek Young
DrawSculley    Start
               Using MainDATA

               longa on
               longi on

               lda   yposition
               asl   a
               tay
               lda   [SLookUp],y
               clc
               adc   xposition
               sta   HiRes              ; set up the index onto the screen now

               lda   image_height       ; depth of shape
               sta   depth

               lda   Bas2
               sta   Sculley

               clc                      ; Carry will stay clear
;                                       ; throughout the loop.
yloop          ldx   image_wordwidth    ; width (in words) of shape

               ldy   #0
xloop          lda   [Sculley],y
               sta   [HiRes],y
               iny                      ; only one register to increment!
               iny
               dex
               bne   xloop

               lda   Sculley
               adc   image_bytewidth    ; next line of Mr. Sculley
               sta   Sculley

               lda   HiRes              ; next line on the screen
               adc   #160
               sta   HiRes

               dec   depth
               bne   yloop
               rts

               End
*-----------------------------------------------------------------------------*
DrawBullet     Start
               Using MainDATA
               Using BulletDATA

               longa on
               longi on

               jsr   PlaySound

GetRandom      anop
               jsr   Random
               and   #$0FFF             <- to optimize!!  think about it... :)
               cmp   #2100
               bge   GetRandom
               sta   bullet_offset

               stz   image_index        init an index into the shape data

               lda   #15                depth of bullet
               sta   depth

               lda   bullet_offset
               sta   bul_off_temp

yloop          anop
               lda   #5                 width (in words) of shape
               sta   width

               ldy   bul_off_temp       use Y as a horizontal offset
               ldx   image_index

xloop          anop
               lda   [bas2],y
               and   |bulmsk4,x         get byte of shape
               ora   |bullet4,x
               sta   [bas2],y
               iny                      move over a word to the right
               iny
               inx                      increment index into shape's data
               inx

               dec   width              see if done with this line
               bne   xloop

               stx   image_index
               lda   bul_off_temp       move ptr one line down
               clc
               adc   #30                30 bytes wide (skulley shape)
               sta   bul_off_temp       NEU

               dec   depth              see if done all lines
               bne   yloop

               lda   #0
               tay
               tax
zero0          txa
               sta   [Bas2],y
               tya
               clc
               adc   #bWidth
               tay
               cpy   #bWidth*75         75 lines
               bne   zero0

               lda   #0
               ldy   #28
               tax
zero1          txa
               sta   [Bas2],y
               tya
               clc
               adc   #bWidth
               tay
               cpy   #(bWidth*75)+28    75 lines
               bne   zero1

               lda   #0
               tay
zero2          sta   [Bas2],y
               sta   [Bas22],y          ; sta bastard4+2220,y
               iny                      ; (zero bottom lines of Sculley's pic)
               iny
               cpy   #bWidth
               bne   zero2
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

! We don't use the first 256 bytes of DOC RAM because they might already be in
! use by the Note Synthesizer.  Also, we use the full 32768 bytes offered by
! the DOC RAM, since there are two generators and each requires a buffer, so we
! split it in half for an effective $7E00 bytes per generator.  Also, by
! Setting the pointer to the next wave to the beginning of this wave, the wave
! repeats.

PlayParms      anop
SoundPtr       dc    i4'SoundPtr'
Pages          ds    2
               dc    i'200'             Sound speed
               dc    i'$0100'           Page 1 of doc ram
               dc    i'$7E00'           Reserve 32k in doc ram
               dc    i4'0'              Pointer to next wave; 0 for no repeat
               dc    i'$00FF'           Volume: 255 (maximum)

SoundSize      ds    4
ResFileID      ds    2
OurNameStr     GSStr '*:system:cdevs:twilight:SKULLey1.1'
OldResourceApp ds    2
OldResourceFile ds   2

! Motion boundaries (in pixels)
left_boundary  dc    i'0'               motion boundaries in pixels
right_boundary dc    i'bWidth+160'
top_boundary   dc    i'0'
bottom_boundary dc   i'200'

! Image arrays
xvelocity      dc    i'1'
yvelocity      dc    i'1'
xposition      dc    i'0'
yposition      dc    i'0'
image_width    dc    i'bWidth*2'
image_bytewidth dc    i'bWidth'
image_wordwidth dc    i'bWidth/2'
image_height   dc    i'height'

               End
*-----------------------------------------------------------------------------*
* I thought you might want to have the random
* number generator I use.  I haven't tested it
* against QuickDraw but there was a demo with Merlin
* that showed it and it was VERY fast and random
* looking. (I could send it if you want.)
* Use this for whatever you want.
*-------------------------------------------------
* RANDOM returns a random number in A
* RANDOMIZE seeds the generator from the clock
* SEED seeds the generator from AXY.
*
* Adapted by Derek Young from RANDOM, from the
* Merlin 16+ package.
*
* X and Y registers preserved, number returned in A
Random         Start

               phx
               phy
               clc
               ldx   INDEXI
               ldy   INDEXJ
               lda   ARRAY-2,X
               adc   ARRAY-2,Y
               sta   ARRAY-2,X
               dex
               dex
               bne   DYL7
               ldx   #17*2              ; Cycle index if at end of
DYL7           dey                      ; the array
               dey
               bne   SETIXL7
               ldy   #17*2
SETIXL7        stx   INDEXI
               sty   INDEXJ
               ply
               plx
               rts

INDEXI         dc    a'17*2'            ; The relative positions of
INDEXJ         dc    a'5*2'             ; these indexes is crucial

ARRAY          dc    a'1,1,2,3,5,8,13,21,54,75,129,204'
               dc    a'323,527,850,1377,2227'

*=================================================
* Randomize sets the random number seed from the
* clock.

Randomize      Entry
               pha
               pha
               pha
               pha
               ldx   #$D03              ; ReadTimeHex
               jsl   $E10000            ; (like this so we don't need macros)
               pla
               plx
               ply
               sta   1,S

               ora   #1                 ; At least one must be odd
               sta   ARRAY
               stx   ARRAY+2
               phx                      ; Push index regs on stack
               phy
               ldx   #30
LUPV1          sta   ARRAY+2,X
               dex
               dex
               lda   1,S                ; Was Y
               sta   ARRAY+2,X
               dex
               dex
               lda   3,S                ; Was X
               sta   ARRAY+2,X
               lda   5,S                ; Original A
               dex
               dex
               bne   LUPV1
               lda   #17*2
               sta   INDEXI             ; Init proper indexes
               lda   #5*2               ; into array
               sta   INDEXJ
               jsr   Random             ; Warm the generator up.
               jsr   Random
               ply
               plx
               pla
               rts

               end
*-----------------------------------------------------------------------------*
               copy bullets3.src