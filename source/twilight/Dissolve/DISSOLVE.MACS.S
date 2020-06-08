^NEWHANDLE MAC 
 P2SL ]1 
 PxW ]2;]3 
 PHL ]4 
 Tool $902 
 <<< 
^DISPOSEHANDLE MAC 
 PHL ]1 
 Tool $1002 
 <<< 
^PTRTOHAND MAC 
 PxL ]1;]2;]3 
 Tool $2802 
 <<< 
PXW MAC 
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
PHW mac 
 if #=]1 
 pea ]1 
 else 
]D = * 
 lda ]1 
 do *-]d/3 
 if MX/2 
 ds -3 
 lda ]1+1 
 pha 
 lda ]1 
 fin 
 pha 
 else 
 ds -2 
 pei ]1 
 fin 
 fin 
 eom 
PULLLONG MAC 
 DO ]0 
 PullWord ]1 
 PullWord ]1+2 
 ELSE 
 PullWord 
 PullWord 
 FIN 
 <<< 
PULLWORD MAC 
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
TOOL MAC 
 LDX #]1 
 JSL $E10000 
 <<< 
PUSHLONG MAC
 IF #=]1 
 PushWord #^]1 
 ELSE 
 PushWord ]1+2 
 FIN 
 PushWord ]1 
 <<< 
PUSHWORD MAC 
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
^MMSTARTUP MAC 
 PHA 
 Tool $202 
 <<< 
_SENDREQUEST MAC 
 Tool $1c01 
 <<< 
