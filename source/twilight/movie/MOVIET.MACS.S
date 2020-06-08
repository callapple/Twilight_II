_DISPOSECONTROL MAC 
 Tool $A10 
 <<< 
_HIDECONTROL MAC 
 Tool $E10 
 <<< 
^GETCTLHANDLEFROMID MAC 
 PHS 2 
 PxL ]1;]2 
 Tool $3010 
 <<< 
^NEWCONTROL2 MAC 
 P2SL ]1 
 PHWL ]2;]3 
 Tool $3110 
 <<< 
_NEWCONTROL2 MAC 
 Tool $3110 
 <<< 
^LOADONETOOL MAC 
 PxW ]1;]2 
 Tool $F01 
 <<< 
^UNLOADONETOOL MAC 
 PHW ]1 
 Tool $1001 
 <<< 
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
^GETHANDLESIZE MAC 
 P2SL ]1 
 Tool $1802 
 <<< 
_SETHANDLESIZE MAC 
 Tool $1902 
 <<< 
^HLOCK MAC 
 PHL ]1 
 Tool $2002 
 <<< 
_PTRTOHAND MAC 
 Tool $2802 
 <<< 
^BLOCKMOVE MAC 
 PxL ]1;]2;]3 
 Tool $2B02 
 <<< 
_ADDRESOURCE MAC 
 Tool $C1E 
 <<< 
^UPDATERESOURCEFILE MAC 
 PHW ]1 
 Tool $D1E 
 <<< 
^LOADRESOURCE MAC 
 P2SW ]1 
 PHL ]2 
 Tool $E1E 
 <<< 
_REMOVERESOURCE MAC 
 Tool $F1E 
 <<< 
^SETCURRESOURCEFILE MAC 
 PHW ]1 
 Tool $111E 
 <<< 
_SETCURRESOURCEFILE MAC 
 Tool $111E 
 <<< 
^GETCURRESOURCEFILE MAC 
 PHA 
 Tool $121E 
 <<< 
^RELEASERESOURCE MAC 
 PxW ]1;]2 
 PHL ]3 
 Tool $171E 
 <<< 
_DETACHRESOURCE MAC 
 Tool $181E 
 <<< 
^UNIQUERESOURCEID MAC 
 P2SW ]1 
 PHW ]2 
 Tool $191E 
 <<< 
_SFSTARTUP MAC 
 Tool $217 
 <<< 
_SFSHUTDOWN MAC 
 Tool $317 
 <<< 
^SFSTATUS MAC 
 PHA 
 Tool $617 
 <<< 
_SFGETFILE2 MAC 
 Tool $E17 
 <<< 
_COMPILETEXT MAC 
 Tool $600E 
 <<< 
BEQL MAC 
 BNE OV 
 BRL ]1 
OV <<< 
PHWL MAC 
 PHW ]1 
 PHL ]2 
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
PHS MAC 
 DO ]0 
 LUP ]1 
 PHA 
 --^ 
 ELSE 
 PHA 
 FIN 
 <<< 
P2SW MAC 
 PHA 
 PHA 
 do ]0=0 
 pha 
 else 
 phw ]1 
 fin 
 eom 
PUSHWORD mac 
 do ]0=0 
 pha 
 else 
 phw ]1 
 fin 
 eom 
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
PUSHLONG MAC 
 IF #=]1 
 PushWord #^]1 
 ELSE 
 PushWord ]1+2 
 FIN 
 PushWord ]1 
 <<< 
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
CLOSE_GS mac 
 GSOS $2014;]1 
 eom 
OPEN_GS mac 
 GSOS $2010;]1 
 eom 
READ_GS mac 
 GSOS $2012;]1 
 eom 
GSOS mac 
 jsl $E100A8 
 da ]1 
 adrl ]2 
 eom 
_RMSETRESOURCENAME mac 
 Tool $2D1E 
 <<< 
^RMLOADNAMEDRESOURCE mac 
 PHS 2 
 PHWL ]1;]2 
 Tool $2C1E 
 <<< 
~RMFindNamedResource mac ;sys6.0
 PHS 2
 PHW ]1
 PxL ]2;]3
 Tool $2A1E
 <<<

_RMFindNamedResource mac
 Tool $2A1E
 <<<
_NEWHANDLE MAC 
 Tool $902 
 <<< 
^HEXIT MAC 
 P2SW ]1 
 Tool $2A0B 
 <<< 
_SetHandleID MAC
 Tool $3002
 <<<
^GETCURRESOURCEAPP MAC 
 PHA 
 Tool $141E 
 <<< 
^MMSTARTUP MAC 
 PHA 
 Tool $202 
 <<< 
