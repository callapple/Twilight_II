_TLStartUp MAC 
 Tool $201 
 <<< 
_TLShutDown MAC 
 Tool $301 
 <<< 
~MMStartUp MAC 
 PHA 
 Tool $202 
 <<< 
~MMShutDown MAC 
 PHW ]1 
 Tool $302 
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
~QDStartUp MAC 
 PxW ]1;]2;]3;]4 
 Tool $204 
 <<< 
_QDShutDown MAC 
 Tool $304 
 <<< 
_SetSolidPenPat MAC 
 Tool $3704 
 <<< 
~FrameOval MAC 
 PHL ]1 
 Tool $5804 
 <<< 
_QUIT MAC 
 DOS16 $29;]1 
 <<< 
DOS16 MAC 
 JSL $E100A8 
 DA ]1 
 ADRL ]2 
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
PHL MAC 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
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
Tool MAC 
 LDX #]1 
 JSL $E10000 
 <<< 
~SetHeartBeat MAC 
 PHL ]1 
 Tool $1203 
 <<< 
~DelHeartBeat MAC 
 PHL ]1 
 Tool $1303 
 <<< 
~SetPenPat MAC 
 PHL ]1 
 Tool $3004 
 <<< 
~GetPenPat MAC 
 PHL ]1 
 Tool $3104 
 <<< 
~InitPort MAC 
 PHL ]1 
 Tool $1904 
 <<< 
~SetPort MAC 
 PHL ]1 
 Tool $1B04 
 <<< 
~GetPort MAC 
 PHS 2 
 Tool $1C04 
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
~OpenPort MAC 
 PHL ]1 
 Tool $1804 
 <<< 
_SetMasterSCB MAC 
 Tool $1604 
 <<< 
~GetMasterSCB MAC 
 PHA 
 Tool $1704 
 <<< 
~SetMasterSCB MAC 
 PHW ]1 
 Tool $1604 
 <<< 
~ClosePort MAC 
 PHL ]1 
 Tool $1A04 
 <<< 
