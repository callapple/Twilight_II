
               mcopy YDI.Config.Mac
               mcopy 7/m16.memory
               mcopy 7/m16.resources
               copy  YDI.equ
               copy  7/e16.types
               copy  7/e16.window
               copy  7/e16.memory
               copy  7/e16.control
*-----------------------------------------------------------------------------*
FALSE          gequ  0
TRUE           gequ  1

INCBUSYFLG     gequ  $E10064            increment busy flag
DECBUSYFLG     gequ  $E10068            decrement busy flag

rC1InputString gequ  $8005
rWindParam1    gequ  $800E

MyID           gequ  <0
TempDP         gequ  MyID+2
OldPort        gequ  TempDP+4
OurWindow      gequ  OldPort+4
OurPath        gequ  OurWindow+4
C1Ptr          gequ  OurPath+4
C1Handle       gequ  C1Ptr+4
TextSize       gequ  C1Handle+4
LETextHndl     gequ  TextSize+2
ToolDP         gequ  LETextHndl+4
*-----------------------------------------------------------------------------*
DSConfig       Start
               Using GlobalDATA

               phb
               phk
               plb

               DefineStack
oldBank        byte
returnAddress  block 3
MasterID       word
ourPathname    long

               lda   MasterID,s
               ora   #$0A00
               sta   MyID

               lda   ourPathname,s
               sta   OurPath
               lda   ourPathname+2,s
               sta   OurPath+2

               WordResult
               _GetCurResourceApp
               PullWord OldResourceApp

               WordResult
               _GetCurResourceFile
               PullWord OldResourceFile

               pei   MyID
               _ResourceStartUp

               WordResult
               PushWord #3              request read/write access
               PushLong #0              open a new file
               pei   OurPath+2
               pei   OurPath
               _OpenResourceFile
               plx
               stx   RezFileID
*               jcs   Error

               LongResult
               _GetPort
               PullLong OldPort

               LongResult
               PushLong #0              ; no replacment title
               PushLong #0              ; no replacement refCon
               PushLong #DrawContent    ; ptr to replacment contentDraw routine
               PushLong #0              ; no replacement window definition proc
               PushWord #refIsResource
               PushLong #Configuration_Window
               PushWord #rWindParam1
               _NewWindow2
               lda   1,s
               sta   OurWindow
               lda   1+2,s
               sta   OurWindow+2
               _SetPort
               PushWord #$0004          ; use dithered color text in window...
               _SetFontFlags


               LongResult
               PushWord #rC1InputString
               PushLong #SavedPathC1IStr
               _LoadResource
               PullLong C1Handle
               ldy   #2
               lda   [C1Handle]
               sta   C1Ptr
               lda   [C1Handle],y
               sta   C1Ptr+2

               pei   C1Ptr+2            ; PUSH POINTER TO TEXT
               lda   C1Ptr
               inc   a                  ; hop past length word
               inc   a
               pha                      ; PUSH POINTER TO TEXT
               lda   [C1Ptr]            ; get length word
               pha                      ; PUSH LENGTH WORD
               LongResult               ; for GetCtlTitle
               LongResult               ; for GetCtlHandleFromID
               pei   OurWindow+2
               pei   OurWindow
               PushLong #PathLECtl
               _GetCtlHandleFromID
               _GetCtlTitle
               _LESetText

               pei   OurWindow+2
               pei   OurWindow
               _DrawControls

wait           entry
               WordResult               ; then wait for the person to hit the
               PushWord #$FFFF          ; OK button, filtering out all other
               PushLong #CfgTaskRec     ; events
               _TaskMaster
               pla
               cmp   #wInControl        ; control selected?
               beq   ControlHit         ; if not, loop
               cmp   #wInInfo
               beq   beep
               cmp   #wInMenuBar
               beq   beep
               cmp   #wInDesk
               beq   beep
               cmp   #wInContent
               beq   check
               cmp   #wInFrame
               beq   Check
               cmp   #wInDrag
               bne   wait
