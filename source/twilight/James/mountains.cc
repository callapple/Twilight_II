/*
**                       Mountain for T2  by  James C. Smith
*/

#pragma keep "Mountain"
#pragma cdev Mountain
#pragma optimize -1
#pragma debug 0

#include "T2f.H"
#include "Random3.H"


#define NumColors 7              /* number of colors we can access from our custom color palette */
#define NumShades 11             /* number of shades we can derive from each color */


#define MountainIcon                     0x0010DD01l

#define ControlList                      0x00001003l

#define DetailPopUp                      0x00000001l
#define SmoothnesPopUp                   0x00000002l
#define DelayPopUp                       0x00000003l
#define IconControl                      0x00000004l
#define QuitAfterOneCB                   0x00000005l

#define MaxXRes    129
#define MaxYRes    129

#include <string.h>
#include <stdlib.h>
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <orca.h>
#include <locator.h>
#include <memory.h>

pascal void SysBeep() inline(0x2C03,dispatcher);
pascal LongWord TickCount() inline(0x1006,dispatcher);


typedef longword Pattern2[8];  /* this is another, more convenient way of representing QuickDraw's Pattern data structure */
extern Pattern2 ditherColor[NumColors][NumShades]; /* the array of dithered colors with shades per color */
extern void SetCustomDitherColorPatterns(void);


#pragma lint -1


void Plot(int x, int y, int color);
void Subdivite(int x1, int y1, int x2, int y2);
void SetColor(int xa, int ya, int x, int y, int xb, int yb);
void MySetColorTable(void);
void DrawTriangle(int, int, int, int, int, int);
int PickColor(int/*, int*/);

LongWord MakeT2Mountain(void);
void LoadSetupT2Mountain(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Mountain(LongWord);
void SaveT2Mountain(void);
LongWord BlankT2Mountain(void);

void D3(int X,int Y, int *X2, int *Y2);

char *ConfigNameString="\pMountain Config";
unsigned int ConfigSmoothnes, ConfigDetail, ConfigDelay2, ConfigDelay, ConfigQuitAfterOne;
int ActSmoothnes;
Word *movePtr;
long NewTick, OldTick;
char Grid[MaxXRes][MaxYRes];
int XRes, YRes, i;

Word SetupFileNumber;
GrafPortPtr SetupWindow;
RegionHndl Triangle;

long VRam;


void D3(int X,int Y, int *X2, int *Y2)
{
    int Z;
  /*  int OpY;
    OpY=YRes-Y;     */


    Z=Grid[X][Y];
 /*   *X2=(X*10)-X+(OpY<<1)+((X>>1) ? -(OpY) : (OpY))-(YRes>>2);
    *Y2=70+(Y<<2)-(((Z>60?Z:60)*Y)>>7);       */    /* this method does a funky type of perspective */


/*    *X2=(X*6)-(X)+((YRes-Y)<<1)-YRes;
    *Y2=70+(Y<<1)-((Z>60?Z:60)/10); */           /* Let's reduce size for 65*65 rather than 33*33  */

#define Angle   45
#define Width   ((long) (320+Angle+20))
#define Height  180


    *X2=(X*Width/XRes)-(Y*Angle/YRes);
    *Y2=50+(Y*Height/YRes)-((Z>60?Z:60)*3/XRes);    /*Let's attempt scaling!!!!! for variable detail */


 /*   *X2=(X*12)-(X<<1)+((YRes-Y)<<1)-YRes;
    *Y2=70+(Y<<2)-((Z>60?Z:60)/6);     */     /* Old Faithfull */


/*    *X2=(X*10)-X+((YRes-Y)<<1)-YRes;
    *Y2=70+(Y<<2)-((Z>60?Z:60)/6);   */   /* this is what was used in the origonal beta release of mountains */
}

struct getInfoOut T2Info={0,0,0xE};

LongWord BlankT2Mountain(void)
{
    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);
	init_random(toT2Str);
    set_random_seed();
    SetCustomDitherColorPatterns();
    ActSmoothnes=ConfigSmoothnes-2;
    ConfigDelay2=ConfigDelay*120;
    Triangle=NewRgn();
	SetPenMode(modeCopy);
	SetPenSize(1, 1);

  /*  *((char *) 0x00C034)|=0x01;  */  /* change the border color */

    if((*((char *)0x00C035))& 0x08)
        VRam=0xE12000l;
    else
        VRam=0x012000l;
    XRes=3;
    for(i=0; i<ConfigDetail; i++)
        XRes=XRes*2-1;
    YRes=XRes;
	while (!(*movePtr))
  	{
        ClearScreen (0);
        memset(Grid, 0, sizeof (Grid));
        MySetColorTable();
        Plot(0, 0, (random() % 255)+1);
        Plot(XRes-1, 0, (random() % 255)+1);
        Plot(XRes-1, YRes-1, (random() % 255)+1);
        Plot(0, YRes-1, (random() % 255)+1);
        Subdivite(0,0,XRes-1,YRes-1);
        NewTick=OldTick=TickCount();
        if(ConfigDelay>1)
            while( (!(*movePtr)) && (NewTick<OldTick+(long)ConfigDelay2) )
                NewTick=TickCount();
        if(ConfigQuitAfterOne && (T2Info.count_selected_modules > 1))
            break;
	}
    if(*movePtr)
    {
	    return (LongWord) 0;
    } else
	    return (LongWord) bmrNextModule;
}

