/*
**                       DripDrop for T2  by  James C. Smith
*/

#pragma keep "DripDrop"
#pragma cdev DripDrop
#pragma optimize -1
#pragma debug 0

#include "T23.H"
#include "Random3.H"
#include <orca.h>
#include <string.h>
#include <types.h>
#include <memory.h>
#include <locator.h>
#include <loader.h>
#include <control.h>
#include <resources.h>
#include <sound.h>
#include <quickdraw.h>

#pragma lint 0

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


#define ControlList                      0x00001003l

#define IconControl                      0x00000001l
#define NumDropsPopUp                    0x00000002l
#define DropLifePopUp                    0x00000003l
#define SoundCB                          0x00000004l

#define rSoundID                         0x00000001l



LongWord MakeT2DripDrop(void);
void LoadSetupT2DripDrop(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2DripDrop(LongWord);
void SaveT2DripDrop(void);
void LoadSound();
handle LoadASound(unsigned long, word *);
void PlayASound(handle, int, word);


Word SetupFileNumber;
GrafPortPtr SetupWindow;
word OptionWord;
Handle SoundHandle;

int i, i2, OldX,OldY, OldAge, SoundsAreLoaded=0, DisableSounds;
int RectAry[4];
word ConfigNumDrops, ConfigDropLife, ConfigSound;
Word *movePtr;
char *ConfigNameString="\pDripDrop Config";
word DropFreq;

typedef struct rSoundSampleType {
     int SoundFormat;
     int WaveSize;
     int RealPitch;
     int StereoChannel;
     unsigned int SampleRate;
     char StartOfWaveData;
};

typedef struct Drop {
	int     x;
	int     y;
    int     Age;
};

struct startupToolsOut DripDropToolsOut;
word MyID;
word Colors[16];
int BrightColor;
struct Drop Drops[20];

struct SoundParamBlock SoundPB;
struct rSoundSampleType *SoundPtr;
word LastGen, GenNum=0;

void PlayASound(handle SoundHandle, int Channel, word Frequency)
{
    struct rSoundSampleType *SoundPtr;

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
        FFSetUpSound((word) (0<<12 | GenNum<<8 | ffSynthMode), (Pointer) &SoundPB);
        LastGen=GenNum;
        GenNum++;
        if(GenNum>3)
            GenNum=0;
        SoundPB.docBuffer=GenNum<<15;
        SoundPB.volSetting=Channel+96;
        FFStopSound((word) (1<<GenNum));
        FFSetUpSound((word) (1<<12 | GenNum<<8 | ffSynthMode), (Pointer) &SoundPB);
        FFStartPlaying(1<<GenNum | 1<< LastGen);
        GenNum++;
        if(GenNum>3)
            GenNum=0;
    HUnlock(SoundHandle);
}


void CycleColors(void)
{
    word tmp;

    tmp=Colors[15];
    memmove(&Colors[2], &Colors[1], 28);
    Colors[1]=tmp;
	SetColorTable(0, Colors);

    BrightColor++;
    if(BrightColor>15)
        BrightColor=1;
}

LongWord BlankT2DripDrop(void)
{
    int StartSoundTool;


    init_random(toT2Str);
    set_random_seed();

    if(ConfigSound)
    {
	    StartSoundTool = SoundToolStatus();
	    if (!StartSoundTool) {
		    SendRequest(t2StartupTools, stopAfterOne+sendToName, (longword) toT2Str, (((long)MyID)<<16)+startshut_sound,(void *) &DripDropToolsOut);
		    if (DripDropToolsOut.errors)
            {
                ConfigSound=0;
			    return (LongWord) NULL;
            }
	    } else
            ConfigSound=0;
    }


    SetPenMode(modeCopy);
	SetPenSize(2, 1);


    for(i=0; i<16; i++) Colors[i]=(i<<1)%16;
    SetColorTable(0, Colors);
    BrightColor=15;

    for(i=0; i<ConfigNumDrops; i++)
    {
        Drops[i].x=random() % 320;
        Drops[i].y=random() % 200;
        Drops[i].Age=(random()^0x5555) % (ConfigDropLife+8);
    }
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        CycleColors();
        for(i=0; i<ConfigNumDrops; i++)
        {
            OldX=Drops[i].x;
            OldY=Drops[i].y;
            OldAge=Drops[i].Age-6;
            Drops[i].Age++;
            if(Drops[i].Age>=ConfigDropLife+6)
            {
                Drops[i].x=random() % 320;
                Drops[i].y=random() % 200;
                Drops[i].Age=((random()^0x5555) % 3)+1;
                PlayASound(SoundHandle, Drops[i].x, DropFreq);
            }
            i2=Drops[i].Age;
            if(i2<ConfigDropLife)
            {
                RectAry[0]=Drops[i].y-(i2<<1);
                RectAry[1]=Drops[i].x-(i2<<3);
                RectAry[2]=Drops[i].y+(i2<<1);
                RectAry[3]=Drops[i].x+(i2<<3);
                SetSolidPenPat(BrightColor);
                FrameOval((Rect *) RectAry);
            }
            if(OldAge>0)
            {
                RectAry[0]=OldY-(OldAge<<1);
                RectAry[1]=OldX-(OldAge<<3);
                RectAry[2]=OldY+(OldAge<<1);
                RectAry[3]=OldX+(OldAge<<3);
                SetSolidPenPat(0);
                FrameOval((Rect *) RectAry);
            }

        } /* end loop for numprops */

	}  /* end while no movement */
	if (ConfigSound)
    {
        FFStopSound((word) 0x7FFF);
		SendRequest(t2ShutdownTools, stopAfterOne+sendToName, (long) toT2Str,startshut_sound,(long) NULL);
    }
	return (LongWord) NULL;
}

