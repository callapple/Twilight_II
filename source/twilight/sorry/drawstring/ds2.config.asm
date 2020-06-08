
               mcopy DS2.Config.Mac
               mcopy 7/m16.util2
               copy  DS2.equ
               copy  7/e16.types
               copy  7/e16.window
               copy  7/e16.memory
               copy  7/e16.control
*-----------------------------------------------------------------------------*
FALSE          gequ  0
TRUE           gequ  1

rC1InputString gequ  $8005
rWindParam1    gequ  $800E
rConfiguration gequ  $0001

MyID           gequ  <0
TempDP         gequ  MyID+2
OldPort        gequ  TempDP+4
OurWindow      gequ  OldPort+4
TEFlag         gequ  OurWindow+4
ToolDP         gequ  TEFlag+2
OurPath        gequ  ToolDP+4
*-----------------------------------------------------------------------------*
DSConfig       Start

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

*               pei   MyID
*               _SetCurResourceApp

               WordResult
               PushWord #3              request read/write access
               PushLong #0              open a new file
               pei   OurPath+2
               pei   OurPath
               _OpenResourceFile
               plx
               stx   ResFileID
*               jcs   Error

               LongResult
               _GetPort
               PullLong OldPort

               stz   TEFlag
               WordResult               ;First, check whether we need to load
               _TEStatus                ;the TE toolset
               pla
               bcs   MustLoad
               beq   MustLoad
               brl   skipLoad

MustLoad       anop
               LongResult               ; Okay, now we need some dp space
               PushLong #$100           ; we need one page of direct page space
               pei   MyID
               PushWord #attrLocked+attrFixed+attrPage+attrBank
               PushLong #0
               _NewHandle
               bcc   dpMemOk            ;if we got the mem than everything's
               pla                      ;cool. Otherwise we HAVE to exit.
               pla
               brk   $99

dpMemOk        anop
*               makeDP                   ;Get a pointer to the DP mem and store
*               lda   [3]                ;it in TEFlag, for the time being
*               sta   TEFlag
*               pld
               PullLong ToolDP          ;Don't forget to get the handle, too....

               PushWord #$22            ;And finally, load the TE toolset
               PushWord #0
               _LoadOneTool
               bcc   TELoaded
               brk   $88

TELoaded       anop
               pei   MyID               ; and start TE up!
               lda   [ToolDP]
               pha
               _TEStartUp
               bcc   TEOk               ;TE Started up allright....
               brk   $77

TEOk           lda   #-1                ;indicating that we've done so, while
               sta   TEFlag             ;we're at it....

skipLoad       anop
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

               PushWord #%10010         ; get text from rC1InputString Resource
               PushLong #SavedTextC1IStr ; resource ID of C1 input string
               PushLong #0              ; length of input text buffer (unused)
               PushWord #0              ; type of reference stored in styleRef
               PushLong #0              ; styleRef-style structure reference
               LongResult               ; handle of TERecord in memory
               pei   OurWindow+2
               pei   OurWindow
               PushLong #TextEditCtl
               _GetCtlHandleFromID
               _TESetText

               LongResult
               PushWord #rConfiguration
               PushLong #DelayRez
               _LoadResource
               makePdp
               lda   [3]
               sta   DelayTime
               killLdp

               ldx   #0                 ; Caluculate the delay
               lda   DelayTime          ; in seconds
               sec
nextSub        sbc   #60
               bmi   subOk
               inx
               bra   nextSub
subOk          stx   Seconds

               PushWord Seconds         ; Convert it to a string
               PushLong #TimeTxt
               PushWord #2              ; number of characters
               PushWord #FALSE          ; unsigned
               _Int2Dec

               PushLong #TimeTxt        ;Now, we're going to set the LE control
               lda   Seconds            ;to the number of seconds. To do this
               cmp   #10                ;we need to figure out how many digits
               blt   push1              ;there are. Since it can be any number
               pea   0002               ;between 1-99, we only have to worry
               bra   goOn               ;about it having 1 or two digits.
