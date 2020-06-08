
               copy  7/e16.memory
               copy  YDI.Equ
               mcopy YDI.Mac
               mcopy 7/m16.quickdraw
               case off
*-----------------------------------------------------------------------------*
! You Draw It v2.1
spkr           gequ  $E0C030
Strobe         gequ  $E0C000
ClearStrobe    gequ  $E0C010
NewVideo       gequ  $E0C029
VBLWait        gequ  $E0C019            bit 7 = 1 if not VBL
INCBUSYFLG     gequ  $E10064            increment busy flag
DECBUSYFLG     gequ  $E10068            decrement busy flag

rC1InputString gequ  $8005

Shape1Start    gequ  $00A2              +$2000 not included
Shape2Start    gequ  $00C0
Shape3Start    gequ  $00DE
Shape4Start    gequ  $00FC
Shape5Start    gequ  $011A
Shape6Start    gequ  $2442
Shape7Start    gequ  $2460
Shape8Start    gequ  $247E
Shape9Start    gequ  $249C
Shape10Start   gequ  $24BA
Shape11Start   gequ  $47E2
Shape12Start   gequ  $4800
Shape13Start   gequ  $481E
Shape14Start   gequ  $483C
Shape15Start   gequ  $00A2+$7D00        +$2000 not included
Shape16Start   gequ  $00C0+$7D00
Shape17Start   gequ  $00DE+$7D00
Shape18Start   gequ  $00FC+$7D00
Shape19Start   gequ  $011A+$7D00
Shape20Start   gequ  $2442+$7D00
Shape21Start   gequ  $2460+$7D00
Shape22Start   gequ  $247E+$7D00
Shape23Start   gequ  $249C+$7D00
Shape24Start   gequ  $24BA+$7D00
Shape25Start   gequ  $47E2+$7D00
Shape26Start   gequ  $4800+$7D00
Shape27Start   gequ  $481E+$7D00
Shape28Start   gequ  $483C+$7D00
LastShape5     gequ  $6A3A-$2000        +$E12000 not included
LastShape6     gequ  $71BA-$2000
LastShape7     gequ  $793A-$2000
LastShape8     gequ  $80BA-$2000
LastShape9     gequ  $883A-$2000
LastShape10    gequ  $6A4F-$2000
LastShape11    gequ  $71CF-$2000
LastShape12    gequ  $794F-$2000
LastShape13    gequ  $80CF-$2000
LastShape14    gequ  $884F-$2000

MasterID       gequ  <0
MyID           gequ  MasterID+2
TempDP         gequ  MyID+2
PicPtr         gequ  TempDP+4
PackedPtr      gequ  PicPtr+4
SLookUp        gequ  PackedPtr+4
SCBPtr         gequ  SLookUp+4
x              gequ  SCBPtr+4
y              gequ  x+2
CurrX          gequ  y+2
CurrY          gequ  CurrX+2
CurrShape      gequ  CurrY+2
YSave          gequ  CurrShape+2
NumShapes      gequ  YSave+2
depth          gequ  NumShapes+2
Action         gequ  depth+2
twice          gequ  Action+2
bottom         gequ  twice+2
TempHandle     gequ  bottom+2
SFStatus       gequ  TempHandle+4
FrontWindow    gequ  SFStatus+2
OurPath        gequ  FrontWindow+4
*-----------------------------------------------------------------------------*
YDI2           Start
               Using GlobalDATA

               longa on
               longi on

               phb
               phk
               plb

               jsr   StartUp

; Load Picture
               _OpenGS openParams
               jcs   GSOSErr0           ;ExitWithBeep       if error, quit

               lda   OpenID
               sta   ReadID
               sta   CloseID

               lda   eof
               sta   readLength

               LongResult
               PushLong eof
               pei   MyID
               PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   TempDP
               plx
               stx   TempDP+2
               jcs   MemoryErr2         ;ExitWithBeep2      if error, quit

               lda   [TempDP]
               sta   PackedPtr
               sta   PicDestIN
               ldy   #2
               lda   [TempDP],y
               sta   PackedPtr+2
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   GSOSErr2           ;ExitWithBeep2      if error, quit

               _CloseGS CloseParams     close picture

               PushWord #3
               PushWord #rC1InputString
               PushLong #SavedPathC1IStr
               _ReleaseResource

