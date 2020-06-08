
/*
* MOIRE!
*
* An all new Twilight II module!  (EXE version.)
* By Jim Maricondo, August 10-13, 1992.  Copyright 1992, All rights reserved.
*
* This is an improved C version of two different moire programs, one
* (following) in BASIC, and one in TML Pascal.
*
10  HGR2 :A = 5
20 X1 =  RND (1) * 279:Y1 =  RND (1) * 191
30 C = C + 1: IF C = 8 THEN C = 0
40  HCOLOR= C:Y = 191
50  FOR X = 0 TO 279 STEP A
60  HPLOT X,191 TO X1,Y1 TO 279 - X,0
70  NEXT X
80  FOR Y = 0 TO 191 STEP A
90  HPLOT 279,191 - Y TO X1,Y1 TO 0,Y
100  NEXT Y
110  FOR I = 1 TO 500: NEXT I
120  IF  PEEK ( - 16384) = 155 THEN  POKE  - 16368,0: TEXT : END
130  GOTO 20
*
* v1.0 - 10-13 August 1992 - JRM:
*      = initial version
* v1.0.1b1 - date unknown - JRM:
*          = updated for new random stuff
* v1.0.1b2 - 23 December 92 - JRM:
*          = updated for new LoadConfigResource proc
*          = cleaned up code a LOT
*
*/

#pragma keep "moire.d"
#pragma optimize -1
#pragma cdev Moire
#include "moire.h"
#pragma lint -1

/* Strings */

char toT2String[]=toT2Str;

/* Resource name strings */

char DrawDelayStr[]="\pMoire:  DrawDelay";
char ColorsStr[]="\pMoire:  Colors";
char ClearScreenStr[]="\pMoire:  ClearScrn";

/* Global Variables */

Word DrawDelay;		/* Drawing delay */
Word Colors;			/* Colors to use */
Word ClearScrn;		/* How often to clear the screen */

Word *movePtr;
Word SetupFileNumber;
GrafPortPtr SetupWindow;

/* Prototypes */

	int moire_effect_a(void);
	int moire_effect_b(void);

	void SaveConfigResource(char *, word);
	word LoadConfigResource(char *, word);

	LongWord MakeT2Moire(void);
	void LoadSetupT2Moire(void);
	LongWord HitT2Moire(LongWord);
	void SaveT2Moire(void);
	LongWord BlankT2Moire(void);

/* Random v3 */

	extern int random(void);
	extern void set_random_seed(void);
	extern void init_random(char *);

/* Routines */

/*------ MOIRE main event loop ------*/

/*****************************************************************************\
|*  BlankT2Moire
|*  This function performs the screen blanking activities.
\*****************************************************************************/

