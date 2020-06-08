{$Keep 'Tunnel'}

program Tunnels;

uses Common,QuickDrawII;

const
   circles=189;                         {number of times to iterate draw}
   LeftArrow=$08;
   RightArrow=$15;
   UpArrow=$0B;
   DownArrow=$0A;
   Escape=$1B;
   SpaceBar=$20;

type
   CirclePosition=record
     Xpos:integer;                      {UL postn of X}
     Ypos:integer;                      {UL Postn of y}
{     LRXPos:integer;                     Lwr Rt postn of X}
{     LRYPos:integer;                     Lwr Rt postn of Y}
     Color:integer;                     {Color of this circle}
     end;


var
    CirclePos:CirclePosition;           {see above record}
    CRect:rect;                         {used to define rect for Oval}
    TempColors:Packed Array[1..16] of integer; {used to keep track of colors}
    LastC:integer;                      {last color variable}
    Table:packed array[1..90] of integer; {table}
    TBCol:integer;                      {keeps track of loc. in table}
    DoNext:Boolean;                     {true/false val of cycle}
    VCount:integer;                     {counter}
    waittime:integer;                   {user set wait time}
    quitflag:boolean;                   {to quit}
    ThisCol:integer; {Keep track of which color is next}
    Temp1: integer; {Position for R - $x00}
    Temp2: integer; {Position for G - $0x0}
    Temp3: integer; {Position for B - $00x}
    CNum: integer; {Position of TempColors array}


{Each time we need the right hand/bottom side of the circle, we will simply
 add a multiple of 2, or the equation
      Iteration Number * 2 = New position}

function GetKey: integer;  var keyboard, strobe: ^byte;
         begin
         keyboard:=pointer($00C000); strobe:=pointer($00C010);
         getkey:=keyboard^ & $7F;
         strobe^:=0;
         end;

Procedure InitScreen;

{Sets up the screen for drawing}

begin {InitScreen}
StartGraph(320);
SetPenMode(0);
SetPenSize(1,1);
SetBackColor(0);                        {Set up background to black}
end; {InitScreen}

Procedure DrawCircles ;

{Draws the circles on the screen... see above for equation for figuring
 out which number is which}

var
  jz:integer;                           {loop counter for drawing}

begin {DrawCircles}
for jz:=0 to circles do begin
  with Crect do begin
    v1:=CirclePos.ypos;
    h1:=CirclePos.xpos;
    v2:=CirclePos.ypos+(jz*2);          {See above equation}
    h2:=CirclePos.xpos+(jz*2);
    end; {With}
  SetSolidPenPat(CirclePos.Color);      {Set Pen Color}
  FrameOval(Crect);                     {Draw the oval}
  With CirclePos do begin
    xpos:=CirclePos.xpos-1;
    ypos:=CirclePos.ypos-1;
    Color:=CirclePos.Color+1;
    end; {With}
  If CirclePos.color=16 then CirclePos.color:=1;
  end; {for jz}
end; {DrawCircles}

procedure Process;

{process keypresses}

begin {process}
Case GetKey of
        LeftArrow:WaitTime:=WaitTime+1;
        DownArrow:WaitTime:=WaitTime+20;
        RightArrow:WaitTime:=WaitTime-1;
        UpArrow:WaitTime:=WaitTime-20;
        Escape:Quitflag:=true;
        SpaceBar:WaitTime:=800;
        otherwise: ;
        end; {case getkey of}
end; {process}

procedure Cycle;

var
   Colors:integer;                      {color to be stored}
   z:integer;                           {loop counter}
   x:integer;                           {wait var}

begin {Cycle}

for z:=2 to 15 do begin                  {Set colors 1-14}
 Colors:=GetColorEntry(0,z);
 SetColorEntry(0,z-1,Colors);            {move colors down}
 end; {For z}

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

procedure Action;

  begin {Action}
  ThisCol:=TempColors[CNum];            {set up the color}
  Temp1:=ThisCol&$F00;
  If Temp1<>0 then temp1:=temp1-1;
  Temp2:=ThisCol&$0F0;
  If Temp2<>0 then temp2:=temp2-1;
  Temp3:=ThisCol&$00F;
  if Temp3<>0 then temp3:=temp3-1;
  Temp1:=Temp1*$100;
  Temp2:=Temp2*$010;
  ThisCol:=(Temp1+Temp2+Temp3);