/*int MyColorTable[]={0x0000,0x0118,0x0AFA,0x09F9,0x08E8,0x07D7,0x06C6,0x05B5,0x04A4,0x0393,0x0282,0x0171,0x0260,0x0350,0x0240, 0x0FFF};*/
/*int MyColorTable[]={0x0000,0x0004,0x0118,0x0474,0x08E8,0x0363,0x06C6,0x0252,0x04A4,0x0141,0x0282,0x0131,0x0260,0x0120,0x0240, 0x0FFF};*/
int MyColorTable[]={0x0000,0x0006,0x0118,0x0AFA,0x09F9,0x08E8,0x07D7,0x06C6,0x05B5,0x04A4,0x0393,0x0282,0x0171,0x0260,0x0350, 0x0FFF};

void MySetColorTable(void)
{
    memcpy((void *)(VRam+0x007E00l), MyColorTable, 32);
}


void Plot(int x3, int y3, int color)
{
    Grid[x3][y3]=(char)color;
}

void DrawTriangle(int x1, int y1, int x2, int y2, int x3, int y3)
{
        OpenRgn();
        MoveTo(x1, y1);
        LineTo(x2, y2);
        LineTo(x3, y3);
        LineTo(x1, y1);
        CloseRgn(Triangle);
        PaintRgn(Triangle);
/*        SetSolidPenPat(0);
        MoveTo(x1, y1);
        LineTo(x2, y2);
        LineTo(x3, y3);
        LineTo(x1, y1);    */
        SetEmptyRgn(Triangle);
}

int PickColor(int Color/*, int MyShade*/)
{
    int n;
    n=Color < 64 ? 0: (Color-64)*77/(256-64);
  /*  n=Color < 64 ? 0: (Color-64)/32+1;    */
  /*  n=Color < 64 ? 1: (Color-64)/14+2;    */

    SetPenPat(&ditherColor[0][n]);
  /*  SetPenPat(&ditherColor[n][MyShade]);*/  /* here we set the dithered color indexed by the shade and color */
  /*  SetSolidPenPat(n);        */
}


