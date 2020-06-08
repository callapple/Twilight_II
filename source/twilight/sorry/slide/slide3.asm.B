
*-----------------------------------------------------------------------------*
! DYA Demo Shell.
!
!  Version 0.1, 07/17/90: First version recorded.
!
! Copyright 1990, Jim Maricondo.
*-----------------------------------------------------------------------------*
               mcopy Slide.Mac
               copy  7:e16.memory
               copy  7:e16.event
*-----------------------------------------------------------------------------*
Strobe         gequ  $E0C000            addr of keyboard strobe register
ClearStrobe    gequ  $E0C010            access to clear keypress
VBLWait        gequ  $E0C019            bit 7 = 1 if not VBL
Screen         gequ  $E0C022            addr of text/background color register
NewVideo       gequ  $E0C029            addr of NewVideo register
Border         gequ  $E0C034            addr of border color register

oHeight        gequ  $0                 height's offset into file
oWidth         gequ  $2                 width's offset into file
oPalette       gequ  $4                 palette's offset into file
oGraphic       gequ  $24                graphic's offset into file

fadeDelay      gequ  $2F00              how fast to fadein/out (greater=slower)

SHRBank        gequ  $E1                bank to do our drawing
SHRBankMem     gequ  $E12000
SHRSize        gequ  $8000              size of SHR screen

ztemp1         gequ  0                  temporary pointers
ztemp2         gequ  ztemp1+4
ztemp3         gequ  ztemp2+4
PicPtr         gequ  ztemp3+4           pointers to packed picture data
MyID           gequ  PicPtr+4           additional ID for extra memory
SCBPtr         gequ  MyID+2
DYAPtr         gequ  SCBPtr+4
WidthTemp      gequ  DYAPtr+4
HeightTemp     gequ  WidthTemp+2
oldscreen      gequ  HeightTemp+2
oldborder      gequ  oldscreen+2
buffer1        gequ  oldborder+2
buffer2        gequ  buffer1+4
*-----------------------------------------------------------------------------*
MainEntry      Start
               Using MainDATA

               phb                      Store old data bank
               phk
               plb

               jsr   StartUp
               jsr   GetDirPath

               _OpenGS Open_Prms        open the directory file
               lda   ref_num
               sta   ref_num1
               sta   ref_num2

Read_Dir       anop
               _GetDirEntryGS GDE_Prms
               bcs   exit

               lda   filetype
               cmp   #$C0
               beq   contC0
               cmp   #$C1
               beq   contC1
               cmp   #$99
               beq   contDYA
               bra   read_dir

ContC0         anop
               lda   auxtype
               beq   PaintWorks         if auxtype = $0000, then it's PW+ form
               cmp   #$0001
               beq   Image              if auxtype = $0001, then it's IMG form
               cmp   #$0002             if auxtype < > $0002 then it's not 
               bne   read_dir            supported

               jsr   LoadAPF
               bcc   show
               bra   read_dir

PaintWorks     anop
               jsr   LoadPW
               bra   show
Image          anop
               jsr   LoadIMG
               bra   show
ContC1         anop
               lda   auxtype
               cmp   #$0000
               bne   read_dir
               jsr   LoadC1
               bra   show
ContDYA        anop
               lda   auxtype
               cmp   #$DEAD
               bne   read_dir
               jsr   loadDYA

Show           anop
               jsr   FadeIn

               DefineStack
oldDirectPage  word
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

               lda   #$E000
delay          anop
               pha
               phd

               tsc
               tcd
               lda  [MovePtr]
               bne  done

               pld
               pla
               dec   a
               bne   delay

NextPic        anop
               jsr   FadeOut
               bra   read_dir

Done           anop
               pld
               pla
               jsr   FadeOut

Exit           _CloseGS  Close_Prms     close directory file

quit           Entry
               shortm
               lda   #$41               turn off SHR
               sta   >NewVideo
               longm

               jsr   RestoreText

               _CloseGS CloseParams     close picture

               pei   MyID               dispose all our allocated memory
               _DisposeAll


               End
*-----------------------------------------------------------------------------*
StartUp        Start

               DefineStack
