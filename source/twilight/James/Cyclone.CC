/*
**                       Cyclone for T2  by  James C. Smith
*/


/*
** speed  (pixels moved/frame)
*/


#pragma keep "Cyclone"
#pragma cdev Cyclone
#pragma optimize -1
#pragma debug 0

#include "T2.H"
#include "Random3.H"
#include <stdlib.h>
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <string.h>
#include <memory.h>

#pragma lint 0

#define MaxNumLines 90
#define NumX 320
#define NumY 200

#define ControlList                      0x00001003l

#define ShapePopup                       0x00000001l
#define LengthPopup                      0x00000002l
#define ColorPopup                       0x00000003l
#define IconControl                      0x00000004l
#define WidthPopup                       0x00000005l
#define PresetShapes                     0x00000006l
#define HorizontalPopup                  0x00000007l
#define VerticalPopup                    0x00000008l

#define ShapeMenu                        0x00000001l
#define LengthMenu                       0x00000002l
#define ColorMenu                        0x00000003l

#define RandomShape                      0x00000001l
#define LineShape                        0x00000002l
#define VShape                           0x00000003l
#define XShape                           0x00000004l
#define OvalShape                        0x00000005l
#define FilledOvalShape                  0x00000006l
#define RectShape                        0x00000007l
#define FilledRectShape                  0x00000008l
#define RRectShape                       0x00000009l
#define FilledRRectShape                 0x0000000Al
#define Sliding                          0x00000000l
#define Reds                             0x00000001l
#define Blues                            0x00000002l
#define Greens                           0x00000003l
#define DefaultColor                     0x00000004l
#define Earthtone                        0x00000005l
#define Rainbow                          0x00000006l
#define Pastels                          0x00000007l
#define ZShape                           0x0000000Bl
#define Diamond                          0x0000000Cl


pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


