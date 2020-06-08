*------------------------------------------------*
*                                                *
*                Movie Theater                   *
*                                                *
*             A Twilight II Module               *
*                                                *
*               By Derek Young                   *
*                                                *
* V1.0 - DY with code from JRM.                  *
* V1.1 - 4 Jan 93 JRM                            *
* V1.1.1 - 12 Jan 93 JRM                         *
* V1.1.2 - 28 Jan 93 JRM (Debugged for Test)     *
* v1.1.3 - 30 Jan 93 JRM (MMStartUp)             *
*------------------------------------------------*
* remember to turn debugging labels off!

 lst off
 rel
 xc
 xc
 mx %00
 use Moviet.macs

TRUE = $FFFF
rWString = $8022
singleHandle = 1
rTextForLETextBox2 = $800B
rControlTemplate = $8004
resourceToResource = 9
refIsHandle = 1
refIsPointer = 0

 dum 0
PicPtr adrl 0
DataPtr adrl 0 ;space for the animation routine
StartAddress adrl 0
EndAddress adrl 0
delay da 0

MovePtr adrl 0 ;indicates movement (time to unblank!)
 dend

 dum 1
Bank db 0 ;This is how the stack is set up
rtlAddr adr 0 ;with DP at the top and Result
T2data2 adrl 0 ;occupying the top four bytes
T2data1 adrl 0
T2Message da 0
T2Result adrl 0
T2StackSize adrl 0
 dend

Screen = $E12000
SHADOW = $E0C035

*-------------------------------------------------
* NewHandle attributes
attrNoPurge equ $0000 ; Handle Attribute Bits - Not purgeable
attrBank equ $0001 ; Handle Attribute Bits - fixed bank
attrAddr equ $0002 ; Handle Attribute Bits - fixed address
attrPage equ $0004 ; Handle Attribute Bits - page aligned
attrNoSpec equ $0008 ; Handle Attribute Bits - may not use speci
attrNoCross equ $0010 ; Handle Attribute Bits - may not cross ba
attrFixed equ $4000 ; Handle Attribute Bits - not movable
attrLocked equ $8000 ; Handle Attribute Bits - locked
*-------------------------------------------------
* start of the blanker...

MakeT2 = 0
SaveT2 = 1
BlankT2 = 2
LoadSetUpT2 = 3
UnloadSetUpT2 = 4
KillT2 = 5
HitT2 = 6

Start
 phb
 phk
 plb

 lda T2Message,s
 cmp #BlankT2 ;must be BlankT2
 beq :Blank
 cmp #MakeT2
 beql doMake
 cmp #KillT2
 beql doKill
 cmp #HitT2
 beql doHit
 cmp #SaveT2
 beql doSave
 cmp #LoadSetUpT2
 beql doLoadSetup
 cmp #UnloadSetUpT2
 beql doUnloadSetup
 brl Bye

:Blank
 lda T2Data1,s
 sta MovePtr ;save this in our own DP
 lda T2Data1+2,s
 sta MovePtr+2

* lda T2Data2,s
* sta RezFileID

* lda T2Data2+2,s ;our memory ID
* sta MyID
* clc
* adc #$100
 ~MMStartUp
 pla
 sta MyID
 ora #$0100
 sta MemID ;need a memory ID

*-------------------------------------------------
* The start of the program...

Blank
 lda #0
 sta T2Result,s
 sta T2Result+2,s ;the result (nil for no error)

 lda AnimHandle
 ora AnimHandle+2
 beq Error ;error occurred while loading the file!

 lda ErrorNum
 bne Error

* let moviet use shadowing if we've got it!

 lda #$E1
 sta ScreenPtr+2

 sep $30
 ldal SHADOW
 rep $30
 bit #$08
 bne noShadow
 lda #$01
 sta ScreenPtr+2