rtsAddress     word
oldBank        byte
rtlAddress     block 3
MainID         word
MovePtr        long
TextPtr        long

               lda   >ClearStrobe       reset strobe
               shortm
               lda   >Screen
               sta   OldScreen
               lda   >Border
               and   #$0F
               sta   OldBorder
               lda   #0
               sta   >Screen
               lda   >Border
               and   #$F0
               sta   >Border
               longm

               shortm                   turn off SHR
               lda   #$41
               sta   >NewVideo
               longm

               lda   MainID,s
               ora   #$0100
               sta   MyID

               LongResult
               PushLong #$400
               pei   MyID
               PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   ztemp3
               plx
               stx   ztemp3+2
               jcs   MemoryError

               lda   [ztemp3]
               sta   buffer1
               ldy   #2
               lda   [ztemp3],y
               sta   buffer1+2

               LongResult
               PushLong #$400
               pei   MyID
               PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   ztemp3 
               plx
               stx   ztemp3+2
               jcs   MemoryError

               lda   [ztemp3]
               sta   buffer2
               ldy   #2
               lda   [ztemp3],y
               sta   buffer2+2

               lda   #0
               ldy   #$400-2
zero0          sta   [buffer1],y
               sta   [buffer2],y
               dey
               dey
               bpl   zero0

               rts

               End
*-----------------------------------------------------------------------------*
GetDirPath     Start
               using MainDATA

               DefineStack
oldDirectPage  word
rtsAddress     word
oldBank        byte
rtlAddress     block 3
MainID         word
MovePtr        long
TextPtr        long

               phd
               tsc
               tcd

               shortmx
               lda   [TextPtr]          get length byte of P-String
               sta   MyFile             put leading length word
               stz   MyFile+1            in input string
               ldy   #0                 copy filename to openparams
               inc   <TextPtr           make ptr point one byte over
back           anop
               lda   [TextPtr],y
               sta   MyFile+2,y
               iny
               cpy   MyFile
               blt   back
               longmx

               pld
               rts

               End
*-----------------------------------------------------------------------------*
RestoreText    Start

               shortm
               lda   oldscreen
               sta   >Screen
               lda   >Border
               and   #$F0
               ora   oldborder
               sta   >Border
               longm
               rts

               End
*-----------------------------------------------------------------------------*
LoadDYA        Start
               Using MainDATA

               ldx   #$7D00-2          clear SHR display buffer
               lda   #0
zero           sta   $E12000,x
               dex
               dex
               bpl   zero

               _OpenGS OpenParams       open Mother Earth console
               jcs   Error1

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
               stx   ztemp1
               plx
               stx   ztemp1+2
               jcs   MemoryError

               lda   [ztemp1]
               sta   PicPtr
               sta   PicDestIN
               ldy   #2
               lda   [ztemp1],y
               sta   PicPtr+2
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   Error1

               LongResult
               lda   #0
               pha
               lda   [PicPtr]
               pha
               pei   MyID
               PushWord #attrLocked+attrFixed+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   ztemp3
               plx
               stx   ztemp3+2
               jcs   MemoryError

               lda   [ztemp3]
               sta   DYAPtr
               ldy   #2
               lda   [ztemp3],y
               sta   DYAPtr+2

               WordResult
               lda   PicPtr+2
               pha
               lda   PicPtr
               inc   a
               inc   a
               pha
               lda   eof
               dec   a
               dec   a
               pha
               PushLong zTemp3
               lda   [PicPtr]
               sta   TempSize
               PushLong #TempSize
               _UnPackBytes
               pla

               PushLong ztemp1
               _DisposeHandle

               ldx   #0
               txa
zeroSCB        sta   $E19D00,x
               inx
               inx
               cpx   #$C8
               bne   zeroSCB

               ldx   #0
               ldy   #oPalette
copyPalette    lda   [DYAPtr],y
               sta   $E19E00,x
               inx
               inx
               iny
               iny
               cpx   #32
               bne   copyPalette

               ldy   #oWidth
               lda   [DYAPtr],y
               sta   WidthTemp
               ldy   #oHeight
               lda   [DYAPtr],y
               sta   HeightTemp

               lda   #$2000
               sta   fill+1             init fillin value
               ldy   #oGraphic
               ldx   #0
