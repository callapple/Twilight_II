*------------------------------------------------*
*                                                *
*                    Tunnel                      *
*            A Twilight II blanker               *
*                By Derek Young                  *
*                                                *
*------------------------------------------------*
 lst off
 rel
 xc
 xc
 mx %00
 use Tunnel.macs


 dum $00
Color da 0 ;for drawing the circles
i da 0

DP adrl 0

MyID da 0
MemID da 0
 dend

delay = 1
NumCircles = 189

 phk
 plb

 lda #$FFF
 sta LastC

 lda #$FFF
 stal $E19E00


 stz CycleColor
 stz VCount

* ~SetHeartBeat #Cycler

 jsr StartUp
 jsr DrawCircles

 sep $20
]loop ldal $C000
 bpl ]loop
 stal $C010
 rep $20

* ~DelHeartBeat #Cycler

 jsr ShutDown

 _QUIT :1
:1 adrl 0
 da 0

*-------------------------------------------------
* Draw the huge ring of circles on the screen

DrawCircles

 lda #160
 sta h1
 sta h2
 lda #100
 sta v1
 sta v2
 lda #1
 sta Color

 lda #NumCircles
 sta i
:Loop
 pei Color
 _SetSolidPenPat
   ;yuck!  QuickDraw :(
 ~FrameOval #CRect

 lda Color
 inc
 and #%1111 ;keep it between 0 and fifteen
 bne :ok
 inc  ;skip 1
:ok sta Color

 dec v1
 dec h1
 inc v2
 inc h2

 dec i
 bne :Loop
 rts

CRect
v1 da 0
h1 da 0
v2 da 0
h2 da 0

*-------------------------------------------------
* The color cycler.
* It uses a heartbeat task.

Cycler
 adrl 0
Period da delay
 da $A55A

 phk
 plb
 rep $30
 lda #delay
 sta Period

 lda #$FFFF
 sta DoNext

 lda VCount
 inc
 sta VCount
 cmp #91
 bge :bigger
 stz DoNext
:bigger

 phb  ;Cycle the 15 first colors
 pea $E1E1
 plb
 plb

* lda $9E02
* sta $9E00
 lda $9E04
 sta $9E02
 lda $9E06
 sta $9E04
 lda $9E08
 sta $9E06
 lda $9E0A
 sta $9E08
 lda $9E0C
 sta $9E0A
 lda $9E0E ;move each color down one
 sta $9E0C
 lda $9E10
 sta $9E0E
 lda $9E12
 sta $9E10
 lda $9E14
 sta $9E12
 lda $9E16
 sta $9E14
 lda $9E18
 sta $9E16
 lda $9E1A
 sta $9E18
 lda $9E1C
 sta $9E1A
 lda $9E1E
 sta $9E1C
 plb

 lda VCount
 cmp #91
 blt :smaller
 stz VCount
:smaller

 lda LastC
 stal $E19E1E

 lda DoNext
 beq :else ;false...

 ldy CycleColor
 cpy #90*2
 blt :ok
 ldy #0
:ok lda CycleTable,y
 sta LastC
 iny
 iny
 sty CycleColor
 stz DoNext

 rtl

:else
 ldal $E19E02
 sta LastC

 rtl

Timer da 0
LastC da 0
DoNext da 0
VCount da 0

CycleColor da 0

CycleTable da $F00,$F10,$F20,$F30,$F40,$F50,$F60,$F70,$F80
 da $F90,$FA0,$FB0,$FC0,$FD0,$FE0,$FF0,$EF0,$DF0
 da $CF0,$BF0,$AF0,$9F0,$8F0,$7F0,$6F0,$5F0,$4F0
 da $3F0,$2F0,$1F0,$0F0,$0F1,$0F2,$0F3,$0F4,$0F5
 da $0F6,$0F7,$0F8,$0F9,$0FA,$0FB,$0FC,$0FD,$0FE
 da $0FF,$0EF,$0DF,$0CF,$0BF,$0AF,$09F,$08F,$07F
 da $06F,$05F,$04F,$03F,$02F,$01F,$00F,$10F,$20F
 da $30F,$40F,$50F,$60F,$70F,$80F,$90F,$A0F,$B0F
 da $C0F,$D0F,$E0F,$F0F,$F0E,$F0D,$F0C,$F0B,$F0A
 da $F09,$F08,$F07,$F06,$F05,$F04,$F03,$F02,$F01

*-------------------------------------------------
* Startup QuickDraw and the other tools
* (Won't be needed for the blanker :)
*-------------------------------------------------

StartUp
 _TLStartUp
 ~MMStartUp
 PullWord MyID
 ora #$100
 sta MemID

 ~NewHandle #$300;MemID;#$C005;#0
 PullLong DP

 ~QDStartUp [DP];#0;#160;MyID
 rts


ShutDown
 _QDShutDown
 ~DisposeAll MemID
 ~MMShutDown MyID
 _TLShutDown
 rts

 typ S16
 sav Tunnel.l

 end

If DoNext=true then begin
  SetColorEntry(0,15,LastC);              {restore last color}
  TbCol:=TBCol+1;
  If TBCol=91 then TBCol:=1;
  LastC:=Table[TBCol];             {get last color}
  DoNext:=False;                         {set to false}
  end {IF donext}
else begin
  SetColorEntry(0,15,LastC);
  LastC:=GetColorEntry(0,1);
  end; {Else}
for x:=1 to waittime do begin
  end; {For X}
end; {Cycle}


InitScreen;                             {Start up graphics}
DrawCircles;                            {Draw the screen}
LastC:=$FFF;                            {pure white}
TBCol:=1;                               {table counter}
VCount:=0;
WaitTime:=800;                          {time to pause during cycle}
Quitflag:=false;
repeat
 VCount:=VCount+1;                     {counter}
 DoNext:=True;
 if VCount<=90 then DoNext:=False;      {indicate we want to cycle}
 Cycle;                                {Cycle the Colors}
 If VCount>90 then VCount:=0;         {reset counter}
 Process;
 if Waittime>2700 then waittime:=2699;
 if waittime<100 then waittime:=101;
 until quitflag=true;