push1          pea   0001
               lda   TimeTxt
               xba
               sta   TimeTxt
goOn           LongResult               ; for GetCtlTitle
               LongResult               ; for GetCtlHandleFromID
               PushLong OurWindow
               PushLong #DelayLECtl
               _GetCtlHandleFromID
               _GetCtlTitle
               _LESetText

               LongResult
               _FindTargetCtl
               pla
               plx
               bcs   out
               sta   <TempDP
               stx   <TempDP+2          ; TempDP = target control's handle
               lda   [TempDP]
               tax
               ldy   #2
               lda   [TempDP],y
               sta   <TempDP+2          ; control handle now deref'ed into TempDP
               stx   <TempDP

ItsLEControl   ldy   #oCtlData          ; offset to LE Record handle
               lda   [TempDP],y
               tax                      ; low word in X
               iny
               iny
               lda   [TempDP],y         ; high word in A

               pha
               phx                      ; push the LE record handle

               LongResult               ; save original port
               _GetPort

               pei   OurWindow+2
               pei   OurWindow
               _StartDrawing

               PushWord #0              ; start of selection range
               PushWord #$FF            ; end of selection range
               lda   11,s
               pha
               lda   11,s
               pha                      ; get LE handle at top of stack
               _LESetSelect

               PushWord #0
               PushWord #0
               _SetOrigin

               _SetPort                 ; restore original port

               pla
               pla                      ;pull the LE record handle off the stack
out            anop

wait           WordResult               ; then wait for the person to hit the
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
               jeq   Cancelled
               cmp   #OKCtl             ; OK pressed?
               bne   wait

Exit           anop
               WordResult               ; for Dec2Int
               LongResult               ; for LEGetTextHand
               LongResult               ; for GetCtlTitle
               LongResult               ; for GetCtlHandleFromID
               PushLong OurWindow
               PushLong #DelayLECtl
               _GetCtlHandleFromID
               _GetCtlTitle
               lda   1,s
               sta   TempDP
               lda   3,s
               sta   TempDP+2
               _LEGetTextHand

               makePdp
               pld
               WordResult
               PushLong TempDP          ; handle to edit record
               _LEGetTextLen
               PushWord #FALSE
               _Dec2Int
               plx
               cpx   #1
               bge   timeOk
               ldx   #1
timeOk         anop
               lda   #0
dLoop          clc
               adc   #60
               dex
               bne   dLoop
               sta   DelayTime

               LongResult 
               PushWord #rConfiguration
               PushLong #DelayRez
               _LoadResource
               makePdp
               lda   DelayTime
               sta   [3]
               killLdp

               PushWord #TRUE
               PushWord #rConfiguration
               PushLong #DelayRez
               _MarkResourceChange

               LongResult               ;Get the text from the TE box
               PushWord #%10010         ; rezID for output buffer, C1InputStr
               PushLong #SavedTextC1IStr
               PushLong #0              ; length of output buffer (ignored)
               PushWord #0              ; reference for style data (ignored)
               PushLong #0              ; style data (ignored)
               LongResult
               pei   OurWindow+2
               pei   OurWindow
               PushLong #TextEditCtl
               _GetCtlHandleFromID
               _TEGetText
               plx
               plx

               PushWord #TRUE           ; indicate that the resource has changed
               PushWord #rC1InputString
               PushLong #SavedTextC1IStr
               _MarkResourceChange

cancelled      anop
               pei   OurWindow+2
               pei   OurWindow
               _CloseWindow

               lda   TEFlag
               beq   skipTE
               _TEShutDown
               pei   ToolDP+2           ; get rid of TE's DP space
               pei   ToolDP
               _DisposeHandle

skipTE         anop
               pei   OldPort+2
               pei   OldPort
               _SetPort

               PushWord ResFileID
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

ResFileID      ds    2
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
               dc    i4'$001B2006'
cLastClickTick ds    4
cClickCount    ds    2
cTaskData2     ds    4
cTaskData3     ds    4
cTaskData4     ds    4
cLastClickPoint ds   4

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