copy1Line      lda   [DYAPtr],y
fill           sta   $E12000,x
               inx
               inx
               iny
               iny
               cpx   WidthTemp
               bne   copy1Line

               dec   HeightTemp
               beq   return

               lda   fill+1             load the $2000
               clc
               adc   #$A0
               sta   fill+1
               ldx   #0
               bra   copy1line

return         anop

               PushLong ztemp3          dispose unpacked data too
               _DisposeHandle

               rts

               End
*-----------------------------------------------------------------------------*
LoadAPF        Start
               Using MainDATA

               _OpenGS OpenParams       open Image packed picture
               jcs   Error1

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
               stx   ztemp1
               plx
               stx   ztemp1+2
               jcs   MemoryError

               lda   [zTemp1]
               sta   PicPtr
               sta   PicDestIN
               ldy   #2
               lda   [zTemp1],y
               sta   PicPtr+2
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   Error1

               _CloseGS CloseParams
               jcs   Error1

               lda   eof                  load filesize
               clc                        and add to it the beginning
               adc   PicPtr               of the file buffer
               sta   endfile              so we have the END of the file

               lda   eof+2
               clc                        just do the same for the high
               adc   PicPtr+2             byte
               sta   endfile+2

checkmain      ldy   #5                   load the 5th byte of the data
               lda   [PicPtr],y
               and   #$7F7F               mask off the HIGH bits
               cmp   #$414D               is it a "MA"?
               jne   notpref              nope, this isn't the correct block
               iny                         or file
               iny
               lda   [PicPtr],y           get the next two bytes
               cmp   #$4E49               is it a "IN"?
               jne   notpref              nope

               ldy   #11                (pixelsperscanline)
               lda   [PicPtr],y         get the width of the picture
               sta   width

               cmp   #320               is it 320 mode?
               beq   pref2              yes
               cmp   #640               is it 640 mode?
               beq   pref2              yes

               sec                      if it's neither, than we don't support
               rts                       it, so abort this picture

pref2          ldy   #9
               lda   [PicPtr],y           get the master mode
               sta   preftemp             store it
               xba                        move it into the high byte also
               ora   preftemp             so it'll be $0X0X
               and   #$F0F0               and just to make sure mask the high

               ldx   #0                   nibbles off
pref3          sta   $E19D00,x            store this master mode Scan Contro
               inx                        Byte into the enter SCBs
               inx                        data buffer
               cpx   #$C8                 have we gone to 200 bytes yet?
               bne   pref3                nope

               LongResult
               ldy   #13                  get the number of palettes
               lda   [PicPtr],y
               pha                        multiply it by 32 bytes, which is
               PushWord #$0020            how many bytes per palette
               _Multiply
               pla                        pull the result
               sta   palettenum           store it as the byte offset past the
               clc                        palettes information
               adc   #17                  add 17 to it to make it correct
               sta   preftemp             store it as the preferred temp area
               plx

               lda   PicPtr
               clc                        load the 0 direct page space, and
               adc   preftemp             add to it the data grabbed and store
               sta   SCBPtr               it at $04 DP space.  Now we have
               lda   PicPtr+2             a pointer to the SCBs information
               sta   SCBPtr+2             contained in the file!!!

               ldy   preftemp             load the pointer to the SCBs area
               dey                        and subtract 2 from it so we
               dey                        get the number of scb's
               lda   [PicPtr],y           get the number of SCBs in the file
               cmp   #257                 is it greater than 256?
               blt   scbsok               yes
               lda   #256                 no more than 256 SCBs
scbsok         sta   scbnum               store it as the # of SCBs
               ldx   #0                   initialize some counters
               ldy   #2
scbs_set       anop
               lda   [SCBPtr],y           move the individual SCBs in the file
               sta   $E19D00,x
               iny
               iny
               iny
               iny                ; we just did a double check by using
               inx                ; both the Master SCB and the individual SCBs
               cpx   scbnum
               blt   scbs_set

               lda   palettenum           load the pointer to the SCBs
               sta   preftemp             and store it for future reference

               ldx   #0
               ldy   #13                  initialize counters
pref5          iny
               iny
               lda   [PicPtr],y           we're just going to move the
               sta   $E19E00,x            palettes from the file into the
               inx                        actual palettes area ($E19E00)
               inx  
               lda   palettenum           decrement the palette size
               dec   a
               dec   a
               sta   palettenum           are we done yet?
               bne   pref5                no

               lda   preftemp             we're done
               clc                        adjust the SCBs pointer to skip
               adc   #15                  the first bytes
               tay
               lda   [PicPtr],y           load the number of SCBs
               iny
               iny
               tax
               tya
