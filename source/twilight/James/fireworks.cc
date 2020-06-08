/*#define DONT_USE_SOUNDS 1*/  /* define DONT_USE_SOUNDS to disable all the sound
                               ** related code
                               */


/* to do
**
** kill every other
** check for error loading sounds (missing resource OR our of memory)
*/

/*
**                       Fireworks for T2  by  James C. Smith
*/

#pragma keep "Fireworks"
#pragma cdev Fireworks
#pragma optimize -1
#pragma debug 0

#include "T23.H"
#include "Random3.H"
#include "Plot2.h"
#include <memory.h>
#include <string.h>
#include <locator.h>
#include <loader.h>
#include <quickdraw.h>
#include <stdlib.h>
#include <control.h>
#include <resources.h>
#include <sound.h>

#pragma lint 0

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


/* constants */

#define MaxNumSparks   170

#define ControlList                      0x00001003l

#define IconControl                      0x00000001l
#define NumSparks                        0x00000002l
#define BigCB                            0x00000003l

#define ReflectCB                        0x00000004l

#define SoundCB                          0x00000005l


#ifndef DONT_USE_SOUNDS
#define rSoundExplode                    0x00000001l
#define rSoundLaunch                     0x00000002l
#define rSoundWhirl                      0x00000003l
#define rSoundBoom                       0x00000004l