LongWord MakeT2Cyclone(void);
void LoadSetupT2Cyclone(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Cyclone(LongWord);
void SaveT2Cyclone(void);

void DrawShape(int,int,int,int);

word OptionWord;
int i, DrawNumber, EraseNumber, X1Hist[MaxNumLines], X2Hist[MaxNumLines], Color;
int Y1Hist[MaxNumLines], Y2Hist[MaxNumLines], X1V, X2V, Y1V, Y2V, X1, X2, Y1, Y2;
int Colors[16], Colors2[16], ColorCount, FirstTime;
int SlideColor, SlideDirection, SlideCounter, SlideMask;
int RectAry[4];
Word *movePtr;
unsigned int ConfigShape, ConfigLength, ConfigColor, ConfigWidth, ActLength, HM, VM, ConfigPreset, IsPreset, LastPreset;
char *ConfigNameString="\pCyclone Config";
Long OldTick=0, TmpTick, CheckIn;
word DefColors[]=
{0x0000,0x0535,0x0A62,0x0831,0x0611,0x0742,0x0762,0x0783,0x0694,0x0395,0x0168,0x0108,0x0617,0x0624,0x0CA2,0x0CA2,\
 0x0000,0x0B22,0x0F00,0x0F70,0x0FF0,0x07F0,0x00C3,0x00A6,0x00FF,0x007F,0x000F,0x070F,0x0F0F,0x0F07,0x0A1E,0x0A1E,\
 0x0000,0x004A,0x018E,0x06C9,0x00DF,0x0FE6,0x0FC9,0x0F9D,0x0D9F,0x0BFC,0x0FF9,0x0FCD,0x0DCF,0x06C9,0x0FE6,0x0FE6};


Word SetupFileNumber;
GrafPortPtr SetupWindow;


int min(int a, int b)
{
    if (a<b) return (a);
    else return(b);
}

int max(int a, int b)
{
    if (a>b) return (a);
    else return(b);
}



void DrawShape(int LX1, int LY1, int LX2, int LY2)
{
	RectAry[0]=min(LY1,LY2)-5;
	RectAry[1]=min(LX1,LX2)-5;
	RectAry[2]=max(LY2,LY1)+5;
	RectAry[3]=max(LX2,LX1)+5;
    switch (ConfigShape)
    {
        case LineShape:
            MoveTo(LX1,LY1);
            LineTo(LX2,LY2);
            break;
        case VShape:
            MoveTo(LX1,LY1);
            LineTo((LX1+LX2)>>1, LY2);
            LineTo(LX2,LY1);
            break;
        case XShape:
            MoveTo(LX1,LY1);
            LineTo(LX2,LY2);
            MoveTo(LX2,LY1);
            LineTo(LX1,LY2);
            break;
        case OvalShape:
            FrameOval((Rect *) &RectAry);
            break;
        case FilledOvalShape:
            PaintOval((Rect *) &RectAry);
            break;
        case RectShape:
            FrameRect((Rect *)&RectAry);
            break;
        case FilledRectShape:
            PaintRect((Rect *) &RectAry);
            break;
        case RRectShape:
            FrameRRect((Rect *) &RectAry,25,25);
            break;
        case FilledRRectShape:
            PaintRRect((Rect *) &RectAry,15,15);
            break;
        case ZShape:
            MoveTo(LX1,LY1);
            LineTo(LX2,(LY1+LY2)>>1);
            LineTo(LX1,(LY1+LY2)>>1);
            LineTo(LX2,LY2);
            break;
        case Diamond:
            MoveTo((LX1+LX2)>>1,LY1);
            LineTo(LX2,(LY1+LY2)>>1);
            LineTo((LX1+LX2)>>1,LY2);
            LineTo(LX1,(LY1+LY2)>>1);
            LineTo((LX1+LX2)>>1,LY1);
            break;
    }  /* end switch shape */
} /* end draw shape function */



LongWord BlankT2Cyclone(void)
{
    CheckIn=0;
    FirstTime=1;
    ColorCount=0;
    Color=15;
    SlideCounter=1;
	init_random(toT2Str);
    set_random_seed();

    if(ConfigLength==1)
        ActLength=0;
    else
        ActLength=(ConfigLength-1)*15;
	SetPenMode(modeCopy);
	SetPenSize(ConfigWidth+1, ConfigWidth+1);
    switch(ConfigColor) {
        case Sliding:
        case Blues:
	        for(i=0; i<16; i++) Colors2[i]=i;
            break;
        case Greens:
	        for(i=0; i<16; i++) Colors2[i]=i<<4;
            break;
        case Reds:
	        for(i=0; i<16; i++) Colors2[i]=i<<8;
            break;
        case DefaultColor:
            InitColorTable(Colors2);
            break;
        case Earthtone:
            memcpy(Colors2, DefColors, 32);
            break;
        case Rainbow:
            memcpy(Colors2, &DefColors[16], 32);
            break;
        case Pastels:
            memcpy(Colors2, &DefColors[32], 32);
            break;
    } /* end switch ConfigColor */
	SetColorTable(0, Colors2);
	X1V=(random() % 3)+3;
	Y1V=(random() % 3)+3;
	do X2V=(random() % 3)+3; while (X2V == X1V);
	do Y2V=(random() % 3)+3; while (Y2V == Y1V);
	DrawNumber=max(0,ActLength-1);
	EraseNumber=0;
	X1=X1Hist[DrawNumber]=(random() % (NumX-30))+15;
	Y1=Y1Hist[DrawNumber]=(random() % (NumY-30))+15;
	X2=X2Hist[DrawNumber]=(random() % (NumX-30))+15;
	Y2=Y2Hist[DrawNumber]=(random() % (NumY-30))+15;
    if(ConfigShape==RandomShape)
        ConfigShape=(random()  % 11) +2;


	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
		if(ColorCount > 0) {
			ColorCount=0;
			Color++;
			if(Color > 15)
				Color=1;
            if(ConfigColor==Sliding){

			if(SlideCounter==1){           /* pick new color to slide and */
				do {
					SlideColor=(random()% 3) <<2;    /* determin the direction to slide in */
					SlideMask= 0x0F << SlideColor;
					if(Colors2[15] & SlideMask) SlideDirection=0;
					else SlideDirection=1;
				} while((Colors2[15] ^ SlideMask)==0);
			}

			for(i=SlideCounter; i < 16; i++)         /* slide the color */
				if (SlideDirection) Colors2[i]+= 1<<SlideColor;
				else Colors2[i]-= 1<<SlideColor;


			SlideCounter++;
			if(SlideCounter>15)
				SlideCounter=1;

            } /* end if slifing colors */
			memcpy(&Colors[1], &Colors2[16-Color], (long) Color<<1);    /* cycle colors */
			if (Color<15) memcpy(&Colors[Color+1], &Colors2[1], (long) (15-Color)<<1);


            if(CheckIn) {
                TmpTick=OldTick;
                while((OldTick=TickCount())==TmpTick);
                CheckIn=0;
            } else
                CheckIn++;
			SetColorTable(0, Colors);
		}
		ColorCount++;
		SetSolidPenPat(Color);
		/*X1=X1Hist[DrawNumber];
		Y1=Y1Hist[DrawNumber];
		X2=X2Hist[DrawNumber];
		Y2=Y2Hist[DrawNumber];  */
        DrawShape(X1,Y1,X2,Y2);
        if(HM) DrawShape(NumX-X1,Y1,NumX-X2,Y2);
        if (VM) DrawShape(X1,NumY-Y1,X2,NumY-Y2);
        if (VM && HM) DrawShape(NumX-X1,NumY-Y1,NumX-X2,NumY-Y2);
        if(ActLength) {
		    SetSolidPenPat(0);
            if(EraseNumber+1>=ActLength)
                FirstTime=0;
            if(!FirstTime){
                DrawShape(X1Hist[EraseNumber],Y1Hist[EraseNumber],X2Hist[EraseNumber],Y2Hist[EraseNumber]);
                if(HM)DrawShape(NumX-X1Hist[EraseNumber],Y1Hist[EraseNumber],NumX-X2Hist[EraseNumber],Y2Hist[EraseNumber]);
                if(VM)DrawShape(X1Hist[EraseNumber],NumY-Y1Hist[EraseNumber],X2Hist[EraseNumber],NumY-Y2Hist[EraseNumber]);
                if(VM && HM)DrawShape(NumX-X1Hist[EraseNumber],NumY-Y1Hist[EraseNumber],NumX-X2Hist[EraseNumber],NumY-Y2Hist[EraseNumber]);
            }
		    DrawNumber++;
		    if(DrawNumber >= ActLength)
			    DrawNumber=0;
		    EraseNumber++;
		    if(EraseNumber >= ActLength)
			    EraseNumber=0;
        }
		X1+=X1V;
		Y1+=Y1V;
		X2+=X2V;
		Y2+=Y2V;
		if(X1 < 5 || X1 > NumX-1)
			X1V=-X1V;
		if(Y1 < 5 || Y1 > NumY-1)
			Y1V=-Y1V;
	    if(X2 < 5 || X2 > NumX-1)
			X2V=-X2V;
		if(Y2 < 5 || Y2 > NumY-1)
			Y2V=-Y2V;
        if(ActLength) {
		    X1Hist[DrawNumber]=X1;
		    Y1Hist[DrawNumber]=Y1;
		    X2Hist[DrawNumber]=X2;
		    Y2Hist[DrawNumber]=Y2;
        }
	}
    ClearScreen (0);
	return (LongWord) NULL;
}