; Unpack Picture
               ldx   #$7D00-2           make screen black; zero pixel data
               lda   #0
nextZero       sta   $E12000,x
               dex
               dex
               bpl   nextZero

               LongResult               get memory for unpacked pic
               PushLong #$8000
               pei   MyID
               PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   TempDP
               plx
               stx   TempDP+2
               jcs   MemoryErr0         ;ExitWithBeep       if error, quit

               lda   [TempDP]
               sta   PicPtr
               sta   ScreenHandle
               ldy   #2
               lda   [TempDP],y
               sta   PicPtr+2
               sta   ScreenHandle+2

*               lda   #$2000             reset where to unpack as Unpackbytes
*               sta   ScreenHandle        thrashes this info (how rude!! :)
*               lda   #$E1
*               sta   ScreenHandle+2

               lda   eof                load filesize
               clc                       and add to it the beginning
               adc   PackedPtr           of the file buffer
               sta   endfile            so we have the END of the file

               lda   eof+2
               clc                      just do the same for the high
               adc   PackedPtr+2           byte
               sta   endfile+2

checkmain      ldy   #5                 load the 5th byte of the data
               lda   [PackedPtr],y
               and   #$7F7F             mask off the HIGH bits
               cmp   #$414D             is it a "MA"?
               jne   notpref            nope, this isn't the correct block
               iny                       or file
               iny
               lda   [PackedPtr],y      get the next two bytes
               cmp   #$4E49             is it a "IN"?
               jne   notpref            nope

               ldy   #11                (pixelsperscanline)
               lda   [PackedPtr],y      get the width of the picture
               sta   width

               cmp   #320               is it 320 mode?
               beq   pref2              yes
               cmp   #640               is it 640 mode?
               beq   pref2              yes

*               brl   exitWithBeep       if it's neither, than we don't support
;                                        it, so abort this picture
               brl   BadAPFFile

pref2          ldy   #9
               lda   [PackedPtr],y      get the master mode
               sta   preftemp           store it
               xba                      move it into the high byte also
               ora   preftemp           so it'll be $0X0X
               and   #$F0F0             and just to make sure mask the high

               ldx   #0                 nibbles off
pref3          sta   $E19D00,x          store this master mode Scan Contro
               inx                      Byte into the enter SCBs
               inx                      data buffer
               cpx   #$C8               have we gone to 200 bytes yet?
               bne   pref3              nope

               LongResult
               ldy   #13                get the number of palettes
               lda   [PackedPtr],y
               pha                      multiply it by 32 bytes, which is
               PushWord #$0020          how many bytes per palette
               _Multiply
               pla                      pull the result
               sta   palettenum         store it as the byte offset past the
               clc                      palettes information
               adc   #17                add 17 to it to make it correct
               sta   preftemp           store it as the preferred temp area
               plx

               lda   PackedPtr
               clc                      load the 0 direct page space, and
               adc   preftemp           add to it the data grabbed and store
               sta   SCBPtr             it at $04 DP space.  Now we have
               lda   PackedPtr+2        a pointer to the SCBs information
               sta   SCBPtr+2           contained in the file!!!

               ldy   preftemp           load the pointer to the SCBs area
               dey                      and subtract 2 from it so we
               dey                      get the number of scb's
               lda   [PackedPtr],y      get the number of SCBs in the file
               cmp   #257               is it greater than 256?
               blt   scbsok             yes
               lda   #256               no more than 256 SCBs
scbsok         sta   scbnum             store it as the # of SCBs
               ldx   #0                 initialize some counters
               ldy   #2
scbs_set       anop
               lda   [SCBPtr],y         move the individual SCBs in the file
               sta   $E19D00,x
               iny
               iny
               iny
               iny                ; we just did a double check by using
               inx                ; both the Master SCB and the individual SCBs
               cpx   scbnum
               blt   scbs_set

               lda   palettenum         load the pointer to the SCBs
               sta   preftemp           and store it for future reference

               ldx   #0
               ldy   #13                initialize counters
pref5          iny
               iny
               lda   [PackedPtr],y      we're just going to move the
               sta   $E19E00,x          palettes from the file into the
               inx                      actual palettes area ($E19E00)
               inx  
               lda   palettenum         decrement the palette size
               dec   a
               dec   a
               sta   palettenum         are we done yet?
               bne   pref5              no