typedef struct rSoundSampleType {
     int SoundFormat;
     int WaveSize;
     int RealPitch;
     int StereoChannel;
     unsigned int SampleRate;
     char StartOfWaveData;
};
#endif
LongWord MakeT2Fireworks(void);
void LoadSetupT2Fireworks(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Fireworks(LongWord);
void SaveT2Fireworks(void);

void (*PlotPointer)(int, int, int);
void Plot(int, int, int);
void Plot2(int, int, int);
void set_pixel2(int, int, int);
void Wait(int);
void Wait2(int);
void New(void);
void Flasher(int,int,int);
void Slow(int, int, int);
void Cycle(void);
#ifndef DONT_USE_SOUNDS
handle LoadASound(unsigned long ResID, word *);
void LoadSounds(void);
void UnLoadSounds(void);
void PlayASound(handle, int, word);
#endif

typedef struct SparkStruct {
    int HistX[14];
    int HistY[14];
    int X;
    int Y;
    int XV;
    int YV;
};

struct startupToolsOut FWToolsOut;
struct SparkStruct Sparks[MaxNumSparks], *SparkPtr;

word MyID;
long x,y,xv,yv;
int IntX=999, IntY, XHist[14], YHist[14], CyclePointer=15, Erase, HistPointer, tmp;
int LaunchColorTable[]={0x000,0x0111,0x0200,0x0300,0x0400,0x0500,0x0600,0x0700,0x0800,0x0900,0x0A00,0x0B00,0x0C00,0x0D00,0x0E00,0x0F00};
/*int LaunchColorTable[]={0x000,0x0111,0x0222,0x0333,0x0444,0x0555,0x0666,0x0777,0x0888,0x0999,0x0AAA,0x0BBB,0x0CCC,0x0DDD,0x0EEE,0x0FFF};*/
int MyColorTable[16], CurNumSparks;
int i, StopIt, EveryOther=0, SoundsAreLoaded=0, DisableSounds;
Long OldTick=0, TmpTick;
Word *movePtr;
char *VRam;
unsigned int *ScreenTablePtr;


char *ConfigNameString="\pFireworks Config";
word ConfigNumSparks, ConfigBig, ConfigSound, ConfigReflect;
#ifndef DONT_USE_SOUNDS
Handle SoundHandleExplode, SoundHandleLaunch, SoundHandleBoom, SoundHandleWhirl;
word ExplodeFreq, LaunchFreq, BoomFreq, WhirlFreq;
struct rSoundSampleType *SoundPtr;
#endif

Word SetupFileNumber;
GrafPortPtr SetupWindow;


signed int SinTable[]={
     0, 2, 4, 6, 8,11,13,15,17,19,21,23,26,28,30,31,33,35,37,
    39,41,42,44,46,47,49,50,51,53,54,55,56,57,58,59,60,60,61,
    62,62,63,63,63,63,63,63,63,63,63,63,63,62,62,61,60,60,59,
    58,57,56,55,54,53,51,50,49,47,46,44,42,41,39,37,35,33,32,
    30,28,26,23,21,19,17,15,13,11, 8, 6, 4, 2, 0,-2,-4,-6,-8,
    -11,-13,-15,-17,-19,-21,-23,-26,-28,-30,-31,-33,-35,-37,-39,-41,-42,-44,-46,
    -47,-49,-50,-51,-53,-54,-55,-56,-57,-58,-59,-60,-60,-61,-62,-62,-63,-63,-63,
    -63,-63,-63,-63,-63,-63,-63,-63,-62,-62,-61,-60,-60,-59,-58,-57,-56,-55,-54,
    -53,-51,-50,-49,-47,-46,-44,-42,-41,-39,-37,-35,-33,-32,-30,-28,-26,-23,-21,
    -19,-17,-15,-13,-11,-8,-6,-4,-2};

#ifndef DONT_USE_SOUNDS
word LastGen, GenNum=0;
struct SoundParamBlock SoundPB;

void PlayASound(handle SoundHandle, int Channel, word Frequency)
{
    if(ConfigSound==0 || SoundsAreLoaded==0)
        return;

    HLock(SoundHandle);
    SoundPtr=(void *) *SoundHandle;

    Channel=Channel > 160 ? 1 : 0;
    SoundPB.waveStart=&SoundPtr->StartOfWaveData;
    SoundPB.waveSize=SoundPtr->WaveSize;
    SoundPB.freqOffset=Frequency;
    SoundPB.docBuffer=GenNum<<15;
    SoundPB.bufferSize=0x6;
    SoundPB.nextWavePtr=NULL;
    SoundPB.volSetting=255;
    FFStopSound((word) (1<<GenNum));
    FFStartSound((word) (Channel<<12 | GenNum<<8 | ffSynthMode), (Pointer) &SoundPB);
    GenNum++;
    if(GenNum>3)
        GenNum=0;
    HUnlock(SoundHandle);
}

/*
void PlayASound(handle SoundHandle, int Channel, word Frequency)
{
    if(ConfigSound==0 || SoundsAreLoaded==0)
        return;

    Channel>>=1;
    HLock(SoundHandle);
    SoundPtr=(void *) *SoundHandle;

    SoundPB.waveStart=&SoundPtr->StartOfWaveData;
    SoundPB.waveSize=SoundPtr->WaveSize;
    SoundPB.freqOffset=Frequency;
        SoundPB.docBuffer=GenNum<<15;
        SoundPB.bufferSize=0x6;
        SoundPB.nextWavePtr=NULL;
        SoundPB.volSetting=159-Channel+96;
        FFStopSound((word) (1<<GenNum));
        FFSetUpSound((word) (0<<12 | GenNum<<8 | ffSynthMode), &SoundPB);
        LastGen=GenNum;
        GenNum++;
        if(GenNum>3)
            GenNum=0;
        SoundPB.docBuffer=GenNum<<15;
        SoundPB.volSetting=Channel+96;
        FFStopSound((word) (1<<GenNum));
        FFSetUpSound((word) (1<<12 | GenNum<<8 | ffSynthMode), &SoundPB);
        FFStartPlaying(1<<GenNum | 1<< LastGen);
        GenNum++;
        if(GenNum>3)
            GenNum=0;
    HUnlock(SoundHandle);
} */

handle LoadASound(unsigned long ResID, word *freqOffset)
{
    handle WorkHandle;

    WorkHandle=LoadResource(rSoundSample, ResID);
    if(toolerror())
        return 0;
    DetachResource(rSoundSample, ResID);
    SetHandleID(MyID, WorkHandle);
    HLock(WorkHandle);
    SoundPtr=(void *) *WorkHandle;
    SendRequest(t2CalcFreqOffset, stopAfterOne+sendToName, (longword) toT2Str, (long) (SoundPtr->RealPitch),(void *) &FWToolsOut);
    *freqOffset=FWToolsOut.errors;
    HUnlock(WorkHandle);
    return WorkHandle;
}

void LoadSounds(void)
{
    word MyResFile, OldResFile;
    int NumSoundsLoaded;

    OldResFile=GetCurResourceFile();
    MyResFile=OpenResourceFile(1 /* read only */, NULL, LGetPathname2(MyID, 0x0001));
    SoundsAreLoaded=1;

    SoundHandleExplode=LoadASound(rSoundExplode, &ExplodeFreq);
    if(SoundHandleExplode)
    {
        SoundHandleWhirl=  LoadASound(rSoundWhirl, &WhirlFreq);
        if(SoundHandleWhirl)
        {
            SoundHandleBoom=   LoadASound(rSoundBoom, &BoomFreq);
            if(SoundHandleBoom)
            {
                SoundHandleLaunch= LoadASound(rSoundLaunch, &LaunchFreq);
                if(SoundHandleLaunch);
                else {
                    DisposeHandle(SoundHandleExplode);
                    DisposeHandle(SoundHandleWhirl);
                    DisposeHandle(SoundHandleBoom);
                    SoundsAreLoaded=0;
                }
            } else {
                DisposeHandle(SoundHandleExplode);
                DisposeHandle(SoundHandleWhirl);
                SoundsAreLoaded=0;
            }
        } else {
            DisposeHandle(SoundHandleExplode);
            SoundsAreLoaded=0;
        }
    } else {
        SoundsAreLoaded=0;
    }

    if(!SoundsAreLoaded)
        ConfigSound=0;
    CloseResourceFile(MyResFile);
    SetCurResourceFile(OldResFile);
}

void UnLoadSounds(void)
{
    if(SoundsAreLoaded)
    {
        DisposeHandle(SoundHandleExplode);
        DisposeHandle(SoundHandleLaunch);
        DisposeHandle(SoundHandleBoom);
        DisposeHandle(SoundHandleWhirl);
        SoundsAreLoaded=0;
    }
}

#endif

void Wait2(int WaitLength)
{
    TmpTick=OldTick;
    while(((OldTick=TickCount())<=TmpTick+WaitLength) && (!(*movePtr)));
}

void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while((OldTick=TickCount())<=TmpTick+WaitLength);
}

