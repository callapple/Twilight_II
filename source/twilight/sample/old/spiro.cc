
/*
* "BallBounce" v1.0 - Sample Twilight II Module in Orca/C
*
* v1.0   - 30 May 1993 by James R. Maricondo
*        =
*        =
*/

#pragma keep "ball.d"
#pragma optimize -1
#pragma cdev BallBounce
#include "ball.h"
#pragma lint -1

/* Strings */

char toT2String[]=toT2Str;
char ImageDelayStr[]="\pSpiro:  ImageDelay";
char SmallPenStr[]="\pSpiro:  SmallPen";

/* Prototypes */

	extern int random(void);
	extern void set_random_seed(void);
	extern void init_random(char *);

	LongWord MakeT2Message(void);
	void LoadSetupT2Message(void);
	void SaveConfigResource(char *, word);
	word LoadConfigResource(char *, word);
	LongWord HitT2Message(LongWord);
	LongWord BlankT2Message(void);
	void SaveT2Message(void);

/* Global Variables */

Word *movePtr;
Word ImageDelay;		/* Image delay */
Word SmallPen;		/* Force small pen size? */

Word SetupFileNumber;
GrafPortPtr SetupWindow;

/*------ SPIROGRAPHICS main drawing control routine ------*/

LongWord BlankT2Message (void) {

	extended vertex_angle, rotation_angle;
	unsigned int shapes, sides;
	Word startSane, MyID;
	Long TargetTick;

	struct startupToolsOut spiroToolsOut;
	Ptr	spiroToolsOutP = (Ptr) &spiroToolsOut;

	MyID = MMStartUp();

	startSane = SANEStatus();
	if (!startSane) {
		SendRequest(t2StartupTools, stopAfterOne+sendToName, (long) toT2String,
			(long) (((long) MyID<<16) + startshut_sane),
			(Ptr) spiroToolsOutP);
		if (spiroToolsOut.errors)
			return (LongWord) NULL;
	}

	SetPenMode(modeCopy);
	SetSolidPenPat(-1);
	SetPenSize(1,1);
	init_random(toT2String);

/*
* vertex_angle and rotation_angle can be any number in the range 1 thru 359
* repetitions should be between 10-45
* sides should be between 1-40
* the fewer sides, the fewer repetitions should be executed <- unimplemented
*/

	while (!(*movePtr)) {
		vertex_angle = (int) (random() & 31);   	/*32(cur),<<23>>,25,35,45,60*/
		rotation_angle = (int) (random() % 38);	/*40,50,70,80*/
		shapes = (random() & 31) + 14;			/*31-45(cur),35-45,25-47,30-45,30-50*/
		sides = (random() & 15);				/*16(cur),18,25,40*/

	if (vertex_angle > 23)
		vertex_angle = 0;

/*
* Now the variables have whole numbers.  This is acceptable, but it will
* prevent us from seeing many unique shapes (like a triangle, where
* vertex_angle must be ~ 1.5) that only can be generated with radians with
* decimals.  So give both randomized radian measures decimals, by adding
* a random number between 0 and 1.
*/

		vertex_angle += ((unsigned int) random() / 65534.9);
		rotation_angle += ((unsigned int) random() / 65534.9);

		if (draw_spirographic(vertex_angle, rotation_angle, shapes, sides))
	        break;

		TargetTick = GetTick () + (ImageDelay * 60);
		while ((!(*movePtr)) && (GetTick () < TargetTick));
		if (*movePtr)
			break;

		ClearScreen(0);
	}

	if (!startSane)
		SendRequest(t2ShutdownTools, stopAfterOne+sendToName, (long) toT2String,
			(long) startshut_sane,
			(long) NULL);

/* No error occurred, so return a NULL handle */

	return (LongWord) NULL;
}

/*****************************************************************************\
|* SaveConfigResource-								
|*  This function takes a word value and saves it as a rT2ModuleWord
|*  resource in the Twilight.Setup file.  The value is saved and a		  *|
|*  name is added.  Any previous rT2ModuleWord with the same name is
|*  first removed before the new value is added.
\*****************************************************************************/

void SaveConfigResource (char *Name, Word SaveValue) {

	Word FileID;
	Long ResourceID;
	Word **ConfigData;

/*  Check to see if the named resource already exists */

	ResourceID = RMFindNamedResource (rT2ModuleWord, Name, &FileID);
	if (!toolerror ())
	{
		char NullString = '\x000';

/* The resource already exists, so first remove the name from */
/*	the resource, then remove the resource itself				  */

		RMSetResourceName (rT2ModuleWord, ResourceID, &NullString);
		RemoveResource (rT2ModuleWord, ResourceID);
	}

/* Create new handle for the future resource */

	ConfigData =
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, 0L);
	**ConfigData = SaveValue;

/* Find a new ID for the resource and add it */

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource ((handle) ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle ((handle) ConfigData);
	else
	{

/* Set the name of the resource if it was added correctly */

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
	}
}


