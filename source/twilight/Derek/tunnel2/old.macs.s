^INITIALLOAD2 MAC 
 PHS 5 
 PHWL ]1;]2 
 PxW ]3;]4 
 Tool $2011 
 <<< 
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