noShadow
 lda ScreenPtr+2
 sep $30
 sta screenFill+3
 rep $30


 PushLong AnimHandle
 jsr makePdp
 pld
 PullLong PicPtr
 jsr PlayAnimation

 brl Bye

Error ;error while loading the file!
 ~HexIt RealError
 pla
 sta err1num
 sta err2num
 sta err3num
 sta err4num
 pla
 sta err1num+2
 sta err2num+2
 sta err3num+2
 sta err4num+2

 lda ErrorNum
 cmp #5 ;errors 1 through 4 are good
 bge :unknown

 dec  ;make that 0 through 3
 asl
 tax
 phx ;save this for a moment

 pha
 pha ;result space
 pea 0
 lda Errorlengths,x ;size
 pha
* PushWord MemID ;memory ID
 ~MMStartUp
 pla
 ora #$0F00
 pha
 PushWord #$8000 ;attributes
 PushLong #0 ;location
 _NewHandle
 PullLong ErrorHand

 plx
 pea #^Errors
 lda Errors,x
 pha ;pointer
 PushLong ErrorHand ;handle
 pea 0
 lda Errorlengths,x
 pha  ;size
 _PtrToHand  ;copy the string into the handle

 lda ErrorHand
 sta T2Result,s
 lda ErrorHand+2
 sta T2Result+2,s

:unknown


Bye lda RTLaddr,s ;move up RTL address
 sta T2data1+3,s
 lda RTLaddr+1,s
 sta T2data1+3+1,s

 plb ;restore the bank

 tsc ;remove the input parameters.
 clc
 adc #10
 tcs

 clc
 rtl

MyID da 0
MemID da 0

ScreenPtr adrl $e12000

* errors that can be returned

ErrorHand adrl 0
Errors da err1
 da err2
 da err3
 da err4

Errorlengths
 da err2-err1
 da err3-err2
 da err4-err3
 da endoferrors-err4

err1 asc D2'Movie Theater:'D3' Error $'
err1num asc 'XXXX'0D'The animation pathname has not been set up!'00
err2 asc D2'Movie Theater:'d3' Error $'
err2num asc 'XXXX'0D'The animation file could not be found!'00
err3 asc d2'Movie Theater:'d3' Error $'
err3num asc 'XXXX'0D'There was an error loading the file!'00
err4 asc d2'Movie Theater:'d3' Error $'
err4num asc 'XXXX'0D'Not enough memory to load the animation file!'00
endoferrors

 do 0
err1 asc 'Movie Theater: Error $'
err1num asc 'XXXX'0D'The animation pathname has not been set up!'00
err2 asc 'Movie Theater: Error $'
err2num asc 'XXXX'0D'The animation file could not be found!'00
err3 asc 'Movie Theater: Error $'
err3num asc 'XXXX'0D'There was an error loading the file!'00
err4 asc 'Movie Theater: Error $'
err4num asc 'XXXX'0D'Not enough memory to load the animation file!'00
 fin

*------------------------------------------------*
* The format of a PaintWorks animation file ($C2)*
*                                                *
*  Byte             Content                      *
* 0000-7FFF      Screen image of the first frame *
* 8000-8003      Length of animation data block  *
* 8004-8007      Delay time (in ticks)           *
* 8008-EOF       animation data block            *
*------------------------------------------------*

* Call PlayAnimation with a pointer to the animation file in PicPtr.

*-------------------------------------------------

PlayAnimation

 ~BlockMove PicPtr;ScreenPtr;#$8000 ;load in the first frame

 lda PicPtr
 clc
 adc #$8008+4
 sta DataPtr ;setup the pointer to the data block
 sta StartAddress
 lda PicPtr+2
 adc #0
 sta DataPtr+2
 sta StartAddress+2

 ldy #$8000+4
 lda [PicPtr],y
 sta delay ;find the delay between frames

 ldy #$8000
 lda StartAddress
 clc
 adc [PicPtr],y
 sta EndAddress
 pha ;save for a sec...

 ldy #$8000+2
 lda StartAddress+2
 adc [PicPtr],y
 sta EndAddress+2

 pla ;...and restore
 sec
 sbc #4
 sta EndAddress
 lda EndAddress+2
 sbc #0 ;find the address of the end
 sta EndAddress+2