void SaveT2Cyclone(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigShape = GetCtlValue (GetCtlHandleFromID (SetupWindow, ShapePopup));
	ConfigLength = GetCtlValue (GetCtlHandleFromID (SetupWindow, LengthPopup));
	ConfigColor = GetCtlValue (GetCtlHandleFromID (SetupWindow, ColorPopup))-1;
    ConfigWidth = GetCtlValue (GetCtlHandleFromID (SetupWindow, WidthPopup))-1;
	HM          = GetCtlValue (GetCtlHandleFromID (SetupWindow, HorizontalPopup));
    VM          = GetCtlValue (GetCtlHandleFromID (SetupWindow, VerticalPopup));
    OptionWord=(IsPreset<<15) | (ConfigWidth<<12) | (ConfigShape << 8) | (VM<<7) | (ConfigLength << 4) | (HM<<3) | ConfigColor;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Cyclone(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == ShapePopup) {
	    ConfigShape = GetCtlValue (GetCtlHandleFromID (SetupWindow, ShapePopup));
		EnableFlag = 1L;       }
	if (ControlHit == LengthPopup) {
	    ConfigLength = GetCtlValue (GetCtlHandleFromID (SetupWindow, LengthPopup));
		EnableFlag = 1L;       }
	if (ControlHit == ColorPopup) {
	    ConfigColor = GetCtlValue (GetCtlHandleFromID (SetupWindow, ColorPopup))-1;
		EnableFlag = 1L;       }
	if (ControlHit == WidthPopup) {
        ConfigWidth = GetCtlValue (GetCtlHandleFromID (SetupWindow, WidthPopup))-1;
		EnableFlag = 1L;       }
	if (ControlHit == HorizontalPopup) {
	    HM          = GetCtlValue (GetCtlHandleFromID (SetupWindow, HorizontalPopup));
		EnableFlag = 1L;       }
	if (ControlHit == VerticalPopup)  {
        VM          = GetCtlValue (GetCtlHandleFromID (SetupWindow, VerticalPopup));
		EnableFlag = 1L;       }
    if(EnableFlag && ConfigPreset!=1) {
	    SetCtlValue (1, GetCtlHandleFromID (SetupWindow, PresetShapes));
        IsPreset=0;
        ConfigPreset=1;
    }
    OptionWord= (ConfigWidth<<12) | (ConfigShape << 8) | (VM<<7) | (ConfigLength << 4) | (HM<<3) | ConfigColor;
	if (ControlHit == PresetShapes) {
		EnableFlag = 1L;
	    ConfigPreset=OptionWord = GetCtlValue (GetCtlHandleFromID (SetupWindow, PresetShapes));
        LastPreset=OptionWord;
        IsPreset=1;
        if(OptionWord != 1){
            ConfigWidth = (OptionWord & 0xF000) >> 12;
            ConfigShape = (OptionWord & 0x0F00) >> 8;
            ConfigLength = (OptionWord & 0x0070) >> 4;
            ConfigColor = OptionWord & 0x0007;
            VM           = (OptionWord & 0x0080) >> 7;
            HM           = (OptionWord & 0x0008) >> 3;
	        SetCtlValue (ConfigShape, GetCtlHandleFromID (SetupWindow, ShapePopup));
	        SetCtlValue (ConfigLength, GetCtlHandleFromID (SetupWindow, LengthPopup));
	        SetCtlValue (ConfigColor+1, GetCtlHandleFromID (SetupWindow, ColorPopup));
	        SetCtlValue (ConfigWidth+1, GetCtlHandleFromID (SetupWindow, WidthPopup));
	        SetCtlValue (HM, GetCtlHandleFromID (SetupWindow, HorizontalPopup));
	        SetCtlValue (VM, GetCtlHandleFromID (SetupWindow, VerticalPopup));
        }
    }
    if(LastPreset==OptionWord && ConfigPreset==1){
        IsPreset=1;
        ConfigPreset=LastPreset;
	    SetCtlValue (LastPreset, GetCtlHandleFromID (SetupWindow, PresetShapes));
    }
	return EnableFlag;
}


