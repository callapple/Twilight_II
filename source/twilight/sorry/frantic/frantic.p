
{$DeskAcc -1 -1 'Frantic'} 
{$LongGlobals+} 

{  August 6, 1987  }
{  Frantic NDA written by:  }
{  Floyd Zink, Jr.  }
{  CIS 73147,2717  }
{  Genie  F.ZINK   }

{  This is public domain.  You can do what ever you want with this. }


program FranticNDA;

uses QDIntf, GSIntf, MiscTools, ConsoleIO;

var
   Open       : boolean; 
   myWindPtr  : WindowPtr;


procedure dofrantic; forward;  

function DAOpen: WindowPtr; 

var myWind: NewWindowParamBlk; 

begin
  if open then exit;
    fillchar(myWind,sizeof(NewWindowParamBlk),0); 
    with myWind do 
    begin 
      param_length := sizeof(NewWindowParamBlk);
      wFrame := $0020;         
      wPosition.top   := 5;  { Copied window idea from }
      wPosition.left  := 5;  { Jason Harper's MeltDown NDA }
      wPosition.bottom:= 6;
      wPosition.right := 6;
      wPlane := -1;  
      wStorage := nil; 
    end; 
    myWindPtr := NewWindow(myWind);   
    SetSysWindow(myWindPtr);              
    Open := true; 
    DAOpen := myWindPtr;
    dofrantic; 
end; 

procedure DAClose;                    
begin
   if Open then CloseWindow(myWindPtr); 
   Open := false; 
end; 

procedure DAAction(Code:Integer; Param:Longint); 
begin
   CloseNDAByWinPtr(myWindPtr);
end; 

procedure DAInit(Code:Integer);     
begin
  if (Code = 0) and Open then DAClose; 
  Open := false; 
end; 

procedure dofrantic;      
var
   currPort   : GrafPtr;     
   screenwidth,screenheight,color,dh,dv,
   sh,sv,len,dir,k,old_dir,j : integer;
   newr: Rect;
   eventrec: EventRecord;
   done:boolean;

begin
   HideCursor;              
   if GetMasterSCB >= 128         
     then screenwidth := 640
     else screenwidth := 320;
   screenheight:=200;
   currPort := GetPort;
   SetPort(GetMenuMgrPort); 
   sh:=6; sv:=3;
   done:=false;
   newr.left:= Random mod (screenwidth+1);
   newr.top := Random mod (screenheight+1);
   newr.right:=newr.left+sh;
   newr.bottom:=newr.top+sv;
   old_dir:=0;
   repeat
     color:= random mod 16;
     setdithcolor(color);
     for j:=1 to 20 do 
     begin
       dir:=random mod 2;
       case old_dir of
       0: if dir=0 then dir:=3 else dir:=1;
       1: if dir=1 then dir:=2;
       2: if dir=0 then dir:=1 else dir:=3;
       3: if dir=1 then dir:=2;
       end;
       old_dir:=dir;
       case dir of
       0: begin
            len:=(random mod newr.top) div sv;
            dh:=0; dv:=-sv;
          end;
       1: begin
            len:=(random mod (screenwidth-newr.right)) div sh;
            dh:=sh; dv:=0;
         end;
       2: begin
            len:=(random mod (screenheight-newr.bottom)) div sv;
            dh:=0; dv:=sv;
          end;
       3: begin
            len:=(random mod newr.left) div sh;
            dh:=-sh; dv:=0;
           end;
        end; 
       for k:=1 to len do begin
          offsetrect(newr,dh,dv);
          paintrect(newr);
       end;
       if GetOSEvent(MDownMask+KeyDownMask,eventrec) then
       begin
         done:=true;
         leave;
       end;   
       end;     
   until Done; 
   SetPort(currPort);
   DrawMenuBar;     
   Refresh(nil);
   ShowCursor;
end; 

begin 
end.  