void Plot2(int x, int y, int color)
{
    Plot(x, y, color);
    Plot(320-x, 200-y, color);
}

void set_pixel2(int x, int y, int color)
{
    set_pixel(x, y, color);
    set_pixel(320-x, 200-y, color);
}


void Plot(int x, int y, int color)
{
    char *PP;

        if(x<0 || y<0 || x>318 || y>198)
            return;
        PP=VRam + *(ScreenTablePtr+y) + (x>>1);
        if(x & 0x01)       {
            *PP=(*PP & 0xF0) | color;
            *(PP+1)=(*(PP+1) & 0x0F) | (color<<4);
            *(PP+160)=(*(PP+160) & 0xF0) | color;
            *(PP+161)=(*(PP+161) & 0x0F) | (color<<4);
        }else {
            *PP=(color<<4)|color;
            *(PP+160)=(color<<4)|color;
        }
}


/*void Plot(int x, int y, int color)
{
    char *PP;

    if(x<0 || y<0 || x>318 || y>198)
        return;
    PP=VRam + *(ScreenTablePtr+y) + (x>>1);
    if(ConfigBig)  {
        if(x & 0x01)       {
            *PP=(*PP & 0xF0) | color;
            *(PP+1)=(*(PP+1) & 0x0F) | (color<<4);
            *(PP+160)=(*(PP+160) & 0xF0) | color;
            *(PP+161)=(*(PP+161) & 0x0F) | (color<<4);
        }else {
            *PP=(color<<4)|color;
            *(PP+160)=(color<<4)|color;
        }
    } else {
    if(x & 0x01)
        *PP=(*PP & 0xF0) | color;
    else
        *PP=(*PP & 0x0F) | (color<<4);
    }
} */

int Spark;

int Angle;
signed int Z;

