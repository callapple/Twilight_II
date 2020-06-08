
               DefineStack
oldBank        byte
returnAddress  block 3
MasterID       word
MovePtr        long
TextPtr        long

               lda   MasterID,s
               ora   #$0A00
               sta   MyID

               pei   MyID
               _ResourceStartUp

               WordResult
               _GetCurResourceApp
               PullWord OldResourceApp

               WordResult
               _GetCurResourceFile
               PullWord OldResourceFile

               pei   MyID
               _SetCurResourceApp

               WordResult
               PushWord #1              request read access
               PushLong #0              open a new file
               PushLong #OurNameStr
               _OpenResourceFile
               plx
               stx   ResFileID
*               jcs   Error

               LongResult
               PushWord #rC1InputString
               PushLong #$00000001
               _LoadResource
               plx
               stx   TempDP
               plx
               stx   TempDP+2
*               jcs   error
               ldy   #2
               lda   [TempDP]
               tax
               lda   [TempDP],y
               sta   TempDP+2
               stx   TempDP


               PushWord ResFileID
               _CloseResourceFile

               PushWord OldResourceFile
               _SetCurResourceFile

               PushWord OldResourceApp
               _SetCurResourceApp

               _ResourceShutDown

               pei   <MyID
               _DisposeAll
               clc
               rtl
               
ResFileID      ds    2
OurNameStr     GSStr '*:System:CDevs:Twilight:DrawString1.1'
OldResourceApp ds    2
OldResourceFile ds   2