*               ldx   #0                 save original screen palette
*nextTempPal    lda   $E19E00,x
*               sta   TempPal,x
*               inx
*               inx
*               cpx   #32
*               bne   nextTempPal
*
*               lda   #0                 black out screen palette 0
*               ldx   #0
*nextBlack      sta   $E19E00,x
*               inx
*               inx
*               cpx   #32
*               bne   nextBlack

               lda   preftemp           we're done
               clc                      adjust the SCBs pointer to skip
               adc   #15                the first bytes
               tay
               lda   [PackedPtr],y      load the number of SCBs
               iny
               iny
               tax
               tya
pref6          clc
* OK, it's a PARIK LOOP..  fix it if you like. :)
               adc   #4                 and adjust the pointer to
               dex                      skip the entire SCBs area since
               bne   pref6              we've already worked with it
               sta   preftemp           and finally point to the packed data!

               lda   #$7D00*2           the size of the screen for
               sta   ScreenLength        unpacking purposes

               WordResult
               pei   PackedPtr+2        push hi byte of buffer containing
;                                        the packed data
               lda   PackedPtr          load the original buffer
               clc
               adc   preftemp           add the number of bytes to skip
               pha
               lda   eof                load the filesize
               sec                       and subtract from it the
               sbc   preftemp            number of bytes to skip
               pha
               PushLong #ScreenHandle   push handle to screen
               PushLong #ScreenLength   push pointer to screen size word
               _UnPackBytes
               pla                      discard result

               pei   TempDP+2           get rid of packed data buffer
               pei   TempDP
               _DisposeHandle

*               pea   $E1E1
*               plb
*               plb
*
*               ldx   #$7D00-2
*               txy
*copy           lda   |$2000,x
*               sta   [PicPtr],y
*               dex
*               dex
*               dey
*               dey
*               bpl   copy
*
*               phk
*               plb

               lda   [PicPtr]
               cmp   #$D2FE             ID byte
               jeq   NewFormat

; Check how many frames are in animation

               ldy   #lastshape5
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last5
               ldy   #lastshape6
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last6
               ldy   #lastshape7
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last7
               ldy   #lastshape8
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last8
               ldy   #lastshape9
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last9
               ldy   #lastshape10
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last10
               ldy   #lastshape11
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last11
               ldy   #lastshape12
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last12
               ldy   #lastshape13
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last13
               ldy   #lastshape14
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last14

               brl   BadATFFile
*               brl   exitWithBeep       user messed up...

last5          anop
               lda   #5
               sta   numShapes
               brl   cont
last6          anop
               lda   #6
               sta   numShapes
               brl   cont
last7          anop
               lda   #7
               sta   numShapes
               brl   cont
last8          anop
               lda   #8
               sta   numShapes
               brl   cont
last9          anop
               lda   #9 
               sta   numShapes
               brl   cont
last10         anop
               lda   #10
               sta   numShapes
               brl   cont
last11         anop
               lda   #11
               sta   numShapes
               brl   cont
last12         anop
               lda   #12
               sta   numShapes
               brl   cont
last13         anop
               lda   #13
               sta   numShapes
               brl   cont
last14         anop
               lda   #14
               sta   numShapes
               brl   Cont


NewFormat      anop
               ldy   #lastshape5
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast10
               ldy   #lastshape6
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast12
               ldy   #lastshape7
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast14
               ldy   #lastshape8
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast16
               ldy   #lastshape9
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast18
               ldy   #lastshape10
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast20
               ldy   #lastshape11
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast22
               ldy   #lastshape12
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast24
               ldy   #lastshape13
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast26
               ldy   #lastshape14
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast28

               brl   BadATFFile
*               brl   exitWithBeep       user messed up...

aLast10        anop
               lda   #10
               sta   numShapes
               bra   cont
aLast12        anop
               lda   #12
               sta   numShapes
               bra   cont
aLast14        anop
               lda   #14
               sta   numShapes
               bra   cont
aLast16        anop
               lda   #16
               sta   numShapes
               bra   cont
aLast18        anop
               lda   #18
               sta   numShapes
               bra   cont
aLast20        anop
               lda   #20
               sta   numShapes
               bra   cont
