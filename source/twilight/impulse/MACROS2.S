~IntSource MAC 
 PHW ]1 
 Tool $2303 
 <<< 
~MMStartUp MAC 
 PHA 
 Tool $202 
 <<< 
~MMShutDown MAC 
 PHW ]1 
 Tool $302 
 <<< 
_MMShutDown MAC
 Tool $302
 <<<
_WriteResource MAC 
 Tool $161E 
 <<< 
~NewHandle MAC 
 P2SL ]1 
 PxW ]2;]3 
 PHL ]4 
 Tool $902 
 <<< 
~DisposeAll MAC 
 PHW ]1 
 Tool $1102 
 <<< 
PHW MAC 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
PHL MAC 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
P2SL MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
Tool MAC
 LDX #]1 ; load tool call #
 JSL $E10000 ; go to dispatcher
 <<<
PxW MAC
 DO ]0/1
 PHW ]1
 DO ]0/2
 PHW ]2
 DO ]0/3
 PHW ]3
 DO ]0/4
 PHW ]4
 FIN
 FIN
 FIN
 FIN
 <<<
PushLong MAC
 IF #=]1 
 PushWord #^]1 
 ELSE 
 PushWord ]1+2 
 FIN 
 PushWord ]1 
 <<< 
PushWord MAC 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
_NewControl2 MAC 
 Tool $3110 
 <<< 
BEQL MAC 
 BNE OV 
 BRL ]1 
OV <<< 
PullLong MAC 
 DO ]0 
 PullWord ]1 
 PullWord ]1+2 
 ELSE 
 PullWord 
 PullWord 
 FIN 
 <<< 
PullWord MAC 
 PLA 
 DO ]0 
 STA ]1 
 FIN 
 IF MX/2 
 PLA 
 DO ]0 
 STA ]1+1 
 FIN 
 FIN 
 <<< 
~GetTick MAC 
 PHS 2 
 Tool $2503 
 <<< 
PHS MAC 
 DO ]0 
 LUP ]1 
 PHA 
 --^ 
 ELSE 
 PHA 
 FIN 
 <<< 
~NewControl2 MAC 
 P2SL ]1 
 PHWL ]2;]3 
 Tool $3110 
 <<< 
PHWL MAC 
 PHW ]1 
 PHL ]2 
 <<< 
_SetCtlValue MAC
 Tool $1910 
 <<< 
_GetCtlValue MAC
 Tool $1A10 
 <<< 
~GetCtlHandleFromID MAC
 PHS 2 
 PxL ]1;]2 
 Tool $3010 
 <<< 
_GetCtlHandleFromID MAC
 Tool $3010 
 <<< 
_NewHandle MAC
 Tool $902 
 <<< 
_AddResource MAC
 Tool $C1E 
 <<< 
~UpdateResourceFile MAC
 PHW ]1 
 Tool $D1E 
 <<< 
_UpdateResourceFile MAC
 Tool $D1E 
 <<< 
_RemoveResource MAC
 Tool $F1E 
 <<< 
_MarkResourceChange MAC
 Tool $101E 
 <<< 
~SetCurResourceFile MAC
 PHW ]1 
 Tool $111E 
 <<< 
_SetCurResourceFile MAC
 Tool $111E 
 <<< 
~GetCurResourceFile MAC
 PHA 
 Tool $121E 
 <<< 
~UniqueResourceID MAC
 P2SW ]1 
 PHW ]2 
 Tool $191E 
 <<<
PxL MAC
 DO ]0/1 
 PHL ]1 
 DO ]0/2 
 PHL ]2 
 DO ]0/3 
 PHL ]3 
 DO ]0/4 
 PHL ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
PXL MAC 
 DO ]0/1 
 PHL ]1 
 DO ]0/2 
 PHL ]2 
 DO ]0/3 
 PHL ]3 
 DO ]0/4 
 PHL ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
P2SW MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
_ReleaseResource MAC
 Tool $171E 
 <<< 
_RMSetResourceName mac
 Tool $2D1E 
 <<< 
~RMLoadNamedResource mac
 PHS 2 
 PHWL ]1;]2 
 Tool $2C1E 
 <<< 
~RMFindNamedResource mac
 PHS 2 
 PHW ]1 
 PxL ]2;]3 
 Tool $2A1E 
 <<< 
killLdp MAC
 pld
 ply
 ply
 <<<
~GetIRQEnable MAC
 PHA 
 Tool $2903 
 <<< 
wr MAC
 phd
 <<<
lr MAC
 phd
 phd
 <<<
_GetTick MAC
 Tool $2503 
 <<< 
_UDivide MAC
 Tool $B0B 
 <<< 
_SendRequest MAC
 Tool $1c01
 <<<
_PtrToHand MAC
 Tool $2802 
 <<< 
~GetCurResourceApp MAC
 PHA 
 Tool $141E 
 <<< 
_HexIt MAC
 Tool $2A0B 
 <<< 