Loop lda [DataPtr] ;the offset into the screen
 bne :doanim

 ldx delay
]loop jsr WaitVBL
 dex
 bne ]loop ;wait that many "ticks"

 lda DataPtr
 clc
 adc #4 ;next offset/word
 sta DataPtr
 bcc :1
 inc DataPtr+2
:1

 lda DataPtr
 cmp EndAddress
 lda DataPtr+2 ;4 byte compare
 sbc EndAddress+2
 blt check

 lda StartAddress
 sta DataPtr ;go back to the beginning of the animation
 lda StartAddress+2
 sta DataPtr+2
 bra check

:doanim tax ;leave the offset in X

 ldy #2
 lda [DataPtr],y
screenFill stal Screen,x ;store the actual change

 lda DataPtr
 clc
 adc #4
 sta DataPtr
 bcc :2
 inc DataPtr+2
:2 bra Loop ;loop until offset is non zero

check
 lda [MovePtr] ;check for any movement
 beq Loop

 rts ;that's it!

* Wait for a VBL to occur.  The period between two VBLs is one tick.

WaitVBL
 sep $20
]V ldal $C019 ;Wait until the VBL is done if it's active
 bmi ]V
]V ldal $C019 ;Wait until it starts again
 bpl ]V
 rep $20
 rts

*-------------------------------------------------
* Setup procedure for the blanker.
* Only one button is checked for which allows the
* user to select the animation pathname.

makeDP mac
 phd
 tsc
 tcd
 eom

debug? = 0

debug mac
 do debug?
 brl xx
 da $7771
 str ]1
 fin
xx eom


CtlList = 5
AnimPath_LText = 2
YDIAnimPathStrCtl = $7000

*-------------------------------------------------
* Make
*
* Create all the buttons in the window

doMake
 lda T2data1+2,s
 sta WindPtr+2 ;our window pointer
 lda T2data1,s
 sta WindPtr
 lda T2data2,s ;our Resource ID
 sta RezFileID
* lda T2data2+2,s ;our memory ID
* sta MyID
 ~MMStartUp
 pla
 sta MyID

 ~NewControl2 WindPtr;#resourceToResource;#CtlList
 plx
 plx

;Make sure we're dealing with the T2pref file.

 ~GetCurResourceFile

 ~SetCurResourceFile RezFileID

;Load the animation path resource.

 ~RMLoadNamedResource #rWString;#rAnimPathname
 bcc :pathThere
 plx
 plx ;setup not saved...
 stz PathHandle
 stz PathHandle+2

 lda #UnknownStr
 sta PathPtr
 lda #^UnknownStr
 sta PathPtr+2
 bra :moveon

:pathThere

 PushWord #rWString ;rtype for _DetachResource
 ~RMFindNamedResource #rWString;#rAnimPathname;#temp ;rID
 _DetachResource

 lda 1,s
 sta PathHandle
 lda 1+2,s
 sta PathHandle+2
 jsr makePdp

 lda [3]
 xba
 sta [3]
 inc 3
 bne :1
 inc 3+2
:1 pld ;ptr to source string

 PullLong PathPtr

:moveon _SetCurResourceFile

 jsr substitute

 lda #4
 sta T2Result,s

return lda RTLaddr,s ;move up RTL address
 sta T2data1+3,s
 lda RTLaddr+1,s
 sta T2data1+3+1,s

 plb ;restore the bank

 tsc ;remove the input parameters.
 clc
 adc #10
 tcs

 clc
 rtl

WindPtr adrl 0 ;pointer to window to draw controls in
RezFileID da 0 ;resource file ID

PathHandle adrl 0 ;handle to pathname