aLast22        anop
               lda   #22
               sta   numShapes
               bra   cont
aLast24        anop
               lda   #24
               sta   numShapes
               bra   cont
aLast26        anop
               lda   #26
               sta   numShapes
               bra   cont
aLast28        anop
               lda   #28
               sta   numShapes
               bra   Cont


cont           anop

; Zero variables
               stz   CurrShape
               stz   y
               stz   x
               stz   Action
               stz   twice

*               ldx   #0                 restore old palette
*nextRestPal    lda   TempPal,x
*               sta   $E19E00,x
*               inx
*               inx
*               cpx   #32
*               bne   nextRestPal


; Main animation loop
mainloop       anop
               lda   CurrShape
               asl   a                  times two
               tax
               lda   AddrTable,x        get start addr from table
               sta   YSave

               lda   y
               clc
               adc   #50
               lsr   a
               clc
               adc   #$80
               sta   Bottom
               shortm
wait2          lda   >$E0C02E
               cmp   Bottom
               bne   wait2
               longm
               jsr   CopyShape

               DefineStack
oldDP          word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

               phd                      check if keypress, mouse click, etc
               tsc
               tcd
               lda   [MovePtr]
               jne   done
               pld

               lda   Action
               beq   down_right
               cmp   #1
               beq   up_right
               cmp   #2
               beq   down_left
               cmp   #3
               beq   up_left

               brl   exitWithBeep       <- shouldn't ever be called..

up_left        anop
               lda   y
               dec   a
               jeq   downLeftNext
               sta   y

               lda   x
               dec   a
               jeq   upRightNext
               sta   x
               bra   next

down_left      anop
               lda   y
               inc   a
               cmp   #199-56
               jeq   upLeftNext
               sta   y

               lda   x
               dec   a
               jeq   downRightNext
               sta   x
               bra   next

up_right       anop
               lda   y
               dec   a
               jeq   downRightNext
               sta   y

               lda   x
               inc   a
               cmp   #160-28
               jeq   upLeftNext
               sta   x
               bra   next

down_right     anop
               lda   y
               inc   a
               cmp   #199-56
               jeq   upRightNext
               sta   y

               lda   x
               inc   a
               cmp   #160-28
               jeq   downLeftNext
               sta   x

next           anop

               lda   twice
               beq   noIncShape

               lda   CurrShape
               inc   a
               cmp   numShapes
               bne   fine
               lda   #0
fine           sta   CurrShape
               stz   twice
               brl   mainloop

noIncShape     anop
               lda   #1
               sta   twice
               brl   mainloop

done           pld
               brl   Exit

MemoryErr2     anop
               _CloseGS CloseParams     close picture
MemoryErr0     anop
               lda   MemoryString       get length byte
               and   #$00FF
               inc   a
               sta   <$FE
               jsr   GetMemory
               shortm
               ldx   #0
               txy
copyStr        anop
               lda   MemoryString,x
               sta   [$F0],y
               inx
               iny
               cpx   <$FE
               blt   copyStr
               longm
               jsr   ErrorBeep
               brl   Exit2

SFStartErr0    anop
               lda   StartupString      get length byte
               and   #$00FF
               inc   a
               sta   <$FE
               jsr   GetMemory
               shortm
               ldx   #0
               txy
copyStr2       anop
               lda   StartupString,x
               sta   [$F0],y
               inx
               iny
               cpx   <$FE
               blt   copyStr2
               longm
               jsr   ErrorBeep
               brl   Exit2

GSOSErr2       anop
               _CloseGS CloseParams     close picture
GSOSErr0       anop
               lda   NotFoundString      get length byte
               and   #$00FF
               inc   a
               sta   <$FE
               jsr   GetMemory
               shortm
               ldx   #0
               txy
copyStr3       anop
               lda   NotFoundString,x
               sta   [$F0],y
               inx
               iny
               cpx   <$FE
               blt   copyStr3
               longm
               jsr   ErrorBeep
               brl   Exit2

BadATFFile     anop
               lda   BadCountString      get length byte
               and   #$00FF
               inc   a
               sta   <$FE
               jsr   GetMemory
               shortm
               ldx   #0
               txy