void Slow(int Wiggle, int Glitter, int BallSize)
{
    int C1, C2, C3, FadingI, SmallBallSize;

    SmallBallSize=BallSize-14;
    do{
        C1=random() % 15;
        C2=random() % 15;
        C3=random() % 15;
    } while (C1+C2+C3 < 20);
    MyColorTable[1]=(C1*20)/100<<8 | (C2*20)/100<<4 | (C3*20)/100;
	for(i=15; i>1; i--) {
		MyColorTable[i]=C1<<8 | C2<<4 | C3;
        if(C1) C1--;
        if(C2) C2--;
        if(C3) C3--;
    }
    SetColorTable(0, MyColorTable);
	CyclePointer=15;
    HistPointer=0;
#ifndef DONT_USE_SOUNDS
    if(Wiggle)
        PlayASound(SoundHandleWhirl, IntX, WhirlFreq);
    else
        PlayASound(SoundHandleExplode, IntX, ExplodeFreq);
#endif
    /* Initialize the table of sparks with randm directions */
    for(Spark=0; Spark<CurNumSparks; Spark++){
        SparkPtr=&Sparks[Spark];
        Angle=random()%180;
        Z=SinTable[random()%180];
        if(Z<0)
            Z=(-Z);
        SparkPtr->YV=(SinTable[Angle]*Z)/64;
        Angle-=45;
        if(Angle<0)
            Angle+=180;
        SparkPtr->XV=(SinTable[Angle]*Z)/64;
        SparkPtr->X=IntX<<6;
        SparkPtr->Y=IntY<<6;
        SparkPtr->HistX[HistPointer]=IntX;
        SparkPtr->HistY[HistPointer]=IntY;
    }
    for(i=0; i<BallSize; i++){
        if(*movePtr)
            return;
        HistPointer++;
        if(HistPointer>13)
            HistPointer=0;

        /* erase old sparks is this is the 14th cycle through */
        if(i>13) for(Spark=0; Spark<CurNumSparks; Spark++){
            SparkPtr=&Sparks[Spark];
            if((!Glitter) || (random()%40))
                (*PlotPointer)(SparkPtr->HistX[HistPointer], SparkPtr->HistY[HistPointer], 1);
        } /* end for spark erase*/
       	Cycle();
        if (i<SmallBallSize) for(Spark=0; Spark<CurNumSparks; Spark++){
            SparkPtr=&Sparks[Spark];
            if(SparkPtr->YV< 64 /*(1<<6)*/  )
                SparkPtr->YV++;       /* spark gravity */
            SparkPtr->X+=SparkPtr->XV;
            SparkPtr->Y+=SparkPtr->YV;
            if(Wiggle && i>15) {
                tmp=((i+(Spark<<3))<<3)%180;  /* \/ wiggle \/ */
                SparkPtr->Y+=Spark % 2?(SinTable[tmp]/2):(-(SinTable[tmp]/2));
                tmp-=45;
                if(tmp<0)
                    tmp+=180;
                SparkPtr->X+=SinTable[tmp]; /* /\ wiggle /\ */
            }
            (*PlotPointer)(SparkPtr->HistX[HistPointer]=SparkPtr->X>>6, SparkPtr->HistY[HistPointer]=SparkPtr->Y>>6, CyclePointer);
        } /* end for spark draw new*/
    } /* end for 130 frames in explosion */
    if(Glitter) {
        MyColorTable[1]=0x0111;
        SetColorTable(0, MyColorTable);
        for(i=20; i && (!(*movePtr)); i--){
            Cycle();
            Wait2(2);
        }
    } /* end if glitter */
    if((!Glitter) && (!Wiggle) && ((random() & 42)==42)) {
        for(Spark=0; Spark<CurNumSparks; Spark+=4){
            IntX=Sparks[Spark].X>>6;
            IntY=Sparks[Spark].Y>>6;
            Flasher(3,3,1);
        } /* end for spark flash */
    } /* end if flash all sparks */
} /* end Slow explosion type */

void Cycle(void)
{
    tmp=MyColorTable[15];
    memmove(&MyColorTable[3], &MyColorTable[2], 26);
    MyColorTable[2]=tmp;
    SetColorTable(0, MyColorTable);
    CyclePointer++;
    if(CyclePointer>15)
        CyclePointer=2;
}


int RectAry[4];
int RectAry2[4];