temp adrl 0 ;temporary storage
CompileHandle adrl 0 ;handle to compiled text
ControlHandle adrl 0 ;handle of control
LETextHandle adrl 0 ;handle to LEText box

SubArray  ;substitution array
PathPtr adrl 0 ;pointer to pathname

rAnimPathname str 'Movie Theater: Pathname'

 db 00 ;this space is needed so we can xba the
  ;string length of "UnknownStr"
UnknownStr str '(Unknown.)'

*-------------------------------------------------
* put the filename into *0

substitute
 debug 'substitute'

 pha
 pha
 PushWord #1 ;pascal substitution strings
 PushLong #SubArray

 ~LoadResource #rTextForLETextBox2;#AnimPath_LText
 lda 1,s
 sta LETextHandle
 lda 1+2,s
 sta LETextHandle+2
 jsr makePdp
 pld

 ~GetHandleSize LETextHandle
 pla
 plx ;chuck hi word
 pha
 _CompileText
 PullLong CompileHandle

 ~ReleaseResource #3;#rTextForLETextBox2;#AnimPath_LText

 PushLong PathPtr
 makeDP
 lda 3
 bne :1
 dec 3+2
:1 dec 3
 lda [3]
 xba
 sta [3]
 pld
 ply
 ply

 ~LoadResource #rControlTemplate;#YDIAnimPathStrCtl
 lda 1,s
 sta ControlHandle
 lda 1+2,s
 sta ControlHandle+2
 jsr makePdp
 ldy #$1A ;textRef
 lda CompileHandle
 sta [3],y
 iny
 iny
 lda CompileHandle+2
 sta [3],y

 ldy #$14 ;moreFlags
 lda [3],y
 and #$FFFC
 ora #refIsHandle
 sta [3],y
 pld
 ply
 ply

 pha
 pha
 PushLong WindPtr
 PushWord #singleHandle
 PushLong ControlHandle
 _NewControl2
 plx
 plx
 rts

*-------------------------------------------------
* Save
*
* Save the changes made during setup

doSave debug 'doSave'

 lda PathHandle
 ora PathHandle+2
 bne :notNIL
 brl return

:notNIL

 ~GetCurResourceFile
 ~SetCurResourceFile RezFileID

* get rid of the old pathname if there is one...

 PushWord #rWString ;for RMSetResourceName
 ~RMFindNamedResource #rWString;#rAnimPathname;#temp ;rID
 PushWord #rWString ;rType
 lda 5,s
 pha
 lda 5,s
 pha
 _RemoveResource
 PushLong #ZeroString ;no rezName
 _RMSetResourceName

* Set the ID of pathhandle to the control panel, so we don't confuse the
* living hell out of the resource manager :-)

 phd
 ~GetCurResourceApp
 PushLong PathHandle
 _SetHandleID
 plx

* add a new resource

 PushLong PathHandle ;handle
 PushWord #$18 ;attrNoSpec+attrNoCross
 PushWord #rWString ;rType
 ~UniqueResourceID #$FFFF;#rWString ;rID
 lda 1,s
 sta tempHandle
 lda 1+2,s
 sta tempHandle+2
 _AddResource


 PushWord #rWString ;rType
 PushLong tempHandle ;rID
 PushLong #rAnimPathname ;ptr to name str
 _RMSetResourceName

;Update the file and restore original rezFile.

 ~UpdateResourceFile RezFileID

 ~RMLoadNamedResource #rWString;#rAnimPathname
 PullLong PathHandle

 PushWord #rWString ;rtype
 ~RMFindNamedResource #rWString;#rAnimPathname;#temp ;rID
 _DetachResource

skipSave

 _SetCurResourceFile

 brl return

tempHandle adrl 0
ZeroString str ''

*-------------------------------------------------
* Hit
*
* handle item hits