void SaveT2DripDrop(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigSound = GetCtlValue (GetCtlHandleFromID (SetupWindow, SoundCB));
	ConfigNumDrops = GetCtlValue (GetCtlHandleFromID (SetupWindow, NumDropsPopUp));
	ConfigDropLife = GetCtlValue (GetCtlHandleFromID (SetupWindow, DropLifePopUp));
    OptionWord=(ConfigSound<<15) | (ConfigNumDrops<<8) |   ConfigDropLife;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2DripDrop(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == NumDropsPopUp)
		EnableFlag = 1L;
	if (ControlHit == DropLifePopUp)
		EnableFlag = 1L;
	if (ControlHit == SoundCB)
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

LongWord MakeT2DripDrop (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2DripDrop();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigNumDrops, GetCtlHandleFromID (SetupWindow, NumDropsPopUp));
	SetCtlValue (ConfigDropLife, GetCtlHandleFromID (SetupWindow, DropLifePopUp));
	SetCtlValue (ConfigSound, GetCtlHandleFromID (SetupWindow, SoundCB));
	return 4l;
}



void LoadSetupT2DripDrop(void)
{

/*  Option word format
**     0x8000 = Sound
**     0x7F00 = NumDrops
**     0X00FF = DropLength
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x8309);
    ConfigSound=OptionWord >> 15;
    ConfigNumDrops = (OptionWord & 0x7F00) >> 8;
    ConfigDropLife =  OptionWord & 0x00FF;
}

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
    SendRequest(t2CalcFreqOffset, stopAfterOne+sendToName, (longword) toT2Str, (long) (SoundPtr->RealPitch),(void *) &DripDropToolsOut);
    *freqOffset=DripDropToolsOut.errors;
    HUnlock(WorkHandle);
    return WorkHandle;
}

void LoadSound()
{
    word MyResFile, OldResFile;

    if(DisableSounds)
        ConfigSound=0;
    OldResFile=GetCurResourceFile();
    MyResFile=OpenResourceFile(1 /* read only */, NULL, LGetPathname2(MyID, 0x0001));
    if(toolerror())
    {
        ConfigSound=0;
        return;
    }
    SoundHandle=LoadASound(rSoundID, &DropFreq);
    if(!SoundHandle)
    {
        ConfigSound=0;
    } else
        SoundsAreLoaded=1;
    CloseResourceFile(MyResFile);
    SetCurResourceFile(OldResFile);
}

void UnLoadSound(void)
{
    DisposeHandle(SoundHandle);
    SoundsAreLoaded=0;
}

LongWord DripDrop(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;
    MyID=MMStartUp();
	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2DripDrop ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2DripDrop ();
			break;
		case SaveT2:
			SaveT2DripDrop();
		    break;
		case LoadSetupT2:
            DisableSounds=data2 & 1;
			LoadSetupT2DripDrop();
            if(DisableSounds)
                ConfigSound=0;
            if(ConfigSound)
                LoadSound();
            break;
		case UnloadSetupT2:
            if(SoundsAreLoaded)
                UnLoadSound();
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2DripDrop(data2);
			break;
	}
	return Result;
}