void Flasher(int XSize, int YSize, int LesDelay)
{
#ifndef DONT_USE_SOUNDS
    PlayASound(SoundHandleBoom, IntX, BoomFreq);
#endif
    RectAry[0]=IntY-YSize;
    RectAry[2]=IntY+YSize;
    RectAry[1]=IntX-XSize;
    RectAry[3]=IntX+XSize;
    RectAry2[0]=(200-IntY)-YSize;
    RectAry2[2]=(200-IntY)+YSize;
    RectAry2[1]=(320-IntX)-XSize;
    RectAry2[3]=(320-IntX)+XSize;
    tmp=MyColorTable[15];
    MyColorTable[15]=0x0FFF;
    SetColorTable(0, MyColorTable);
    SetSolidPenPat(15);
    Wait(LesDelay?1:2);
    PaintOval((Rect *) RectAry);
    if(ConfigReflect)
        PaintOval((Rect *) RectAry2);
    MyColorTable[0]=0x0DDD;
    MyColorTable[1]=0x0FFF;
    Wait(LesDelay?0:1);
  /*  *((char *)0x00C034)&=0xF0; */ /* make sure boarder is blank */
  /*  *((char *)0x00C034)|=0x0A; */ /* set boarder color to light grey */
    SetColorTable(0, MyColorTable);
    SetSolidPenPat(1);
    PaintOval((Rect *)RectAry);
    if(ConfigReflect)
        PaintOval((Rect *) RectAry2);
    MyColorTable[0]=0x0000;
    MyColorTable[1]=0x0111;
    MyColorTable[15]=tmp;
    Wait(LesDelay?1:2);
    SetColorTable(0, MyColorTable);
  /*  *((char *)0x00C034)&=0xF0;*/ /* set boarder color to blank */
}

void New(void)
{
	CyclePointer=15;
	memcpy(MyColorTable, LaunchColorTable, 32);
    SetColorTable(0, MyColorTable);
    x=((long) (random() % 160))<<16;
    y=199<<16;
    xv=(random() % 128)<<8;
    if(x>(80<<16)){
        x+=160<<16;
        xv=(-xv);
    }
    IntX=x>>16;
    IntY=y>>16;
    yv=-281<<8;
    yv+=(random()%819)<<4;
    HistPointer=0;
    Erase=0;
    StopIt=0;

    RectAry[0]=IntY-5;
    RectAry[2]=IntY+5;
    RectAry[1]=IntX-6;
    RectAry[3]=IntX+6;
    SetSolidPenPat(CyclePointer);
    PaintOval((Rect *)RectAry);
    if(ConfigReflect)
    {
        RectAry2[0]=(200-IntY)-5;
        RectAry2[2]=(200-IntY)+5;
        RectAry2[1]=(320-IntX)-6;
        RectAry2[3]=(320-IntX)+6;
        PaintOval((Rect *)RectAry2);
    }
#ifndef DONT_USE_SOUNDS
    PlayASound(SoundHandleLaunch, IntX, LaunchFreq);
#endif
}

LongWord BlankT2Fireworks(void)
{
    int StartSoundTool;

#ifndef DONT_USE_SOUNDS
    if(ConfigSound)
    {
	    StartSoundTool = SoundToolStatus();
	    if (!StartSoundTool) {
		    SendRequest(t2StartupTools, stopAfterOne+sendToName, (longword) toT2Str, (((long)MyID)<<16)+startshut_sound,(void *) &FWToolsOut);
		    if (FWToolsOut.errors)
            {
                ConfigSound=0;
			    return (LongWord) NULL;
            }
	    } else
            ConfigSound=0;
    }
#endif

    ClearScreen (0);
    if((*((char *)0x00C035))& 0x08)
        VRam=(char *) 0xE10000l;
    else
        VRam=(char *) 0x010000l;
    ScreenTablePtr=(void *) GetAddress(0x0001);
	init_plot((char *) VRam,(char *) ScreenTablePtr, toT2Str);
    if(ConfigReflect)
    {
        if(ConfigBig)
            PlotPointer=Plot2;
        else
            PlotPointer=set_pixel2;
    } else {
        if(ConfigBig)
            PlotPointer=Plot;
        else
            PlotPointer=set_pixel;
    }

    SetColorTable (0, MyColorTable);
    init_random(toT2Str);
    set_random_seed();
    New();
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
    if(Erase)
        (*PlotPointer)(XHist[HistPointer], YHist[HistPointer], 1);
    Cycle();
    if(StopIt){
        StopIt++;
        if(StopIt>15){
        	switch((random()^0x5555)%4){
           		case 0: Flasher(8,7,0);  /* flasher */
		        		break;
            	case 1: CurNumSparks=(ConfigNumSparks+1)*10;  /* normal */
                        Slow(0,0,85);
	            		break;
            	case 2: CurNumSparks=((ConfigNumSparks+1)*10)/3; /* wiggle */
                        Slow(1,0,115);
	            		break;
            	case 3: CurNumSparks=(ConfigNumSparks+1)*10;  /* glitter */
                        Slow(0,1,85);
	            		break;
			} /* end switch effect type */
            memset(&MyColorTable[1], 0x0111, 30);
            SetColorTable(0, MyColorTable);
            Wait2(20 + (random() % 30));
  			ClearScreen (0);
            New();
        }
    }
    else
        (*PlotPointer)(IntX, IntY, CyclePointer);
    XHist[HistPointer]=IntX;
    YHist[HistPointer]=IntY;
    HistPointer++;
    if(HistPointer>13){
        HistPointer=0;
        if(!Erase){
            SetSolidPenPat(0);
            PaintOval((Rect *)RectAry);
            if(ConfigReflect)
                PaintOval((Rect *)RectAry2);
            Erase=1;
        }
    }
    if(!EveryOther){
        TmpTick=OldTick;
        while((OldTick=TickCount())==TmpTick);
        EveryOther=4;
    } else
        EveryOther--;
    x+=xv;
    y+=yv;
    IntX=x>>16;
    IntY=y>>16;
    yv+=203; /* "gravity" */
    if(yv>(51<<8) && (!StopIt))
        StopIt=1;
	}
    ClearScreen (0);