end; {Action}

Procedure Fadeout;

{Fades out screen. Does stupid, simple fadeout by simply ANDing off
 a position of the color value ($00F, $0F0, or $F00) and decrementing
 it by $001 or $010 or $100.

 Check first to see if it's a zero, if it is, continue}
  var
    OhWaiter: integer; {wait fade counter}

begin {Fadeout}
Cnum:=0;
repeat
  Action;         {action of the subroutine}
  SetColorEntry(0,Cnum,ThisCol);
  Cnum:=Cnum+1;
  for OhWaiter:=1 to 32700 do begin
      end; {for}
until cnum=17;
 end; {Fadeout}



{------------------------------------------------------------------------}
begin {MAIN LOOP}
with CirclePos do begin
  xpos:=160;
  ypos:=100;
{ LRXpos:=160;   }
{ LRYPos:=160;   }
  Color:=1;
  end;
Table[1]:=$F00;
Table[2]:=$F10;
Table[3]:=$F20;
Table[4]:=$F30;
Table[5]:=$F40;
Table[6]:=$F50;
Table[7]:=$F60;
Table[8]:=$F70;
Table[9]:=$F80;
TABLE[10]:=$F90;
TABLE[11]:=$FA0;
TABLE[12]:=$FB0;
TABLE[13]:=$FC0;
TABLE[14]:=$FD0;
TABLE[15]:=$FE0;
TABLE[16]:=$FF0;
TABLE[17]:=$EF0;
TABLE[18]:=$DF0;
TABLE[19]:=$CF0;
TABLE[20]:=$BF0;
TABLE[21]:=$AF0;
TABLE[22]:=$9F0;
TABLE[23]:=$8F0;
TABLE[24]:=$7F0;
TABLE[25]:=$6F0;
TABLE[26]:=$5F0;
TABLE[27]:=$4F0;
TABLE[28]:=$3F0;
TABLE[29]:=$2F0;
TABLE[30]:=$1F0;
TABLE[31]:=$0F0;
TABLE[32]:=$0F1;
TABLE[33]:=$0F2;
TABLE[34]:=$0F3;
TABLE[35]:=$0F4;
TABLE[36]:=$0F5;
TABLE[37]:=$0F6;
TABLE[38]:=$0F7;
TABLE[39]:=$0F8;
TABLE[40]:=$0F9;
TABLE[41]:=$0FA;
TABLE[42]:=$0FB;
TABLE[43]:=$0FC;
TABLE[44]:=$0FD;
TABLE[45]:=$0FE;
TABLE[46]:=$0FF;
TABLE[47]:=$0EF;
TABLE[48]:=$0DF;
TABLE[49]:=$0CF;
TABLE[50]:=$0BF;
TABLE[51]:=$0AF;
TABLE[52]:=$09F;
TABLE[53]:=$08F;
TABLE[54]:=$07F;
TABLE[55]:=$06F;
TABLE[56]:=$05F;
TABLE[57]:=$04F;
TABLE[58]:=$03F;
TABLE[59]:=$02F;
TABLE[60]:=$01F;
TABLE[61]:=$00F;
TABLE[62]:=$10F;
TABLE[63]:=$20F;
TABLE[64]:=$30F;
TABLE[65]:=$40F;
TABLE[66]:=$50F;
TABLE[67]:=$60F;
TABLE[68]:=$70F;
TABLE[69]:=$80F;
TABLE[70]:=$90F;
TABLE[71]:=$A0F;
TABLE[72]:=$B0F;
TABLE[73]:=$C0F;
TABLE[74]:=$D0F;
TABLE[75]:=$E0F;
TABLE[76]:=$F0F;
TABLE[77]:=$F0E;
TABLE[78]:=$F0D;
TABLE[79]:=$F0C;
TABLE[80]:=$F0B;
TABLE[81]:=$F0A;
TABLE[82]:=$F09;
TABLE[83]:=$F08;
TABLE[84]:=$F07;
TABLE[85]:=$F06;
TABLE[86]:=$F05;
TABLE[87]:=$F04;
TABLE[88]:=$F03;
TABLE[89]:=$F02;
TABLE[90]:=$F01;

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

Fadeout;

EndGraph;

End. {Main program}

{Append 'Circles.asm'}