copyStr4       anop
               lda   BadCountString,x
               sta   [$F0],y
               inx
               iny
               cpx   <$FE
               blt   copyStr4
               longm
               jsr   ErrorBeep
               bra   Exit2

BadAPFFile     anop
               lda   BadAPFString      get length byte
               and   #$00FF
               inc   a
               sta   <$FE
               jsr   GetMemory
               shortm
               ldx   #0
               txy
copyStr5       anop
               lda   BadAPFString,x
               sta   [$F0],y
               inx
               iny
               cpx   <$FE
               blt   copyStr5
               longm
               jsr   ErrorBeep
               bra   Exit2

*exitWithBeep2  anop
*               _CloseGS CloseParams     close picture
exitWithBeep   anop                     do a nifty little beep of mine :)
               jsr   ErrorBeep

exit           Entry
; Shutdown procedures

               stz   ErrHandle
               stz   ErrHandle+2

exit2          Entry
               lda   SFStatus
               bne   wuzActiveAt1st
               _SFShutDown
               PushWord #$17
               _UnloadOneTool

wuzActiveAt1st anop
               PushLong OldPort
               _SetPort                 restore original port

               PushWord RezFileID
               _CloseResourceFile

               _ResourceShutDown

               PushWord OldResourceFile
               _SetCurResourceFile

               PushWord OldResourceApp
               _SetCurResourceApp

               pei   MyID               dispose all our allocated memory
               _DisposeAll

*               _CloseGS CloseParams     make sure all files are closed

               plb
               lda   2,s
               sta   12,s
               lda   1,s
               sta   11,s
               tsc                      Remove input paramaters
               clc
               adc   #10                (MasterID+MovePtr+TextPtr)
               tcs
               lda   >ErrHandle
               ora   >ErrHandle+2
               beq   noErrs
ErrOccurred    anop
               ldy   #$DEAD
               lda   >ErrHandle+2
               tax
               lda   >ErrHandle
               sec
               rtl
noErrs         anop
               lda   #0
               tay
               tax
               clc
               rtl

GetMemory      anop
               LongResult
               pea   0                  push hi word of zero
               pha
               pei   MasterID
               PushWord #attrLocked+attrFixed+attrNoSpec+attrNoCross
               PushLong #0
               _NewHandle
               pla
               sta   <$F0
               sta   ErrHandle
               pla
               sta   <$F2
               sta   ErrHandle+2
               lda   [$F0]
               tax
               ldy   #2
               lda   [$F0],y
               sta   <$F2
               stx   <$F0
               rts

ErrorBeep      anop
               php
               sei
               ldx   #95
click1         lda   >Spkr
               lda   #440
middleC        dec   a
               bne   middleC
click2         lda   >Spkr
               lda   #300
anotherkey     dec   a
               bne   anotherkey
               dex
               bne   click1
               plp
               rts


upRightNext    anop
               lda   #1
               sta   Action
               brl   next
downLeftNext   lda   #2
               sta   Action
               brl   next
downRightNext  stz   Action
               brl   next
upLeftNext     lda   #3     
               sta   Action
               brl   Next

CopyShape      anop
               lda   y
               sta   CurrY
               lda   x
               sta   CurrX

               lda   #56
               sta   Depth

copyLoop       anop
               lda   CurrY              y = y coordinate
               asl   a                  multipy by 2 to get index into table
               tay
               lda   [SLookUp],y        get address from table
               clc                      add x to base address
               adc   CurrX              x = horizontal position (in bytes)
               sta   Fill+1

               ldx   #0
               ldy   YSave
copyLine       lda   [PicPtr],y
fill           sta   $E12000,x
               iny
               iny
               inx
               inx
               cpx   #28                28 bytes wide
               bne   copyLine

               lda   YSave
               clc
               adc   #$A0               1 line down into shape
               sta   YSave

               inc   CurrY              store 1 line down into SHR

               dec   depth
               bne   copyLoop

               rts


! This routine helps us find the MAIN block in the APF file..
notpref        anop
               ldy   #2                   we're merely
               lda   [PackedPtr],y           going to add
               tay                        the block size of this "chunk"
               lda   [PackedPtr]             which is held in the
               clc                        first 4 bytes of
               adc   PackedPtr               the apple preferred format
               sta   PackedPtr               to the buffer address, and
               tya                        if we've reached
               adc   PackedPtr+2             the end of the
               sta   PackedPtr+2             file, we are
               lda   PackedPtr               done!
               cmp   endfile
               lda   PackedPtr+2
               sbc   endfile+2
               jcc   checkmain

               brl   exit               if no MAIN chunk found, there is no