check          lda   cTData
               cmp   OurWindow
               bne   beep
               lda   cTData+2
               cmp   OurWindow+2
               bne   beep
               bra   wait
beep           _SysBeep
               bra   wait

ControlHit     anop
               lda   cTaskData4         ; ID of pressed control
               cmp   #CancelCtl         ; cancel pressed?
               jeq   cancelled
               cmp   #SmartFindFileCtl
               jeq   SFF
               cmp   #OKCtl             ; OK pressed?
               bne   wait

Exit           anop
*               brk   $01

* Get a handle to the text in the LineEdit control.
               LongResult               ; for LEGetTextHand
               LongResult               ; for GetCtlTitle
               LongResult               ; for GetCtlHandleFromID
               pei   OurWindow+2
               pei   OurWindow
               PushLong #PathLECtl
               _GetCtlHandleFromID
               _GetCtlTitle
               lda   1,s
               sta   TempDP
               lda   3,s
               sta   TempDP+2
               _LEGetTextHand
               PullLong LETextHndl


* Set size of the resource's handle to the size of the length of the text
* in the LineEdit control adding two for the length word of a C1InputString.
               PushWord #0              ; hi word of zero for new size of handle
               WordResult
               pei   TempDP+2
               pei   TempDP
               _LEGetTextLen            ; get lo word for new size of handle
               lda   1,s                ; add 2
               sta   TextSize
               inc   a
               inc   a
               sta   1,s                
               pei   C1Handle+2         ; SET SIZE OF THE C1 RESOURCE TO THE
               pei   C1Handle           ; SIZE OF THE TEXT+2 FOR LENGTH WORD
               _SetHandleSize           

* Copy the text out of the control and into the resource starting at offset
* +02 into the resource to the end of the resource.
               pei   LETextHndl+2       ;and copy the text into the resource's
               pei   LETextHndl         ;pointer               (source)
               pei   C1Ptr+2
               lda   C1Ptr
               inc   a
               inc   a
               pha                      ;                      (dest)
               PushWord #0              ; hi word
               pei   TextSize                                  (size)
               _HandToPtr

* Get the length of the text and pop it into offset +00 of the C1InputString
* resource.
               lda   TextSize
               sta   [C1Ptr]

               PushLong LETextHndl      ;release the handle returned by LE
               _DisposeHandle

               PushWord #TRUE           ;indicate that the resource has changed.
               PushWord #rC1InputString
               PushLong #SavedPathC1IStr
               _MarkResourceChange

cancelled      anop
               pei   OurWindow+2
               pei   OurWindow
               _CloseWindow

               pei   OldPort+2
               pei   OldPort
               _SetPort

               PushWord RezFileID
               _CloseResourceFile

               _ResourceShutDown

               PushWord OldResourceFile
               _SetCurResourceFile

               PushWord OldResourceApp
               _SetCurResourceApp

               pei   MyID
               _DisposeAll

               plb
               lda   2,s
               sta   2+6,s
               lda   1,s
               sta   1+6,s
               tsc                      Remove input paramaters
               clc
               adc   #6                 (MasterID+ourPathname)
               tcs
               clc
               rtl

               End
*-----------------------------------------------------------------------------*
GlobalDATA     Data

RezFileID      ds    2
OldResourceApp ds    2
OldResourceFile ds   2
DelayTime      ds    2
Seconds        ds    2
TimeTxt        ds    2                  ; text string version of seconds

CfgTaskRec     anop                     ; Configuration window's task record
cWhat          ds    2
cMessage       ds    4
cWhen          ds    4
cWhere         ds    4
cModifiers     ds    2
cTData         ds    4
               dc    i4'$001B2004'
cLastClickTick ds    4
cClickCount    ds    2
cTaskData2     ds    4
cTaskData3     ds    4
cTaskData4     ds    4
cLastClickPoint ds   4

SFStatus       ds    2
temp           ds    4

OpenString     str   'Use which animation file?'