LongWord BlankT2Moire(void) {
	unsigned int r, i, c;
	long TargetTick;
	unsigned char *SrcTbl;
	int CSOverride;

	SetPenMode(modeCopy);
	init_random(toT2String);

	if (Colors == cRandomMItemID)
		Colors = (random() & 7) + 1;	/* get a number from 1 thru 8 */

	if (Colors == cPastelsMItemID)
		SrcTbl = &Pastels_Palette[0];
	else if (Colors == cLandscapeMItemID)
		SrcTbl = &Landscape_Palette[0];
	else if (Colors == cBrightSunMItemID)	
		SrcTbl = &Bright_Sun_Palette[0];
	else if (Colors == cDarkSunMItemID)
		SrcTbl = &Dark_Sun_Palette[0];
	else if (Colors == cBluescaleMItemID)
		SrcTbl = &Bluescale_Palette[0];
	else if (Colors == cGrayscaleMItemID)
		SrcTbl = &Grayscale_Palette[0];
	else if (Colors == cBlueDefaultMItemID)
		SrcTbl = &Blue_Default_Palette[0];

	if (Colors != cDefaultMItemID)
		SetColorTable(0u, SrcTbl);

	if (ClearScrn == csNeverMItemID) {
		CSOverride = TRUE;
		ClearScrn = cs1MoireMItemID;
	}
	else
		CSOverride = FALSE;

	if (DrawDelay == ddNoneMItemID)
		DrawDelay = 0;

	while (!(*movePtr)) {
		if (!(r = (random() & 3))) {		/* r = 0 thru 3 (%00 thru %11) */
			if (!CSOverride)
				ClearScreen(0);
			for (i = 0; i < ClearScrn; i++) {
				if (moire_effect_a())
					goto done;
				TargetTick = GetTick () + (DrawDelay * 60);
				while ((!(*movePtr)) && (GetTick () < TargetTick))
					GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
				if (*movePtr)
					goto done;
			}
		}
		else if (r == 1) {		
			if (!CSOverride)
				ClearScreen(0);
			for (i = 0; i < ClearScrn; i++) {
				if (moire_effect_b())
					goto done;
				TargetTick = GetTick () + (DrawDelay * 60);
				while ((!(*movePtr)) && (GetTick () < TargetTick))
					GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
				if (*movePtr)
					goto done;
			}
		}
		else {								/* r = 2 or r = 3 */
			if (!CSOverride) {
				ClearScreen(0);
				for (i = 0; i < (ClearScrn>>1); i++) {
					if (ClearScrn == cs1MoireMItemID)
						ClearScreen(0);
					if (moire_effect_a())
						goto done;
					TargetTick = GetTick () + (DrawDelay * 60);
					while ((!(*movePtr)) && (GetTick () < TargetTick))
						GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
					if (*movePtr)
						goto done;
					if (ClearScrn == cs1MoireMItemID)
						ClearScreen(0);
					if (moire_effect_b())
						goto done;
					TargetTick = GetTick () + (DrawDelay * 60);
					while ((!(*movePtr)) && (GetTick () < TargetTick))
						GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
					if (*movePtr)
						goto done;
				}
			}
		}
	}
done:

/* No error occurred, so return a NULL handle */

	return (LongWord) NULL;

}

/*------ MOIRE type A moire routine (from BASIC) ------*/

int moire_effect_a(void) {

	unsigned int step;
	unsigned int moire_center_x, moire_center_y;
	unsigned int x, y;

	step = (random() % 19) + 6; 					/* 6 to 25 */
	moire_center_x = (unsigned int) random() % (MAX_X-1);
	moire_center_y = (unsigned int) random() % (MAX_Y-1);
	Set640Color(random() & 0xF);
	y = MAX_Y-1;
	for (x = 0; x < MAX_X; x += step) {
		MoveTo(x, MAX_Y-1);
		LineTo(moire_center_x, moire_center_y);
		LineTo((MAX_X - 1 - x), 0);
		GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
		if (*movePtr)
			return(TRUE);
	}
	for (y = 0; y < MAX_Y; y += step) {
		MoveTo(MAX_X, (MAX_Y - 1 - y));
		LineTo(moire_center_x, moire_center_y);
		LineTo(0, y);
		GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
		if (*movePtr)
			return(TRUE);
	}
	return(FALSE);
}

/*------ MOIRE type B moire routine (from pascal) ------*/

int moire_effect_b(void) {

	int moire_center_x, moire_center_y;
	int x, y, i, i2;

	moire_center_x = (unsigned int) random() % (MAX_X-1);
	moire_center_y = (unsigned int) random() % (MAX_Y-1);
	Set640Color(random() & 0xF);

	for (i = 0; i < 180; i++) {
		MoveTo(moire_center_x, moire_center_y);
		x = SinTable[i];	/* sine i */
		i2 = i - 45;
		if (i2 < 0)
			i2 += 180;
		y = SinTable[i2];	/* cosine i */
		LineTo((x + moire_center_x), (y + moire_center_y));
		GetNextEvent(deskAccEvt+keyDownEvt+autoKeyEvt, &evtRec);
		if (*movePtr)
			return(TRUE);
	}
	return(FALSE);
}

/*****************************************************************************\
|*		SaveConfigResource-																	  *|
|*			This function takes a word value and saves it as a rT2ModuleWord	  *|
|*			resource in the Twilight.Setup file.  The value is saved and a		  *|
|*			name is added.  Any previous rT2ModuleWord with the same name is	  *|
|*			first removed before the new value is added.								  *|
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
	AddResource ((Handle) ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle ((Handle) ConfigData);
	else
	{

/* Set the name of the resource if it was added correctly */

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
	}
}