doHit debug 'doHit'

 lda #0
 sta T2Result+2,s
 sta T2Result,s
 lda T2data2+2,s ; ctlID hi word must be zero
 bne :nothingHit
 lda T2data2,s
 cmp #1
 beq pathBtnHit
:nothingHit brl return

pathBtnHit
 ~LoadOneTool #$17;#$0303

 ~SFStatus
 pla
 sta SFStatus
 bne :active

 ~NewHandle #$100;MyID;#$C005;#0 ;attrLocked+attrFixed+attrPage+attrBank
 PullLong ToolDP

 PushWord MyID
 PushLong ToolDP
 jsr makePdp
 pld
 pla
 plx
 pha ;DP pointer
 _SFStartUp

:active

 do 0
 brk
 brk

 lda #5
 sta TypeList

 sep #$20
 ldal $E0C025
 rep #$20
 bit #%0100_0000 ; option
 beq noOpt
 lda #6
 sta TypeList

noOpt
 fin
 PushWord #120 ;whereX  640
 PushWord #50 ;whereY  640
 PushWord #refIsPointer ;promptRefDesc
 PushLong #OpenString ;promptRef
 PushLong #0 ;filterProcPrt
 PushLong #TypeList ;typeListPtr
 PushLong #SFReply ;replyPtr
 _SFGetFile2

 lda SFStatus
 bne :noShutIt
 _SFShutDown
 ~UnloadOneTool #$17

 ~DisposeHandle ToolDP

:noShutIt
 lda SFReply ;See if user clicked cancel
 bne :noCancel
 brl return

:noCancel
 lda #TRUE
 sta T2Result,s

 PushLong Path
 jsr makePdp
 lda 3
 clc
 adc #2 ;past buff size
 sta 3
 lda 3+2
 adc #0
 sta 3+2
 pld
 PushLong Path
 ~GetHandleSize Path
 lda 1,s ;lo word
 sec
 sbc #2
 sta 1,s
 lda 3,s ;high word
 sbc #0
 sta 3,s
 _PtrToHand

 ~GetHandleSize Path
 lda 1,s ;lo word
 sec
 sbc #2
 sta 1,s
 lda 3,s ;hi word
 sbc #0
 sta 3,s
 PushLong Path
 _SetHandleSize

 ~HLock Path

 lda Path
 sta PathHandle
 lda Path+2
 sta PathHandle+2

; ~DisposeHandle Path
 ~DisposeHandle Nom

 PushLong PathHandle
 jsr makePdp
 lda [3]
 xba
 sta [3]
 inc 3
 bne :1
 inc 3+2
:1 pld  ;ptr to source string
 PullLong PathPtr

 pha ; for disposecontrol
 pha
 ~GetCtlHandleFromID WindPtr;#2 ; animpathctl id
 lda 1,s
 sta 5,s
 lda 1+2,s
 sta 5+2,s
 _HideControl
 _DisposeControl

 jsr substitute

 brl return

SFStatus da 0

OpenString str 'Use which animation ($C2) file?'

TypeList
 da 5 number of types

 da $0000 ;flags: normal.. :-)
 da $C2 ;fileType
 adrl $0000 ;auxType

 da $2000 ;flags: dim all $c0 $02 (apf)
 da $C0 ;fileType
 adrl $0002 ;auxType

 da $A000 ;flags: dim all $C1 file entries
 da $C1 ;fileType
 adrl 0 ;auxType

 da $2000 ;flags: dim all $C0 $0000 pics
 da $C0 ;fileType
 adrl $0000 ;auxType

 da $2000 ;flags: dim all $C0 $0001 pics
 da $C1 ;fileType
 adrl $0001 ;auxType

 da $8000 ;flags: match all auxtypes (Selectable)
 da $00 ;fileType
 adrl $0000 ;auxType


SFReply
 da 0
fileType da 0
auxType adrl 0
 da 3
Nom adrl 0
 da 3
Path adrl 0

ToolDP adrl 0