/*****************************************************************************\
|* LoadConfigResource-																	  *|
|*  This function attempts to load a named rT2ModuleWord resource.  If  *|
|*  the resource exists, the value of the rT2ModuleWord resource is	  *|
|*  returned, otherwise a default value is returned.						  *|
\*****************************************************************************/

Word LoadConfigResource (char *Name, Word DefaultValue) {

	Word Result, fileID;
	Long rID;
	Handle ConfigData;

/**************************************/
/* Attempt to load the named resource */
/**************************************/

	rID = RMFindNamedResource((Word) rT2ModuleWord, (Ptr) Name, &fileID);

	ConfigData = LoadResource((Word) rT2ModuleWord, rID);
	if (toolerror ())
		Result = DefaultValue; /* Resource does not exist, so return the default value */
	else {
       HLock(ConfigData);  /* Resource exists, return the rT2Module word value */
		Result = **(word **)ConfigData;
		HUnlock(ConfigData);

		ReleaseResource(3, (Word) rT2ModuleWord, rID);
   }

	return Result;
}


/*****************************************************************************\
|*		LoadSetupT2Message-																	  *|
|*			This function loads in the messages configuration data.				  *|
\*****************************************************************************/

void LoadSetupT2Message(void) {

	ImageDelay = LoadConfigResource (ImageDelayStr, 7u);
	SmallPen = LoadConfigResource (SmallPenStr, FALSE);
}


/*****************************************************************************\
|* MakeT2Message-																			  *|
|*  This function creates the controls for the messages setup window	  *|
|*  and sets the value of the controls the the current setup.			  *|
\*****************************************************************************/

LongWord MakeT2Message(void) {

	int i;
	Word FileNumber;

	pointer	*extraInfoH;
	handle df_rez_ctlH;
   handle df_ctlH;

/* Save current resource file and switch in Twilight.Setup */

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/* Make absolutely sure that the messages configuration data is loaded */

	LoadSetupT2Message ();

/* Restore old resource file */

	SetCurResourceFile (FileNumber);

/* Create setup controls and set their states to match current setup */

	NewControl2 (SetupWindow, resourceToResource, MainControlList);

	df_rez_ctlH = LoadResource (rControlTemplate, imageDelayCtl_rID);
	extraInfoH = (pointer *) GetWRefCon( (GrafPortPtr) SetupWindow);
	(long) (*df_rez_ctlH)[14] = (long) *extraInfoH;
   df_ctlH = (handle) NewControl2((WindowPtr) SetupWindow, singlePtr, (long) *df_rez_ctlH);
	ReleaseResource (3, rControlTemplate, imageDelayCtl_rID);
	MakeThisCtlTarget ((CtlRecHndl) df_ctlH);

	CallCtlDefProc ((CtlRecHndl) df_ctlH, (word) SetFieldValue, (((long)ImageDelay<<16)+34ul));
	SetCtlValue (SmallPen, GetCtlHandleFromID (SetupWindow, forceSmallPenCtl));

/* Return the number of the last control */

	return LastCtl;
}


/*****************************************************************************\
|* HitT2Message-			
|*  This function checks to see which control has been hit, and if a
|*  control that requires the "Update" button has been hit, the
|*  EnableFlag is set to true.
\*****************************************************************************/

LongWord HitT2Message (LongWord ControlHit) {

/*	LongWord EnableFlag = 0L;*/

	if ((ControlHit == imageDelayCtl) || (ControlHit == forceSmallPenCtl))
		return 1L;
/*		EnableFlag = 1L;*/
	else
		return 0L;

/* Return the update button enable flag */

/*	return EnableFlag;*/
}


/*****************************************************************************\
|* SaveT2Message-			
|*  This function saves the values of all setup controls.
\*****************************************************************************/

void SaveT2Message (void) {

	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/* Save control values */

	ImageDelay = (unsigned int) CallCtlDefProc (GetCtlHandleFromID (SetupWindow,
                   imageDelayCtl), GetFieldValue, 34ul);

	SaveConfigResource (ImageDelayStr, ImageDelay);
	SmallPen = GetCtlValue (GetCtlHandleFromID (SetupWindow, forceSmallPenCtl));
	SaveConfigResource (SmallPenStr, SmallPen);

/* Restore old resource file */

	SetCurResourceFile (FileNumber);
}

/*****************************************************************************\
|* BallBounce-
|*  This function checks the Twilight II message parameter and			  *|
|*  dispatches control to the appropriate message handler.				  *|
\*****************************************************************************/

LongWord BallBounce (LongWord data2, LongWord data1, Word message) {

	LongWord Result = 1L;

	switch (message)
	{
		case MakeT2:
/* Save pointer to setup window and resource file number of Twilight.Setup */
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
/* Create the setup controls */
			Result = MakeT2Message();
			break;
		case SaveT2:
			SaveT2Message();
			break;
		case BlankT2:
			movePtr=(Word *) data1;
			Result = BlankT2Message();
			break;
		case LoadSetupT2:
			LoadSetupT2Message();
		case UnloadSetupT2:
		case KillT2:
			break;
		case HitT2:
			Result = HitT2Message(data2);
			break;
	}

	return Result;
}