/*****************************************************************************\
|*																									  *|
|*	LoadConfigResource-	(updated)																  *|
|*			This function attempts to load a named rT2ModuleWord resource.  if  *|
|*			the resource exists, the value of the rT2ModuleWord resource is	  *|
|*			returned, otherwise a default value is returned.						  *|
|*																									  *|
\*****************************************************************************/

Word LoadConfigResource (char *Name, Word DefaultValue)
{
	Word Result, fileID;
	Long rID;
	Handle ConfigData;
    struct {
        word Type;
        Long ID;
    } HandleInfo;


/**************************************/
/* Attempt to load the named resource */
/**************************************/

	rID = RMFindNamedResource((Word) rT2ModuleWord, (Ptr) Name, &fileID);

	ConfigData = LoadResource((Word) rT2ModuleWord, rID);
	if (toolerror ())
		Result = DefaultValue; /* Resource does not exist, so return the default value */
	else
   {
       HLock(ConfigData);  /* Resource exists, return the rT2Module word value */
		Result = **(word **)ConfigData;
		HUnlock(ConfigData);

		ReleaseResource(3, (Word) rT2ModuleWord, rID);
    }

	 return Result;
}




/*****************************************************************************\
|*																									  *|
|*		SaveConfigResource-																	  *|
|*			This function takes a word value and saves it as a rT2ModuleWord	  *|
|*			resource in the Twilight.Setup file.  The value is saved and a		  *|
|*			name is added.  Any previous rT2ModuleWord with the same name is	  *|
|*			first removed before the new value is added.								  *|
|*																									  *|
\*****************************************************************************/