TypeList       anop
               dc    i'4'               number of types
               dc    i'$0000'           flags: normal.. :-)
               dc    i'$C0'             fileType
               dc    i4'$0002'          auxType
               dc    i'$A000'           flags: dim all $C1 file entries
               dc    i'$C1'             fileType
               dc    i4'0'              auxType
               dc    i'$2000'           flags: dim all $C0 $0000 pics
               dc    i'$C0'             fileType
               dc    i4'$0000'          auxType
               dc    i'$2000'           flags: dim all $C0 $0001 pics 
               dc    i'$C1'             fileType
               dc    i4'$0001'          auxType

SFReply        anop
               ds    2
fileType       ds    2
auxType        ds    4
               dc    i'3'
Nom            ds    4
               dc    i'3'
Path           ds    4

MyPortLoc      anop
SCB            dc    i'$0080'           portSCB
Pix            dc    i4'$E12000'        ptrToPixImage
               dc    i'$00A0'           width in bytes of each line in image
bounds         dc    i'0,0'             boundary rectangle
mode           dc    i'200,640'

MyPort         ds    $AA

orgPort        ds    4

               End
*-----------------------------------------------------------------------------*
DrawContent    Start

               phb
               phk
               plb
               LongResult
               _GetPort
               _DrawControls
               plb
               rtl

               END
*-----------------------------------------------------------------------------*
SFF            Start
               Using GlobalDATA

               PushWord #$17            SF toolset
               PushWord #$0101          version
               _LoadOneTool

               WordResult
               _SFStatus
               pla
               sta   SFStatus
               bne   Active

               LongResult               Get dp space for SF
               PushLong #$100
               pei   MyID
               PushWord #attrLocked+attrFixed+attrPage+attrBank
               PushLong #$000000
               _NewHandle
               plx
               stx   ToolDP
               plx
               stx   ToolDP+2
*               jcs   MemoryErr0         ;ExitWithBeep

               pei   MyID
               lda   [ToolDP]
               pha
               _SFStartUp
*               jcs   SFStartErr0        ;ExitWithBeep

active         anop
               LongResult
               _GetPort
               PushLong #MyPort         Open a new grafPort
               _OpenPort
               PushLong #MyPort
               _SetPort
               PushLong #MyPortLoc      make it point to our memory
               _SetPortLoc
               PushLong #bounds
               _SetPortRect

               jsl   >INCBUSYFLG

               PushWord #120            whereX  640
               PushWord #50             whereY  640
               PushWord #refIsPointer   promptRefDesc
               PushLong #OpenString     promptRef
               PushLong #0              filterProcPrt
               PushLong #TypeList       typeListPtr
               PushLong #SFReply        replyPtr
               _SFGetFile2
               
               jsl   >DECBUSYFLG

               _SetPort

               lda   SFStatus
               bne   noShutIt
               _SFShutDown

               pei   ToolDP+2
               pei   ToolDP
               _DisposeHandle

noShutIt       anop
               lda   SFReply            See if user clicked cancel
               jeq   exit

               lda   Path               Transfer the path to a dp location
               sta   TempDP
               lda   Path+2
               sta   TempDP+2

               ldy   #2                 Load the pointer to the name
               lda   [TempDP]
               clc                      adding two to skip over the length
               adc   #2                 of buffer word
               tax
               lda   [TempDP],y
               sta   TempDP+2
               stx   TempDP

               pei   TempDP+2           ; PUSH POINTER TO TEXT
               lda   TempDP
               inc   a                  ; hop past length word
               inc   a
               pha                      ; PUSH POINTER TO TEXT
               lda   [TempDP]           ; get length word
               pha                      ; PUSH LENGTH WORD
               LongResult               ; for GetCtlTitle
               LongResult               ; for GetCtlHandleFromID
               PushLong OurWindow
               PushLong #PathLECtl
               _GetCtlHandleFromID
               _GetCtlTitle
               _LESetText

               PushLong Path
               PushLong Nom
               _DisposeHandle
               _DisposeHandle

               pei   OurWindow+2
               pei   OurWindow
               _DrawControls

exit           brl   Wait

               END
*-----------------------------------------------------------------------------*