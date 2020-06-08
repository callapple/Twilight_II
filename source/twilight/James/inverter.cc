/*
**                       Inverter for T2  by  James C. Smith
*/

#pragma keep "Inverter"
#pragma cdev Inverter
#pragma optimize -1
#pragma debug 0

#include "T23.H"
#include <string.h>
#include <types.h>
#include <control.h>
#include <resources.h>
#include <memory.h>

#pragma lint 0

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


#define InverterIcon                     0x0010DD01l

#define ControlList                      0x00001003l

#define IconControl                      0x00000001l
#define DelayPopup                       0x00000002l
#define ShapePopup                       0x00000003l

#define DelayMenu                        0x00000001l
#define ShapeMenu                        0x00000002l


LongWord MakeT2Inverter(void);
void LoadSetupT2Inverter(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Inverter(LongWord);
void SaveT2Inverter(void);


Word SetupFileNumber;
GrafPortPtr SetupWindow;
word OptionWord;


int i;
word ConfigDelay, ConfigShape;
Long OldTick=0, TmpTick;
Word *movePtr;
word Colors[16];
char *ConfigNameString="\pInverter Config";


void Wait2(int WaitLength)
{
    TmpTick=OldTick;
    while(((OldTick=TickCount())<=TmpTick+WaitLength) && (!(*movePtr)));
}

void SetUp(void)
{
    char tmp2;

    memcpy( Colors, (void *)0xE19E00, 32); /* Colors = color pallet 1 */

    /* make sure all SCBs are set to palet 0 */
    tmp2=((*((char *) 0xE19DC7))) & ((char)0xF0);
    memset( (void *)0xE19D00, tmp2, (size_t) 200);

    /* invert colors in work */
    for(i=0; i<16; i++)
        Colors[i]=
        (0x000F - (Colors[i] & 0x000F)) |
        (0x00F0 - (Colors[i] & 0x00F0)) |
        (0x0F00 - (Colors[i] & 0x0F00));
    memcpy( (void *) (0xE19E00 +32 ), Colors, 32); /* store colors in pallete 1 */

    /* set SCBs according to ConfigShape */
    tmp2=((*((char *) 0xE19DC7))) & ((char)0xF0);

    for(i=0;  i<200; i++)   {
        if(!(i % ConfigShape)) tmp2 ^= 0x01;
        *((char *) (0xE19D00+i))= tmp2;
    }


} /* end setup */


LongWord BlankT2Inverter(void)
{
    SetUp();
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        Wait2(15*ConfigDelay);
        memcpy(Colors, (void *)0xE19E00, 32); /* Colors = pallet 0     */
        memcpy( (void *) 0xE19E00, (void *) (0xE19E00+32), 32); /* copy pallet1 to pallet0 */
        memcpy( (void *) (0xE19E00 + 32), Colors, 32); /* pallet1 = Colors */
	}
	return (LongWord) NULL;
}

void SaveT2Inverter(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigShape = GetCtlValue (GetCtlHandleFromID (SetupWindow, ShapePopup));
	ConfigDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DelayPopup))-1;
    OptionWord=(ConfigShape<<8) |   ConfigDelay;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Inverter(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == ShapePopup)
		EnableFlag = 1L;
	if (ControlHit == DelayPopup)
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

LongWord MakeT2Inverter (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Inverter();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigShape, GetCtlHandleFromID (SetupWindow, ShapePopup));
	SetCtlValue (ConfigDelay+1, GetCtlHandleFromID (SetupWindow, DelayPopup));
	return 0x03l;
}



void LoadSetupT2Inverter(void)
{

/*  Option word format
**     0xFF00 = Shape
**     0X00FF = Delay
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x640C);
    ConfigShape = (OptionWord & 0xFF00) >> 8;
    ConfigDelay = OptionWord & 0x00FF;
}



LongWord Inverter(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 1L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Inverter ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Inverter ();
			break;
		case SaveT2:
			SaveT2Inverter();
		    break;
		case LoadSetupT2:
			LoadSetupT2Inverter();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Inverter(data2);
			break;
	}
	return Result;
}