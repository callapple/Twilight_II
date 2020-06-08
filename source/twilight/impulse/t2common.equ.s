
* T2 Common Module Equates.  By Jim Maricondo.
* v1.0 - 05/24/92 - Initial Version.
* v1.1 - 05/29/92 - Revised 'cuz of new t2common.rez. - v1.0d33
* v1.2 - 10/24/92 - IPC equates added - v1.0.1b1. - datafield added
* v1.3 - 12/13/92 - mfOverrideSound added - v1.0.1b2

* Resources types.

rT2ModuleFlags equ $1000
rT2ExtSetup1 equ $1001
rT2ModuleWord equ $1002 ; reztype for module words in T2 setup

* Action message codes sent to modules.

MakeT2 equ 0 ; Make module-specific ctls.
SaveT2 equ 1 ; Save new preferences
BlankT2 equ 2 ; Blank the screen.
LoadSetupT2 equ 3 ; Load any resources from yo' fork
UnloadSetupT2 equ 4 ; Dispose of any resources from yo' fk.
KillT2 equ 5 ; Module setup being closed.
HitT2 equ 6 ; Setup window control hit.

 do 0
* How the stack is setup when a module gets called.

dp equ 1 ; This is how the stack is set up
Bank equ dp+2 ; with DP at the top and Result
rtlAddr equ Bank+1 ; occuping the top 4 bytes
T2data2 equ rtlAddr+3
T2data1 equ T2data2+4
T2Message equ T2data1+4
T2Result equ T2Message+2
T2StackSize equ T2Result+4

* Softswitches

KBD equ >$E0C000
KBDSTRB equ >$E0C010
RDVBLBAR equ >$E0C019 ; bit 7 = 1 if not VBL
TBCOLOR equ >$E0C022
NEWVIDEO equ >$E0C029
VERTCNT equ >$E0C02E
SPKR equ >$E0C030
CLOCKCTL equ >$E0C034 ; border color / rtc register
SHADOW equ >$E0C035
INCBUSYFLG equ >$E10064 ; increment busy flag
DECBUSYFLG equ >$E10068 ; decrement busy flag
SHR equ >$E12000
SCBS equ >$E19D00
PALETTES equ >$E19E00

 fin

* Boolean logic

FALSE equ 0
TRUE equ 1

* T2 External IPC

t2TurnOn equ $9000
t2TurnOff equ $9001
t2BoxOverrideOff equ $9002
t2BoxOverrideOn equ $9003
t2GetCurState equ $9004
t2StartupTools equ $9005
t2ShutdownTools equ $9006
t2ShareWord equ $9007
t2SetBlinkProc equ $9008
t2GetNoBlankCursors equ $9009
t2BkgBlankNow equ $900A
t2GetBuffers equ $900B
t2GetVersion equ $900C

* T2 Private IPC

reqDLZSS equ $8007
t2PrivGetProcs equ $9020

* DataField equates.

SetFieldValue equ $8000 ;custom control messages that are
GetFieldValue equ $8001 ; accepted by DataField

* Flag word passed to modules at loadsetupT2 time...

mfOverrideSound equ $0001 ; bit 0. 1=override sound, 0=sound ok