void Subdivite(int x1, int y1, int x2, int  y2)
{
    int x,y,color;
    int X3D1, Y3D1;
    int X3D2, Y3D2;
    int X3D3, Y3D3;
    int X3D4, Y3D4;
    int X3D5, Y3D5;

    if (*movePtr)
        return;
    x=(x1+x2)>>1;
    y=(y1+y2)>>1;
    color=(Grid[x1][y1]+Grid[x2][y1]+Grid[x2][y2]+Grid[x1][y2])>>2;
    if(!Grid[x][y])
        Plot(x,y,color);
    if((x2-x1<2) && (y2-y1<2))      /* ibit was not or equil */
    {
        D3(x1, y1, &X3D1, &Y3D1);
        D3(x2, y1, &X3D2, &Y3D2);
        D3(x,  y,  &X3D3, &Y3D3);
        D3(x1, y2, &X3D4, &Y3D4);
        D3(x2, y2, &X3D5, &Y3D5);


        PickColor((Grid[x1][y1]+Grid[x2][y1]+Grid[x][y])/3/*,3*/);
        DrawTriangle(X3D1,Y3D1,X3D2,Y3D2,X3D3,Y3D3);
        PickColor((Grid[x1][y1]+Grid[x1][y2]+Grid[x][y])/3/*,5*/);
        DrawTriangle(X3D1,Y3D1,X3D4,Y3D4,X3D3,Y3D3);
        PickColor((Grid[x2][y1]+Grid[x2][y2]+Grid[x][y])/3/*,7*/);
        DrawTriangle(X3D2,Y3D2,X3D5,Y3D5,X3D3,Y3D3);
        PickColor((Grid[x1][y2]+Grid[x2][y2]+Grid[x][y])/3/*,9*/);
        DrawTriangle(X3D4,Y3D4,X3D5,Y3D5,X3D3,Y3D3);

        return;
    }
    SetColor(x1,y1,x,y1,x2,y1);
    SetColor(x2,y1,x2,y,x2,y2);
    SetColor(x1,y2,x,y2,x2,y2);
    SetColor(x1,y1,x1,y,x1,y2);
    Subdivite(x1,y1,x,y);
    Subdivite(x,y1,x2,y);
    Subdivite(x1,y,x,y2);
    Subdivite(x,y,x2,y2);
}

void SetColor(int xa, int ya, int x, int y, int xb, int yb)
{
    long color;

    if(Grid[x][y])
        return;
    color=abs(xa-xb) + abs(ya-yb);
    if(ActSmoothnes>0)
        color>>=ActSmoothnes;
    if(ActSmoothnes<0)
        color<<=abs(ActSmoothnes);
    if(!color)
        color=1;
    color<<=4; /* ibit changed for 256 mode */
    color=(random() % (color<<1)+1 )-color;
    color+=(Grid[xa][ya]+Grid[xb][yb])>>1;
    if(color<1)
        color=1;
    if(color>255)
        color=255;
    Plot(x,y,(int) color);
}

void SaveT2Mountain(void)
{
	Word FileNumber, OptionWord;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigSmoothnes = GetCtlValue (GetCtlHandleFromID (SetupWindow, SmoothnesPopUp));
	ConfigDetail = GetCtlValue (GetCtlHandleFromID (SetupWindow, DetailPopUp));
	ConfigDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DelayPopUp));
	ConfigQuitAfterOne = GetCtlValue (GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
    OptionWord=(ConfigQuitAfterOne << 15) | (ConfigDelay << 8) | ((ConfigSmoothnes-1) << 4) | ((ConfigDetail-1));
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Mountain(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == DelayPopUp)
		EnableFlag = 1L;
	if (ControlHit == SmoothnesPopUp)
		EnableFlag = 1L;
	if (ControlHit == DetailPopUp)
		EnableFlag = 1L;
	if (ControlHit == QuitAfterOneCB)
		EnableFlag = 1L;
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

LongWord MakeT2Mountain (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Mountain();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigSmoothnes, GetCtlHandleFromID (SetupWindow, SmoothnesPopUp));
	SetCtlValue (ConfigDetail, GetCtlHandleFromID (SetupWindow, DetailPopUp));
	SetCtlValue (ConfigDelay, GetCtlHandleFromID (SetupWindow, DelayPopUp));
	SetCtlValue (ConfigQuitAfterOne, GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
	return 0x05l;
}



void LoadSetupT2Mountain(void)
{
    word OptionWord;

/*  Option word format
**     0x8000 = Quit After One
**     0x7F00 = Delay
**     0X00F0 = Smoothnes
**     0X000F = Detail
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x0F13);
    ConfigQuitAfterOne = (OptionWord & 0x8000) >> 15;
    ConfigDelay = (OptionWord & 0x7F00) >> 8;
    ConfigSmoothnes = ((OptionWord & 0x00F0)>>4)+1;
    ConfigDetail = (OptionWord & 0x000F)+1;
}



LongWord Mountain(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Mountain ();
			break;
 	    case BlankT2:
            if(data2 & bmiBlankNow)
                ConfigQuitAfterOne=0;
            movePtr=(Word *) data1;
 		    Result = BlankT2Mountain ();
			break;
		case SaveT2:
			SaveT2Mountain();
		    break;
		case LoadSetupT2:
			LoadSetupT2Mountain();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Mountain(data2);
			break;
	}
	return Result;
}