*-------------------------------------------------
* Kill
*
* dispose of anything unneeded

doKill
 ~DisposeHandle PathHandle
 brl return

*-------------------------------------------------
* LoadSetup
*
* load in the file needed (name in resource fork)

* errors:
*  0 - nothing
*  1 - pathname not set up
*  2 - file not found
*  3 - error loading in file
*  4 - out of memory error

ErrorNum da 0 ;our error number
RealError da 0 ;real error number

doLoadSetup
 debug 'doLoadSetup'

 stz ErrorNum
 stz RealError

 ~RMLoadNamedResource #rWString;#rAnimPathname
 bcc :PathOK
 plx
 plx
 stz AnimHandle
 stz AnimHandle+2
 sta RealError ;save the error number
 lda #1
 sta ErrorNum ;pathname not setup
 brl return

:PathOK
 jsr makePdp
 pld
 PullLong pathname

 PushWord #rWString ;rtype
 ~RMFindNamedResource #rWString;#rAnimPathname;#temp ;rID
 bcc :good
 plx
 plx
:er stz AnimHandle
 stz AnimHandle+2
 sta RealError ;save the error number
 lda #1
 sta ErrorNum
 brl return
:good _DetachResource
 bcs :er

* Load Picture

 Open_GS openParams
 bcc :openOK
 stz AnimHandle
 stz AnimHandle+2
 sta RealError ;official error number
 cmp #$46
 beq :fnotf
 cmp #$44
 beq :fnotf
 lda #3 ;error while loading file
 sta ErrorNum

:fnotf lda #2 ;file not found
 sta ErrorNum
 brl return

:openOK lda OpenID
 sta ReadID
 sta CloseID

 lda eof
 sta readLength
 lda eof+2
 sta readLength+2

* lda T2Data2+2,s ;memory ID
* sta MyID
 ~MMStartUp
 pla
 sta MyID
 pha
 pha
 PushLong eof
*  lda T2Data2+2,s ;memory ID
* pha
 PushWord MyID
 PushWord #$C008 ;attrLocked+attrNoCross+attrNoSpec
 PushLong #0
 _NewHandle
 sta RealError
 plx
 stx AnimHandle
 plx
 stx AnimHandle+2
 bcc :MemoryOK
 Close_GS CloseParams close picture
 stz AnimHandle
 stz AnimHandle+2
 lda #4 ;out of memory
 sta ErrorNum
 brl return

:MemoryOK PushLong AnimHandle
 jsr makePdp
 pld
 PullLong PicDestIN

 Read_GS ReadParams

 php
 pha
 Close_GS CloseParams close picture
 pla
 plp
 bcc :readOK
 sta RealError
 ~DisposeHandle AnimHandle
 stz AnimHandle
 stz AnimHandle+2
 lda #3 ;error while loading file
 sta ErrorNum
 brl return

:readOK ;file is all loaded in!
   ;handle is in AnimHandle

 brl return

openParams
 da 12 pcount
openID da 0 ;reference number
pathname adrl 0
 da 0 request_access
 da 0 resource_num
 da 0 ;access
 da 0 ;file_type
 adrl 0 ;aux_type
 da 0 ;storage_type
 ds 8 ;create_td
 ds 8 ;modify_td
 adrl 0 ;option_list
eof adrl 0

readParams
 da 4
readID da 0 ;reference number
picDestIN adrl 0 ;pointer to DATA buffer
readLength adrl 0 ;this many bytes
 adrl 0 ;how many xfered

closeParams
 da 1
closeID da 0 ;reference number

AnimHandle adrl 0 ;for the file loader

*-------------------------------------------------
* Unload
*
* Dispose of anything we loaded in

doUnloadSetup

 debug 'doUnloadSetup'

 ~DisposeHandle AnimHandle ; no setup to unload!

 brl return

* the makePdp routine is found in a different file
 put makepdp.asm

 sav Moviet.l