pref6          clc
               adc   #4                   and adjust the pointer to
               dex                        skip the entire SCBs area since
               bne   pref6                we've already worked with it
               sta   preftemp             and finally point to the packed data!

               lda   #$2000             reset where to unpack as Unpackbytes
               sta   ScreenHandle        thrashes this info (how rude!! :)
               lda   #SHRBank
               sta   ScreenHandle+2

               lda   #$7D00             the size of the screen for
               sta   ScreenLength        unpacking purposes

               WordResult
               lda   PicPtr+2           push hi byte of buffer containing
               pha                       the packed data
               lda   PicPtr               load the original buffer
               clc
               adc   preftemp             add the number of bytes to skip
               pha
               lda   eof                  load the filesize
               sec                        and subtract from it the
               sbc   preftemp             number of bytes to skip
               pha
               PushLong #ScreenHandle     push handle to screen
               PushLong #ScreenLength     push pointer to screen size word
               _UnPackBytes
               pla                        discard result

               PushLong zTemp1         get rid of packed data buffer
               _DisposeHandle

               clc
               rts

! This routine helps us find the MAIN block in the APF file..
notpref        anop
               ldy   #2                   we're merely
               lda   [PicPtr],y           going to add
               tay                        the block size of this "chunk"
               lda   [PicPtr]             which is held in the
               clc                        first 4 bytes of
               adc   PicPtr               the apple preferred format
               sta   PicPtr               to the buffer address, and
               tya                        if we've reached
               adc   PicPtr+2             the end of the
               sta   PicPtr+2             file, we are
               lda   PicPtr               done!
               cmp   endfile
               lda   PicPtr+2
               sbc   endfile+2
               jcc   checkmain

               sec                      if no MAIN chunk found, there is no
               rts                       picture data, so abort

               End
*-----------------------------------------------------------------------------*
LoadPW         Start
               Using MainDATA

               _OpenGS OpenParams       open Image packed picture
               jcs   Error1

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
               stx   ztemp1
               plx
               stx   ztemp1+2
               jcs   MemoryError

               lda   [zTemp1]
               sta   PicPtr
               sta   PicDestIN
               ldy   #2
               lda   [zTemp1],y
               sta   PicPtr+2
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   Error1

               _CloseGS CloseParams     close picture
               jcs   Error1

               ldy   #0
p_palette      tyx                      
               lda   [PicPtr],y          move the palette from the first 32
               sta   $E19E00,x           bytes of the file into the SHR palette
               iny                       area (Palette $0)
               iny
               cpy   #32
               bcc   p_palette

               lda   PicPtr              skip the next $222 bytes that contain
               clc                        patterns, background information, and
               adc   #$222                one nonpacked palette
               sta   PicPtr

               lda   #$2000             reset where to unpack as Unpackbytes
               sta   ScreenHandle        thrashes this info (how rude!! :)
               lda   #SHRBank
               sta   ScreenHandle+2

               lda   #$7D00             the size of the screen for
               sta   ScreenLength        unpacking purposes

               WordResult
               PushLong PicPtr          pointer to packed data buffer
               lda   eof
               sec                      subtract $222 bytes from the filesize
               sbc   #$222               ($202 plus $20 of palettes) and push
               pha                       it as where size of packed data buffer
               PushLong #ScreenHandle   handle to where to unpack to
               PushLong #ScreenLength   ptr to word containing size of unpacked
               _UnPackBytes              data
               pla                      discard result

               PushLong zTemp1         get rid of packed data buffer
               _DisposeHandle

               rts

               End
