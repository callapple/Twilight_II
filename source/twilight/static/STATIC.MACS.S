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
^NEWHANDLE MAC 
 P2SL ]1 
 PxW ]2;]3 
 PHL ]4 
 Tool $902 
 <<< 
_SOUNDSTARTUP MAC 
 Tool $208 
 <<< 
^SOUNDTOOLSTATUS MAC 
 PHA 
 Tool $608 
 <<< 
^WRITERAMBLOCK MAC 
 PHL ]1 
 PxW ]2;]3 
 Tool $908 
 <<< 
^GETSOUNDVOLUME MAC 
 P1SW ]1 
 Tool $C08 
 <<< 
^SETSOUNDVOLUME MAC 
 PxW ]1;]2 
 Tool $D08 
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
P1SW MAC 
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
TOOL MAC 
 LDX #]1 
 JSL $E10000 
 <<< 
^GETTICK MAC 
 PHS 2 
 Tool $2503 
 <<< 
^SETALLSCBS MAC 
 PHW ]1 
 Tool $1404 
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
