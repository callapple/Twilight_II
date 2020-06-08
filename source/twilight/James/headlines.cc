/*
**                       Headlines for T2  by  James C. Smith
*/

/*     File Format
**
**     First 50 bytes = File ID and file format version
**     array of key word records
**          key word record = 2 byte count of number of substitution strings
**                                 there are for this key word.
**                            2 byte pointer to text substitution array for this
**                                 key word
**          text substitution array = an array of 2 byte pointer to substitution
**                                 strings.
**          substitution strin = a \n terminated string.  An 0xFF character in
**                                 the string flags a key word in the string
**                                 and is fallowed by a one byte key word number.
**                                 This number is offset by 32 so that key word
**                                 number 10 is not taken for a \n teminating
**                                 the string.  The key word number - 32 = the
**                                 position of the key word in the key word
**                                 record array.
**
**
*/

#pragma keep "Headlines"
#pragma cdev Headlines
#pragma optimize -1
#pragma debug 0

#include "T2f.H"
#include "Random3.h"

#include <stdio.h>
#include <string.h>

#include <memory.h>
#include <lineedit.h>
#include <loader.h>
#include <misctool.h>
#include <quickdraw.h>
#include <font.h>
#include <string.h>
#include <stdlib.h>
#include <control.h>
#include <resources.h>
#include <locator.h>

pascal LongWord TickCount() inline(0x1006,dispatcher);

extern int random(void);
extern void set_random_seed(void);

LongWord MakeT2Headlines(void);
void LoadSetupT2Headlines(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Headlines(LongWord);
void SaveT2Headlines(void);


#define HeadlinesIcon                    0x0010DD01l
#define ControlList                      0x00001003l
#define IconControl                      0x00000001l
#define SetFont                          0x00000002l
#define DelayPU                          0x00000003l
#define QuitAfterOneCB                    0x00000004l

#define MyStackSize    512

typedef unsigned int FileAddress;

void DeRef(int);
void Wait(int);

char OutString[256];
int OutStringLen=0, TempInt;
FileAddress TempFileAddress;
int x,y;
word MyID;
FILE *HeadlinesFile;
char FileName[128], *FileNamePtr;
char MyStack[MyStackSize];
int MyStackPointer;

char *ConfigNameStringNumber="\pHeadlines Config Font";
char *ConfigNameStringSize="\pHeadlines Config Size";
char *ConfigNameString="\pHeadlines Configuration";
LongWord ConfigFontID;
int ConfigDelay, ConfigQuitAfterOne;
int RealDelay;

Word SetupFileNumber;
GrafPortPtr SetupWindow;


ColorTable DefColorTable={0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF};
ColorTable BlackColorTable={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
Long OldTick=0, TmpTick;
Word *movePtr;
int MyRect[]={5,5,195,635};
struct getInfoOut T2Info={0,0,0xE};

LongWord BlankT2Headlines(void)
{

	init_random(toT2Str);
	set_random_seed();
    SetRandSeed(random());
    FileNamePtr=LGetPathname(MyID, 0x0001);
    memcpy(FileName, FileNamePtr+1, FileNamePtr[0]);
    strcpy(&FileName[FileNamePtr[0]], ".Data");
    HeadlinesFile=fopen(FileName, "rb");
    if(HeadlinesFile==0)
        return (longword) "Error opening the Headlines.Data file!\x0DMake sure it is in the same folder as Headlins.";
    fgets(FileName, sizeof FileName, HeadlinesFile);
    if(strcmp("Headlines data file version 1.00\n", FileName))
    {
        fclose(HeadlinesFile);
        return (longword) "The Headlines.Data file does not contain valid Headlines\rdata or is made for a different version of Headlines.";
    }
    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);
    Wait(0);
    InstallFont(ConfigFontID, 0x0000); /* select configed font */
    SetBackColor(0);
    SetForeColor(1);
    SetSolidBackPat(0);
    RealDelay=ConfigDelay * 60;
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        MyStackPointer=0;
        OutStringLen=0;
        DeRef(0);
        OutString[OutStringLen]=0;

        ClearScreen (0);
        SetColorTable (0, BlackColorTable);
        LETextBox2(OutString, OutStringLen, (Rect *)MyRect, 1);
        SetColorTable (0, DefColorTable);
        Wait(RealDelay);
        if(ConfigQuitAfterOne && (T2Info.count_selected_modules > 1))
            break;
	}
    fclose(HeadlinesFile);
    SetPurgeStat(ConfigFontID, (word) purgeBit);
    if(*movePtr)
    {
	    return (LongWord) 0;
    } else
	    return (LongWord) bmrNextModule;
}

void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while(((OldTick=TickCount())<=TmpTick+WaitLength) && (!(*movePtr)));
}