*-----------------------------------------------------------------------------*
LoadIMG        Start
               Using MainDATA

               _OpenGS OpenParams       open Image packed picture
               jcs   Error1

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
               stx   ztemp1
               plx
               stx   ztemp1+2
               jcs   MemoryError

               lda   [zTemp1]
               sta   PicDestIN
               ldy   #2
               lda   [zTemp1],y
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   Error1

               _CloseGS CloseParams     close picture
               jcs   Error1

               lda   #$2000
               sta   ScreenHandle
               lda   #SHRBank
               sta   ScreenHandle+2

               lda   #SHRSize
               sta   ScreenLength

               WordResult
               ldy   #2                 pointer to packed data buffer
               lda   [zTemp1],y
               pha
               lda   [zTemp1]
               pha
               PushWord eof             size of packed data buffer
               PushLong #ScreenHandle   handle to where to unpack to
               PushLong #ScreenLength   ptr to word containing size of unpacked
               _UnPackBytes              data
               pla

               PushLong zTemp1         get rid of packed data buffer
               _DisposeHandle

               rts

               End
*-----------------------------------------------------------------------------*
LoadC1         Start
               Using MainDATA

               _OpenGS OpenParams       open unpacked picture
               jcs   Error1

               lda   OpenID
               sta   ReadID
               sta   CloseID

               lda   eof
               sta   readLength

               lda   #$2000
               sta   PicDestIN
               lda   #$E1
               sta   PicDestIN+2

               _ReadGS ReadParams
               jcs   Error1

               _CloseGS CloseParams     close picture
               jcs   Error1

               rts

               End
*-----------------------------------------------------------------------------*
ErrorHandlers  Start                    handle any errors that occur
               Using ErrorDATA

StartToolError Entry

               pha                      error number
               PushLong #String1
               PushWord #4              number of characters
               _Int2Hex

               shortm                   turn off graphics
               lda   #$41
               sta   >NewVideo
               longm

               jsr   RestoreText

               PushLong #CString1       write error message
               _WriteCString

               bra   returnBack

MemoryError    Entry

               pha
               PushLong #String2
               PushWord #4
               _Int2Hex

               shortm
               lda   #$41
               sta   >NewVideo
               longm

               jsr   RestoreText

               PushLong #CString2
               _WriteCString

               bra   returnBack

Error1         Entry

               pha
               PushLong #String
               PushWord #4
               _Int2Hex

               shortm
               lda   #$41
               sta   >NewVideo
               longm

               jsr   RestoreText

               PushLong #CString
               _WriteCString

!              bra   returnBack

returnBack     anop

               shortm
back           lda   >Strobe
               bpl   back
               sta   >ClearStrobe
               longm

               sec
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data

palettenum     ds 2                     ; offset into palettes from preferred
width          ds 2                     ; width of preferred file
preftemp       ds 2                     ; temporary Apple Preferred format cntr
scbnum         ds 2                     ; number of SCB we're on
endfile        ds 4                     ; end of buffer for Preferred

ScreenHandle   dc    i4'SHRBankMem'
ScreenLength   dc    i'$8000'

SSRecRefRet    ds    4

openParams     anop
               dc    i'12'              pcount
openID         ds    2                  reference number
               dc    i4'name'           pathname of file to open
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

QParms         dc    i4'0'
               dc    i'0'

TempSize       ds    2

readParams     anop
               dc    i'4'
readID         ds    2                  reference number
picDestIN      ds    4                  pointer to DATA buffer
readLength     ds    4                  this many bytes
               ds    4                  how many xfered

closeParams    anop
               dc    i'1'
closeID        ds    2                  reference number

Open_Prms      anop
               dc    i'2'               pcount
ref_num        ds    2
Name_Ptr       dc    i4'MyFile'         pointer to directory

MyFile         ds    33
!irectory      GSStr '0/'

Close_Prms     anop
               dc    i'1'               pcount
ref_num1       ds    2

GDE_Prms       anop
               dc    i'13'              pcount
ref_num2       ds    2
               ds    2                  flags
               dc    i'1'               base: increment
               dc    i'1'               displacement = +1
               dc    i4'NameBuff'       name_buffer ptr
               ds    2                  entry_num
filetype       ds    2
               ds    4                  eof
               ds    4                  block_count
               ds    8                  create_td
               ds    8                  modify_td
               ds    2                  access
auxtype        ds    4

NameBuff       dc    i'30'              buffer size
name           ds    2                  length
               ds    28                 filename

               End
*-----------------------------------------------------------------------------*
ErrorDATA      Data

CString        dc    c'GS/OS error $'
string         dc    c'???? occured.',h'0d0a00'