void SaveConfigResource (char *Name, Word SaveValue)
{
	Word FileID;
	Long ResourceID;
	Word **ConfigData;

/******************************************************/
/*  Check to see if the named resource already exists */
/******************************************************/

	ResourceID = RMFindNamedResource (rT2ModuleWord, Name, &FileID);
	if (!toolerror ())
	{
		char NullString = '\x000';

/**************************************************************/
/* The resource already exists, so first remove the name from */
/*	the resource, then remove the resource itself				  */
/**************************************************************/

		RMSetResourceName (rT2ModuleWord, ResourceID, &NullString);
		RemoveResource (rT2ModuleWord, ResourceID);
	}

/*********************************************/
/* Create new handle for the future resource */
/*********************************************/

	ConfigData =
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, NULL);
	**ConfigData = SaveValue;

/*********************************************/
/* Find a new ID for the resource and add it */
/*********************************************/

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource ((Handle) ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle ((Handle) ConfigData);
	else
	{

/**********************************************************/
/* Set the name of the resource if it was added correctly */
/**********************************************************/

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
		/*DisposeHandle (ConfigData);     */
	}
}

LongWord MakeT2Cyclone (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Cyclone();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigShape, GetCtlHandleFromID (SetupWindow, ShapePopup));
	SetCtlValue (ConfigLength, GetCtlHandleFromID (SetupWindow, LengthPopup));
	SetCtlValue (ConfigColor+1, GetCtlHandleFromID (SetupWindow, ColorPopup));
	SetCtlValue (ConfigWidth+1, GetCtlHandleFromID (SetupWindow, WidthPopup));
	SetCtlValue (HM, GetCtlHandleFromID (SetupWindow, HorizontalPopup));
	SetCtlValue (VM, GetCtlHandleFromID (SetupWindow, VerticalPopup));
    if(IsPreset) {
	    SetCtlValue (OptionWord & 0x7FFF, GetCtlHandleFromID (SetupWindow, PresetShapes));
        LastPreset=ConfigPreset=OptionWord & 0x7FFF;;
    }else  {
	    SetCtlValue (1, GetCtlHandleFromID (SetupWindow, PresetShapes));
        ConfigPreset=1;
        LastPreset=0;
    }
	return 0x0Al;
}



void LoadSetupT2Cyclone(void)
{

/*  Option word format
**     0x8000 = IsPreset
**     0x7000 = Width
**     0x0F00 = Shape
**     0X0080 = VerticalMirror
**     0x0070 = Length
**     0X0008 = HorizontalMirror
**     0x0007 = Color
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x9610);
    IsPreset =    (OptionWord & 0x8000) >> 15;
    ConfigWidth = (OptionWord & 0x7000) >> 12;
    ConfigShape = (OptionWord & 0x0F00) >> 8;
    ConfigLength = (OptionWord & 0x0070) >> 4;
    ConfigColor = OptionWord & 0x0007;
    VM           = (OptionWord & 0x0080) >> 7;
    HM           = (OptionWord & 0x0008) >> 3;
}



LongWord Cyclone(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Cyclone ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Cyclone ();
			break;
		case SaveT2:
			SaveT2Cyclone();
		    break;
		case LoadSetupT2:
			LoadSetupT2Cyclone();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Cyclone(data2);
			break;
	}
	return Result;
}