void SaveT2Headlines(void)
{
    Word OptionWord;
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DelayPU));
	ConfigQuitAfterOne = GetCtlValue (GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
    OptionWord=(ConfigQuitAfterOne<<15)|ConfigDelay;
	SaveConfigResource(ConfigNameString, OptionWord);
	SaveConfigResource(ConfigNameStringNumber, ConfigFontID & 0x0000FFFF);
	SaveConfigResource(ConfigNameStringSize, ConfigFontID >> 16);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Headlines(LongWord ControlHit)
{
    LongWord OldConfigFontID;
	LongWord EnableFlag = 0L;
    GrafPort MyPort,*OldPort;


	if (ControlHit == DelayPU)
        EnableFlag = 1L;
	if (ControlHit == QuitAfterOneCB)
        EnableFlag = 1L;
	if (ControlHit == SetFont){
        OldConfigFontID=ConfigFontID;
        OldPort = GetPort ();                 /* Save grafport for future restore */
        OpenPort (&MyPort);             /* Create a new port                */
        ConfigFontID=ChooseFont((long) ConfigFontID, (word) 0);
        SetPort (OldPort);
        ClosePort (&MyPort);         /* Restore grafport and kill ours      */
        if(ConfigFontID==0)
            ConfigFontID=OldConfigFontID;
		else
            if(OldConfigFontID != ConfigFontID) EnableFlag = 1L;
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

LongWord MakeT2Headlines (void)
{
    CtlRecHndl junk;
	Word FileNumber;


	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Headlines();
	SetCurResourceFile (FileNumber);


	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigDelay, GetCtlHandleFromID (SetupWindow, DelayPU));
	SetCtlValue (ConfigQuitAfterOne, GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
	return 4l;
}


void LoadSetupT2Headlines(void)
{
    word OptionWord;

/*  Option word format
**     0x8000 = Quit After One
**     0x00FF = Delay between Headlines
*/

	ConfigFontID = (((LongWord) LoadConfigResource (ConfigNameStringSize, 0x1801)) <<16 ) | ((LongWord) LoadConfigResource (ConfigNameStringNumber, times));
	OptionWord = LoadConfigResource (ConfigNameString, 15);
    ConfigQuitAfterOne=(OptionWord & 0x8000)>>15;
    ConfigDelay=OptionWord & 0x00FF;
}


LongWord Headlines(LongWord data2, LongWord data1, Word message)
{
    Handle  TempHandle;
	LongWord Result = 0L;

    MyID=MMStartUp();
	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Headlines ();
			break;
 	    case BlankT2:
            if(data2 & bmiBlankNow)
                ConfigQuitAfterOne=0;
            movePtr=(Word *) data1;
 		    Result = BlankT2Headlines ();
            if(Result & 0x00FFFFFFul)
            {
                TempHandle=NewHandle( (long) (strlen((char *) Result)+1), MyID, attrLocked | attrFixed | attrNoCross | attrNoSpec, NULL);
                strcpy(*TempHandle, (char *) Result);
                Result=(long) TempHandle;
            }
			break;
		case SaveT2:
			SaveT2Headlines();
		    break;
		case LoadSetupT2:
			LoadSetupT2Headlines();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
 	        break;
		case HitT2:
			Result = HitT2Headlines(data2);
			break;
	}
	return Result;
}

void DeRef(int KeyWordNumber)
{
    int SubNumber/*, LocationInWork*/;
    int OrigonalStackPointer;
    char *LocalStackPointer;

    OrigonalStackPointer=MyStackPointer;
    fseek(HeadlinesFile, 50 + KeyWordNumber *(2 + (sizeof (FileAddress))), SEEK_SET);
    fread(&TempInt, sizeof (int), 1, HeadlinesFile);  /* read number of substitutions for this key word */
    fread(&TempFileAddress, sizeof (FileAddress), 1, HeadlinesFile); /* read starting location of list of substitutions */
    SubNumber=(random()+Random()) % TempInt;
    fseek(HeadlinesFile, TempFileAddress+(SubNumber * (sizeof (FileAddress))), SEEK_SET);
    fread(&TempFileAddress, sizeof (FileAddress), 1, HeadlinesFile); /* read starting location of substitution text */
    fseek(HeadlinesFile, TempFileAddress, SEEK_SET);
    LocalStackPointer=fgets(&MyStack[MyStackPointer], MyStackSize-MyStackPointer, HeadlinesFile);
    MyStackPointer+=1+strlen(LocalStackPointer);


    for(; *LocalStackPointer; LocalStackPointer++)
    {
        switch (*LocalStackPointer)
        {
        case 0xFF:
            DeRef(*(++LocalStackPointer)-32);
            break;
        case '\n':
            break;
        case 0x5C:
            OutString[OutStringLen++]=0x0D;
            break;
        case '|':
            OutString[OutStringLen++]=0x27;
            break;
         default:
            OutString[OutStringLen++]=*LocalStackPointer;
            break;
        }
    }
    MyStackPointer=OrigonalStackPointer;
}