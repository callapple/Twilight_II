         KEEP  patch         mcopy patch.mac         copy  patch.equ	copy	13:ainclude:e16.memory	copy	13:ainclude:e16.types;................................................................TRUE     gequ  1FALSE    gequ  0TempHandle gequ <0TempPtr  gequ  TempHandle+4;................................................................Patcher	Start	Using	GlobalDATA         phk         plb         jsr   SetUp                    ;Set things up         jsr   MainEvent                ;do the main program         jsr   ShutDown                 ;then shut them down again         _QUIT QuitParams               ;And quit         End;................................................................GlobalData DataQuitParams anop         dc    i4'0'         dc    i'0'MyID     ds    2                        ;UserIDMemID    ds    2                        ;auxiliary UserIDQuitFlag dc    i'0'SavedFlag dc   i'0'EnableFlag dc  i'$FFFF'                 ;wether the edit menu is enabledStartStopRec ds 4                       ;returned by StartUpToolsNewPtr   ds    4                        ;The pointer to window's grafportSaveName ds    4                        ;The save name handleSavePath ds    4                        ;The save path's handleSaveHandle ds  4                        ;The handle for the window title         End;................................................................SetUp    Start         using GlobalData         using FileData         ~TLStartUp                     ;Start the Tool Locator         ~MMStartUp         pullword MyID         ora   #$0100                   ;And create an aux ID         sta   MemID                    ;  for getting memory with         pushlong #0                    ;Start up the standard tools         pushword MyID         pushword #2                    ;from a resource         pushlong #TSTART_00000002         _StartUpTools         pulllong StartStopRec         jsr   SetUpMenus               ;And draw the menu         ~InitCursor                    ;Show the arrow cursor         lda   #DefaultSave             ;set the save name to the default save         sta   SaveName                 ;string ('untitled')         lda   #DefaultSave+2         sta   SaveName+2         rts         End;................................................................SetUpMenus Start	Using GlobalDATA         ~NewMenuBar2 #2,#MBAR_00000001,#0         _SetSysBar                     ;  and make it the current system bar         ~SetMenuBar #0         ~FixAppleMenu #1	; install desk accs         ~FixMenuBar		; calculate menu sizes         pla         ~DrawMenuBar                   ;And draw the bar         rts         End;................................................................MenuData DataMenuHandlers anop         dc    i'doClose'               ;Close: 255         dc    i'doAbout'               ;About: 256         dc    i'doQuit'                ;Quit: 257         dc    i'doNew'                 ;New: 258         dc    i'doOpen'                ;Open: 259         dc    i'doSave'                ;Save: 260         dc    i'doSaveAs'              ;SaveAs: 261         dc    i'doDocs'                ;Documentation: 262         dc    i'Ignore'                ;Print: 263         dc    i'Ignore'                ;Page Setup:264         End;................................................................MainEvent Start         using TaskData         using GlobalDataagain    anop         ~TaskMaster #$FFFF,#TaskRecord         pla         asl   a         tax         jsr   (TaskHandlers,x)         lda   QuitFlag         beq   again         rts         End;................................................................TaskData DataTaskRecord anopWhat     ds    2Message  ds    4When     ds    4Where    ds    4Modifiers ds   2TData    ds    4         dc    i4'$001FFFFF'LastClickTick ds 4ClickCount ds  2TaskData2 ds   4TaskData3 ds   4TaskData4 ds   4LastClickPoint ds 4TaskHandlers anop         dc    i'doNull'                ;NullEvt         dc    i'Ignore'                ;MouseDownEvt         dc    i'Ignore'                ;MouseUpEvt         dc    i'Ignore'                ;KeyDownEvt         dc    i'Ignore'                ;Undefined         dc    i'Ignore'                ;AutoKeyEvt         dc    i'Ignore'                ;UpdateEvt         dc    i'Ignore'                ;Undefined         dc    i'Ignore'                ;ActivateEvt         dc    i'Ignore'                ;SwitchEvt         dc    i'Ignore'                ;DeskAccEvt         dc    i'Ignore'                ;DriverEvt         dc    i'Ignore'                ;App1Evt         dc    i'Ignore'                ;App2Evt         dc    i'Ignore'                ;App3Evt         dc    i'Ignore'                ;App4Evt         dc    i'Ignore'                ;wInDesk         dc    i'doMenus'               ;wInMenuBar         dc    i'Ignore'                ;wClickCalled         dc    i'Ignore'                ;wInContent         dc    i'Ignore'                ;wInDrag         dc    i'Ignore'                ;wInGrow         dc    i'doClose'               ;wInGoAway         dc    i'Ignore'                ;wInZoom         dc    i'Ignore'                ;wInInfo         dc    i'doMenus'               ;wInSpecial         dc    i'Ignore'                ;wInDeskItem         dc    i'Ignore'                ;wInFrame         dc    i'Ignore'                ;wInactMenu         dc    i'Ignore'                ;wClosedNDA         dc    i'Ignore'                ;wCalledSysEdit         dc    i'Ignore'                ;wTrackZoom         dc    i'Ignore'                ;wHitFrame         dc    i'Ignore'                ;wInControl         dc    i'Ignore'                ;wInControlMenu         End;................................................................doNull   Start         using GlobalData         ~FrontWindow         pla         plx         cmp   #0                       ;if the ptr=NIL then disable things         bne   enable                   ;otherwise enable them         cpx   #0         bne   enable         lda   EnableFlag               ;see if we're already disabled         beq   done                     ;if so, then exit         ~DisableMItem #255	; otherwise, disable close item         ~SetMenuFlag #$0080,#3	; and edit menu         _DrawMenuBar                   ;redraw the menu bar (so Edit will be;                                       ;dimmed)         stz   EnableFlag               ;and indicate that things are disabled         rts                            ;Exitenable   lda   EnableFlag               ;see if things are already enabled         bne   done                     ;and if so, exit         ~EnableMItem #255	; enable close item         ~SetMenuFlag #$FF7F,#3	; and the edit menu         _DrawMenuBar                   ;redraw the menu bar         lda   #$FFFF                   ;and indicate that things are enabled         sta   EnableFlagdone     rts         End;................................................................Ignore   Start         rts                            ;Ignore all of these         End;................................................................doMenus  Start	Using GlobalDATA         using MenuData         using TaskData         lda   TData                    ;Find out which menu it was         sec                            ;transform into a jump table offset         sbc   #255         asl   a         tax         jsr   (MenuHandlers,x)         ;and jump         ~HiliteMenu #FALSE,TData+2	; then unhilite it when done         rts         End;................................................................doClose  Start         using GlobalData         using MenuData         ~FrontWindow         pulllong TempHandle         lda   TempHandle               ;see if it's our window         cmp   NewPtr         bne   DC01                     ;if not, skip this         lda   TempHandle+2         cmp   NewPtr+2         bne   DC01         ~DisableMItem #260	; disable save         ~DisableMItem #261	; disable save as         ~DisableMItem #263             ; disable print         ~DisableMItem #264	; disable page setup         ~EnableMItem #258	; enable new         ~EnableMItem #259	; enable open;        [Do window specific close stuff here]DC01     anop                           ;here you could check for other windows;                                       ;for which you need to do special stuff;                                       ;when closedclose	anop	pei	TempHandle+2	pei	TempHandle         _CloseWindow;                                       ;this will disable the close item         ~FrontWindow                   ;(ID = 255) if there are no more open         pla                            ;windows         plx         cmp   #0         bne   done         cpx   #0         bne   done         ~DisableMItem #255done     rts         End;................................................................doAbout  Start	Using GlobalDATA         ~AlertWindow #4,#0,#ALERT_0000000E         plx         rts         End;................................................................doNew    Start         using FileData	Using GlobalDATA         jsr   newEngine                ;open the window         lda   #DefaultSave             ;and make the save name 'untitled'         sta   SaveName                 ; (see SetUP)         lda   #DefaultSave+2         sta   SaveName+2         rts         End;................................................................newEngine Start         using GlobalData         LongResult                     ;Open the window, from a resource         pushlong #0         pushlong #0         pushlong #drawNew         pushlong #0         pushword #2         pushlong #WPARAM1_00000FFE         pushword #$800E         _NewWindow2         pulllong NewPtr         ~EnableMItem #255	; enable close         ~EnableMItem #260	; enable save         ~EnableMItem #261              ; enable save as         ~EnableMItem #263	; enable print         ~EnableMItem #264	; enable page setup         ~DisableMItem #258	; disable new         ~DisableMItem #259             ; disable open         rts         End;................................................................drawNew  Start         using GlobalData         phb                            ;save the data bank, then make         phk                            ;data bank==code bank         plb         ~DrawControls NewPtr         plb                            ;and restore the saved data bank         rtl         End;................................................................doOpen   Start         using FileData         using GlobalData         lda   SavedFlag                ;if the window has hever been saved,         beq   skip                     ;then skip this         ~DisposeHandle Name            ;dispose name and path strings         ~DisposeHandle Path         ~DisposeHandle SaveHandleskip	anop               PushWord #120            whereX  640               PushWord #50             whereY  640               PushWord #refIsPointer   promptRefDesc               PushLong #OpenString     promptRef               PushLong #0              filterProcPrt               PushLong #TypeList       typeListPtr               PushLong #SFReply        replyPtr               _SFGetFile2         lda   SFReply                  ;See if we should proceed         bne   ok         brl   abortok       lda   Path                     ;Transfer the path to a dp location         sta   TempHandle         lda   Path+2         sta   TempHandle+2         ldy   #2                       ;Load the pointer to the name         lda   [TempHandle]         clc                            ;  adding two to skip over the length         adc   #2                       ;  of buffer word         sta   OpenPath                 ;And store the ptr at OpenPath &         sta   SavePath                 ;SavePath         lda   [TempHandle],y         adc   #0         sta   OpenPath+2         sta   SavePath+2         _OpenGS openParams             ;Open the file         lda   ORefNum                  ;Transfer out refNum         sta   RRefNum         sta   CRefNum         LongResult                     ;Get a block of memeory to load the         pushlong Length                ;  file into         pushword MemID         pushword #$C000         pushlong #0         _NewHandle         pulllong TempHandle            ;And store it's ptr at both         ldy   #2                       ;FilePtr & TempPtr         lda   [TempHandle],y         sta   FilePtr+2         sta   TempPtr+2         lda   [TempHandle]         sta   FilePtr         sta   TempPtr         lda   Length                   ;Transfer the length to the read length         sta   RLength         lda   Length+2         sta   RLength+2         _ReadGS readParams             ;Read the file         _CloseGS closeParams           ;And then close it         jsr   newEngine                ;open the window         pushword #5                    ;Text block         pushlong FilePtr         pushlong Length         pushword #0         pushlong #0         pushlong #0         _TESetText         pei   TempHandle+2            ;we can discard the loaded text	pei	TempHandle         _DisposeHandle                 ;after the TE control has it         jsr   makeSaveName             ;set the window's name         lda   #$FFFF                   ;indicate that the file has been saved         sta   SavedFlagabort    rts         End;................................................................doSave   Start         using GlobalData         lda   SavedFlag                ;if we've been saved before, then         bne   saved                    ;just save the file. Otherwise, do         jsr   doSaveAs                 ;SaveAs         rts                            ;exitsaved    jsr   saveEngine               ;just save the file         rts         End;................................................................doSaveAs Start         using FileData         using GlobalData         pushword #25                   ;Your standard SFPutFile2         pushword #50                   ;Again, a little cramped in 640, but         pushword #0                    ;nice in 320         pushlong #SaveAsPrompt         pushword #0         pushlong SaveName         pushlong #SFReply         _SFPutFile2         lda   SFReply                  ;See if we're still hapening         bne   ok1         brl   doneok1      lda   SavedFlag                ;if the file hasn't been saved then skip         beq   skip                     ; the next bit         ~DisposeHandle Name            ;dispose name and path strings         ~DisposeHandle Path         ~DisposeHandle SaveHandleskip     lda   Path                     ;Transfer the path to a dp location         sta   TempHandle         lda   Path+2         sta   TempHandle+2         ldy   #2                       ;Get the ptr         lda   [TempHandle]         clc                            ;and add two to skip over the output         adc   #2                       ;word         sta   SavePath         lda   [TempHandle],y         adc   #0         sta   SavePath+2         jsr   saveEngine               ;save the file         lda   #$FFFF                   ;indicate that it's been saved         sta   SavedFlag         jsr   makeSaveName             ;and rename the windowdone     rts         End;................................................................saveEngine Start         using FileData	Using GlobalDATA         lda   SavePath                 ;load the pathname into all of the         sta   OpenPath                 ;appropriate places         sta   DPathPtr         sta   CPathPtr         lda   SavePath+2         sta   OpenPath+2         sta   DPathPtr+2         sta   CPathPtr+2         _DestroyGS DestroyParams       ;Destroy any existing file         _CreateGS CreateParams         ;Create a brand new one         _OpenGS OpenParams             ;Open it         lda   ORefNum                  ;Transfer ref nums         sta   CRefNum;        [Insert save code here]         _CloseGS CloseParams           ;And close the file         rts         End;................................................................FileData DataOpenString str 'Locate the Sound control panel:'SaveAsPrompt str 'Save file as:'DefaultSave GSstr 'Untitled'TypeList	anop               dc    i'1'               number of types               dc    i'$8000'           flags: don't match auxtype               dc    i'$C7'             fileType               dc    i4'$0000'          auxTypeSFReply  anop         ds    2type     ds    2auxType  ds    4         dc    i'3'Name     ds    4         dc    i'3'Path     ds    4openParams anop         dc    i'12'ORefNum  ds    2OpenPath ds    4         dc    i'3'         dc    i'0'         ds    2         ds    2         ds    4         ds    2         ds    8         ds    8         dc    i4'0'Length   ds    4readParams anop         dc    i'4'RRefNum  ds    2FilePtr  ds    4RLength  ds    4         ds    4closeParams anop         dc    i'1'CRefNum  ds    2DestroyParams anop         dc    i'1'DPathPtr ds    4CreateParams anop         dc    i'4'CPathPtr ds    4         dc    i'$00C3'         dc    i'6'         dc    i4'$0000'         End;................................................................doQuit   Start         using GlobalData         lda   #$FFFF                   ;Indicate that it's time to quit         sta   QuitFlag         rts         End;................................................................doDocs   Start         using DocData         using GlobalData         LongResult                     ;open a window with the documentation         pushlong #0                    ;in it.         pushlong #0         pushlong #drawDocs         pushlong #0         pushword #2         pushlong #WPARAM1_00000FFD         pushword #$800E         _NewWindow2         pulllong DocPtrwait           anop; then wait for the person to hit the close box, filtering out all other events         ~TaskMaster #$FFFF,#DocTRecord         pla         cmp   #$0016         bne   wait         ~CloseWindow DocPtr	; close doc window         rts         End;................................................................drawDocs Start         using DocData         phb                            ;save the data bank         phk                            ;make the data bank==code bank         plb         ~DrawControls DocPtr         plb                            ;restore the saved data bank         rtl         End;................................................................DocData  DataDocPtr   ds    4DocTRecord anopDWhat    ds    2DMessage ds    4DWhen    ds    4DWhere   ds    4DModifiers ds  2DTData    ds   4         dc    i4'$0011A106'DLastClickTick ds 4DClickCount ds 2DTaskData2 ds  4DTaskData3 ds  4DTaskData4 ds  4DLastClickPoint ds 4         End;................................................................ShutDown Start         using GlobalData         ~ShutDownTools #1,StartStopRec	; shutdown most of the tools         ~MMShutDown MyID         ~TLShutDown                    ;  then the Tool Locator         rts         End;................................................................makeSaveName Start         using GlobalData	Using FileDATA         lda   Name                     ;This is really messy, but it works :)         sta   TempHandle               ;store the Name handle into the dp         lda   Name+2         sta   TempHandle+2         ldy   #2                       ;then derefrence the filename, adding         lda   [TempHandle]             ;two to skip over the GS/OS buffer         clc                            ;length word         adc   #2         sta   SaveName                 ;store this as the SaveName (for the         sta   TempPtr                  ;SFPutFile2 dialog)         lda   [TempHandle],y           ;and in TempPtr (so we can get at it)         adc   #0         sta   SaveName+2         sta   TempPtr+2         LongResult                     ;Next, get another handle of the same         LongResult                     ;size as the first	pei	TempHandle+2	pei	TempHandle         _GetHandleSize         pushword MemID         pushword #attrLocked+attrFixed	phd	phd         _NewHandle         pulllong TempHandle            ;putting the handle into both         lda   TempHandle               ;the dp, so we can deref it, and         sta   SaveHandle               ;SaveHandle, so we can discard it later         lda   TempHandle+2         sta   SaveHandle+2         lda   [TempHandle]             ;load the first word of the pointer         pha                            ;and store for a sec         ldy   #2                       ;load the second byte         lda   [TempHandle],y         sta   TempHandle+2             ;and store it at TempHandle (I didn't         pla                            ;want to use any more dp space :)         sta   TempHandle               ;then put the first byte there too         lda   [TempPtr]                ;load the length word, make it between         and   #$00FF                   ;0-255, and store it as a length byte         sta   [TempHandle]         inc   a                        ;also add two and store for future         inc   a                        ;refrence         sta   NameLength         ldy   #2         shortm                         ;work with bytes (letters)nextMove cpy   NameLength               ;see if we've done enough bytes yet         beq   moved                    ;if so, exit         lda   [TempPtr],y              ;otherwise, move another byte from         dey                            ;offset x in TempPtr to offset x-1         sta   [TempHandle],y           ;in TempHandle         iny         bra   nextMove                 ;and go back to do another bytemoved    longm                          ;work with words again	pei	TempHandle+2         	pei	TempHandle            ;set the window title         pushlong NewPtr         _SetWTitle         rts                            ;and, finally, exit. Easy, huh?NameLength ds  2         End