;                                        picture data, so abort
               End
*-----------------------------------------------------------------------------*
GlobalDATA     Data

screenHandle   dc    i4'0'
screenLength   dc    i2'0'

*MyString       Entry
*               ds    257

!name           entry
!               ds    33

!ame           GSStr '*:system:cdevs:twilight:frames'

openParams     anop
               dc    i'12'              pcount
openID         ds    2                  reference number
*               dc    i4'MyString'       pathname of file to open
pathname       dc    i4'0'
               dc    i'0'               request_access
               dc    i'0'               resource_num
               ds    2                  access
               ds    2                  file_type
               ds    4                  aux_type
               ds    2                  storage_type
               ds    8                  create_td
               ds    8                  modify_td
               ds    4                  option_list
eof            ds    4

readParams     anop
               dc    i'4'
readID         ds    2                  reference number
picDestIN      ds    4                  pointer to DATA buffer
readLength     ds    4                  this many bytes
               ds    4                  how many xfered

closeParams    anop
               dc    i'1'
closeID        ds    2                  reference number

QParms         dc    i4'0'
               dc    i'0'

palettenum     ds 2                     ; offset into palettes from preferred
width          ds 2                     ; width of preferred file
preftemp       ds 2                     ; temporary Apple Preferred format cntr
scbnum         ds 2                     ; number of SCB we're on
endfile        ds 4                     ; end of buffer for Preferred

*TempPal        ds    32

AddrTable      anop
               dc    i'Shape1start,shape2start,shape3start,shape4start'
               dc    i'shape5start,shape6start,shape7start,shape8start'
               dc    i'shape9start,shape10start,shape11start,shape12start'
               dc    i'shape13start,shape14start'
               dc    i'shape15start,shape16start,shape17start,shape18start'
               dc    i'shape19start,shape20start,shape21start,shape22start'
               dc    i'shape23start,shape24start,shape25start,shape26start'
               dc    i'shape27start,shape28start'

oldResourceApp ds    2
oldResourceFile ds   2
oldPort        ds    4
RezFileID      ds    2
ErrHandle      ds    4
NotFoundString str   '$8000: Animation template file loading error.'
BadCountString str   '$8001: Number of frames not marked correctly.'
BadAPFString   str   '$8002: APF animation picture is unusable.'
MemoryString   str   '$8003: Unable to allocate necessary memory.'
StartupString  str   '$8004: Unable to startup StandardFile tool.'

               End
*-----------------------------------------------------------------------------*
StartUp        Start
               Using GlobalDATA

; Startup procedures

               DefineStack
rtsAddress     word
oldBank        byte
returnAddress  block 3
MainID         word
MovePtr        long
ourPathname    long

               lda   MainID,s
               sta   MasterID
               ora   #$0A00
               sta   MyID

               lda   ourPathname,s
               sta   ourPath
               lda   ourPathname+2,s
               sta   ourPath+2

               LongResult               get lookup table
               PushWord #1              lookup table code
               _GetAddress
               PullLong SLookUp         get pointer to table

               LongResult
               _GetPort
               PullLong OldPort

*! If we've been called in 320 mode than change the data areas in our code that
*! assume we're in 640 mode.
*               lda   #320
*               sta   mode
*               lda   #40                was 30
*               sta   fillX+1

               WordResult
               _GetCurResourceApp
               PullWord OldResourceApp

               WordResult
               _GetCurResourceFile
               PullWord OldResourceFile

               PushWord MyID
               _ResourceStartUp

               WordResult
               PushWord #1              request read access
               PushLong #0              open a new file
               PushLong OurPath
               _OpenResourceFile
               plx
               stx   RezFileID
*               jcs   Error

               LongResult
               PushWord #rC1InputString
               PushLong #SavedPathC1IStr
               _LoadResource
               PullLong TempDP
               ldy   #2
               lda   [TempDP]
               sta   PathName
               lda   [TempDP],y
               sta   PathName+2
               rts

               End
*-----------------------------------------------------------------------------*