/*****************************************************************************\
|*		LoadConfigResource-																	  *|
|*			This function attempts to load a named rT2ModuleWord resource.  If  *|
|*			the resource exists, the value of the rT2ModuleWord resource is	  *|
|*			returned, otherwise a default value is returned.						  *|
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
|*  LoadSetupT2Moire-
|*  This function loads in the messages configuration data.
\*****************************************************************************/

void LoadSetupT2Moire(void) {

	DrawDelay = LoadConfigResource (DrawDelayStr, ddNoneMItemID);
	Colors = LoadConfigResource (ColorsStr, cRandomMItemID);
	ClearScrn = LoadConfigResource (ClearScreenStr, cs6MoireMItemID);
}


/*****************************************************************************\
|*  MakeT2Moire-	
|*  This function creates the controls for the messages setup window
|*  and sets the value of the controls the the current setup.
\*****************************************************************************/

LongWord MakeT2Moire(void) {

	int i;
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/* Make absolutely sure that the messages configuration data is loaded */

	LoadSetupT2Moire();

/* Restore old resource file */

	SetCurResourceFile (FileNumber);

/* Create setup controls and set their states to match current setup */

	NewControl2 (SetupWindow, resourceToResource, MainControlList);

	SetCtlValue (DrawDelay, GetCtlHandleFromID (SetupWindow, DrawDelayPopCtl));
	SetCtlValue (Colors, GetCtlHandleFromID (SetupWindow, ColorsPopCtl));
	SetCtlValue (ClearScrn, GetCtlHandleFromID (SetupWindow, ClearScreenPopCtl));

/* Return the number of the last control */

	return IconCtl;
}


/*****************************************************************************\
|* HitT2Moire-																			  *|
|*  This function checks to see which control has been hit, and if a	  *|
|*  control that requires the "Update" button has been hit, the			  *|
|*  EnableFlag is set to true.														  *|
\*****************************************************************************/

LongWord HitT2Moire(LongWord ControlHit) {

	LongWord EnableFlag = 0L;

	if (ControlHit == ClearScreenPopCtl)
		EnableFlag = 1L;
	if (ControlHit == ColorsPopCtl)
		EnableFlag = 1L;
	if (ControlHit == DrawDelayPopCtl)
		EnableFlag = 1L;

/* Return the update button enable flag */

	return EnableFlag;
}


/*****************************************************************************\
|* SaveT2Moire-																			  *|
|*  This function saves the values of all setup controls.					  *|
\*****************************************************************************/

void SaveT2Moire(void) {

	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/* Save control values */

	DrawDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DrawDelayPopCtl));
	SaveConfigResource (DrawDelayStr, DrawDelay);
	Colors = GetCtlValue (GetCtlHandleFromID (SetupWindow, ColorsPopCtl));
	SaveConfigResource (ColorsStr, Colors);
	ClearScrn = GetCtlValue (GetCtlHandleFromID (SetupWindow, ClearScreenPopCtl));
	SaveConfigResource (ClearScreenStr, ClearScrn);

/* Restore old resource file */

	SetCurResourceFile (FileNumber);
}

/*****************************************************************************\
|*		Moire-
|*			This function checks the Twilight II message parameter and			  *|
|*			dispatches control to the appropriate message handler.				  *|
\*****************************************************************************/

LongWord Moire (LongWord data2, LongWord data1, Word message) {

	LongWord Result = 1L;

	switch (message)
	{
		case MakeT2:

/* Save pointer to setup window and resource file number of Twilight.Setup */

			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;

/* Create the setup controls */

			Result = MakeT2Moire();
			break;
		case SaveT2:
			SaveT2Moire();
			break;
		case BlankT2:
			movePtr=(Word *) data1;
			Result = BlankT2Moire();
			break;
		case LoadSetupT2:
			LoadSetupT2Moire();
		case UnloadSetupT2:
		case KillT2:
			break;
		case HitT2:
			Result = HitT2Moire(data2);
			break;
	}

	return Result;
}