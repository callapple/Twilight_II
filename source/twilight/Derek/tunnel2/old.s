*------------------------------------------------*
*                                                *
*                  Old Loader                    *
*        A T2 blanker by Derek Young, DYA        *
*                                                *
*  This blanker will load in blankers from       *
*  Twilight I in the old style and display them. *
*------------------------------------------------*
 lst off
 xc
 xc
 mx %00
 rel
 use old.macs

 dum 0
RezFileID da 0
MyID da 0
MemID da 0
progstart adrl 0
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

*-------------------------------------------------
* start of the blanker...

Start
 phb
 phk
 plb

 lda T2Message,s
 cmp #2  ;must be BlankT2
 bne Bye

 lda T2Data1,s
 sta MovePtr ;save this in our own DP
 lda T2Data1+2,s
 sta MovePtr+2

 lda T2Data2,s
 sta RezFileID
 lda T2Data2+2,s ;our memory ID
 sta MyID
 clc
 adc #$100
 sta MemID ;need a memory ID

*-------------------------------------------------
* Blank the screen - load the old blanker into
* memory and call its blank function.
* We give the blanker our direct page since there is nothing
* in it that isn't saved.  The text in the TextEdit box
* is taken from the setup procedure and is saved in the
* twilight.setup file.  The stack looks like this on entry to
* the blanker:
*
*         | previous       |
*         |   contents...  |
*         +----------------+
*         | TextPtr (Long) |  Pointer to pascal string entered in TextEdit box
*         +----------------+
*         | MovePtr (Long) |  Pointer to the movement flag
*         +----------------+
*         | MemID (Word)   |  Blanker's memory ID
*         +----------------+
*         | RTL (3 bytes)  |  RTL Address
*         +----------------+
*                            <--- Stack Pointer
*-------------------------------------------------

Blank
 ~InitialLoad2 MemID;#pathname;#0;#1 ;load in the blanker
 PullWord TheirID
 PullLong progstart
 PullWord dp
 pla ;size of DP/stack buffer
 bcc :doit

* error! display an error message...

 bra Bye

:doit
 lda progstart
 sta blanker+1
 lda progstart+1
 sta blanker+1+1

 phb ;save everything in case the blanker does
 phd  ;something it's not supposed to.
 php

 lda dp
 tcd ;give the blanker a DP

 PushLong #null ;pointer to text-edit text.
 PushLong MovePtr ;pointer to movement flag
 PushWord TheirID ;blanker's memory ID
blanker jsl $FFFFFF ;call the blanker!

 plp
 pld
 plb

Bye lda RTLaddr,s ;move up RTL address
 sta T2data1+3,s
 lda RTLaddr+1,s
 sta T2data1+3+1,s

 lda #0
 sta T2Result,s
 sta T2Result+2,s ;the result (nil for no error)
 plb  ;restore the bank

 tsc ;remove the input parameters.
 clc
 adc #10
 tcs

 clc
 rtl


null str ''

TheirID da 0
dp da 0
MovePtr adrl 0

* pathname strl '/programming/programming/twilight/old/universe'
pathname strl '*:system:cdevs:twilight:njm.fire'

 sav old.l