#ifndef DONT_USE_SOUNDS
	if (ConfigSound)
    {
        FFStopSound((word) 0x7FFF);
		SendRequest(t2ShutdownTools, stopAfterOne+sendToName, (long) toT2Str,startshut_sound,(long) NULL);
    }
#endif
	return (LongWord) NULL;
}

void SaveT2Fireworks(void)
{
    word OptionWord;
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigReflect = GetCtlValue (GetCtlHandleFromID (SetupWindow, ReflectCB));
	ConfigNumSparks = GetCtlValue (GetCtlHandleFromID (SetupWindow, NumSparks))-1;
	ConfigBig = GetCtlValue (GetCtlHandleFromID (SetupWindow, BigCB));
#ifndef DONT_USE_SOUNDS
	ConfigSound = GetCtlValue (GetCtlHandleFromID (SetupWindow, SoundCB));
#endif
    OptionWord=(ConfigReflect << 6) | (ConfigSound << 5) | (ConfigBig << 4) | ConfigNumSparks;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Fireworks(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == ReflectCB)
		EnableFlag = 1L;
	if (ControlHit == NumSparks)
		EnableFlag = 1L;
	if (ControlHit == BigCB)
		EnableFlag = 1L;
#ifndef DONT_USE_SOUNDS
	if (ControlHit == SoundCB)
		EnableFlag = 1L;
#endif

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
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, 0L);
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

LongWord MakeT2Fireworks (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Fireworks();
	SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
#ifndef DONT_USE_SOUNDS
	SetCtlValue (ConfigSound, GetCtlHandleFromID (SetupWindow, SoundCB));
#endif
	SetCtlValue (ConfigReflect, GetCtlHandleFromID (SetupWindow, ReflectCB));
	SetCtlValue (ConfigNumSparks+1, GetCtlHandleFromID (SetupWindow, NumSparks));
	SetCtlValue (ConfigBig, GetCtlHandleFromID (SetupWindow, BigCB));
#ifndef DONT_USE_SOUNDS
	return 5l;
#else
    return 4l;
#endif
}

void LoadSetupT2Fireworks(void)
{
    word OptionWord;

/*  Option word format
**     0x0040 = Reflect
**     0x0020 = Sound
**     0x0010 = Big
**     0x000F = NumSparks
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x00026);
    ConfigReflect = (OptionWord & 0x0040) >> 6;
    ConfigSound = (OptionWord & 0x0020) >> 5;
    ConfigBig = (OptionWord & 0x0010) >> 4;
    ConfigNumSparks = OptionWord & 0x000F;
}


LongWord Fireworks(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

    MyID=MMStartUp();
	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Fireworks ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Fireworks ();
			break;
		case SaveT2:
			SaveT2Fireworks();
		    break;
		case LoadSetupT2:
            DisableSounds=data2 & 1;
			LoadSetupT2Fireworks();
#ifndef DONT_USE_SOUNDS
            if(DisableSounds)
                ConfigSound=0;
            if(ConfigSound)
                LoadSounds();
#endif
            break;
		case UnloadSetupT2:
#ifndef DONT_USE_SOUNDS
            UnLoadSounds();
#endif
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Fireworks(data2);
			break;
	}
	return Result;
}