CString1       dc    c'StartUpTools error $'
string1        dc    c'???? occured.',h'0d0a00'

CString2       anop
 dc c'Unable to allocate picture memory.',h'0d0a',c'Making sure filetype is S16'
               dc    c', and purging memory may help.',h'0d0a0d0a'
               dc    c'Memory Manager error $'
string2        dc    c'???? occured.',h'0d0a00'

               End
*-----------------------------------------------------------------------------*
FadeIn         Start
               Using FadeDATA

               php                      save old processor status register

               longa off
               longi on

               shortm

               lda   #$41               linearize and turn off SHR screen
               sta   >NewVideo

               ldx   #$01FF
               ldy   #$03FF

repeat0        lda   $E19E00,x          copy0 palettes into buffer
               and   #$F0

               lsr   a
               lsr   a
               lsr   a
               lsr   a

               sta   [buffer2],y
               dey

               lda   $E19E00,x
               and   #$0F
               sta   [buffer2],y

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
zero           sta   $E19E00-2,x
               dex
               dex
               bne   zero

               shortm

               lda   #$C1               turn on SHR screen
               sta   >NewVideo

finish         anop

               longm

dvalIn         lda   #FadeDelay         delay so that we don't fade too fast
delay          dec   a
               bne   delay

               shortm

               bra   fade

quit           anop

               plp                      restore old processor status register

               rts

               longi on
               longa off

fade           anop

               shortm                   just to be on the safe side

               jsr   prepare            fade palettes in buffer

waitVBL        lda   >VBLWait
               bpl   waitVBL
wait2          lda   >VBLWait
               bmi   wait2

               jsr   fadeIt             store buffer data to palettes

               dec   amount             done 16 times yet?
               beq   quit

               bra   finish

prepare        anop

               ldy   #$03FF

repeat         anop
               lda   [buffer1],y
               clc
               adc   [buffer2],y
               sta   [buffer1],y
               dey
               bpl   repeat

               rts

fadeIt         anop

               ldx   #$01FF
               ldy   #$03FE

more           lda   [buffer1],y

               lsr   a
               lsr   a
               lsr   a
               lsr   a

               sta   temp

               phy
               iny
               lda   [buffer1],y
               and   #$F0
               ora   temp
               sta   $E19E00,x
               ply

               dey
               dey
               dex
               bpl   more

               rts

               End
*-----------------------------------------------------------------------------*
FadeOut        Start
               Using FadeDATA

               longa off
               longi on

               php

               shortm

               lda   #$C1
               sta   >NewVideo

               ldx   #$01FF
               ldy   #$03FF

repeat0        lda   $E19E00,x
               and   #$F0
               sta   [buffer1],y

               lsr   a
               lsr   a
               lsr   a
               lsr   a

               sta   [buffer2],y
               dey

               lda   $E19E00,x
               and   #$0F
               sta   [buffer2],y

               asl   a
               asl   a
               asl   a
               asl   a

               sta   [buffer1],y

               dey
               dex
               bpl   repeat0

               lda   #16
               sta   amount

finish         anop

               longm

dvalOut        lda   #FadeDelay
delay          dec   a
               bne   delay

               shortm

               bra   fade

quit           anop
               lda   #$41
               sta   >NewVideo

               plp

               rts

               longi on
               longa off

fade           anop

               shortm

               jsr   prepare

waitVBL        lda   >VBLWait
               bpl   waitVBL
wait2          lda   >VBLWait
               bmi   wait2

               jsr   fadeIt

               dec   amount
               beq   quit

               bra   finish

prepare        anop

               ldy   #$03FF

repeat         anop
               lda   [buffer1],y
               sec
               sbc   [buffer2],y
               sta   [buffer1],y
               dey
               bpl   repeat

               rts

fadeIt         anop

               ldx   #$01FF
               ldy   #$03FE

more           lda   [buffer1],y

               lsr   a
               lsr   a
               lsr   a
               lsr   a

               sta   temp

               phy
               iny
               lda   [buffer1],y
               and   #$F0
               ora   temp
               sta   $E19E00,x
               ply

               dey
               dey
               dex
               bpl   more

               rts

               End
*-----------------------------------------------------------------------------*
FadeDATA       Data

amount         ds    1
temp           ds    1

               End
*-----------------------------------------------------------------------------*
