
/*
* SPIROGRAPHICS!
*
* An all new Twilight II module!  (G2MF version.)
* By Jim Maricondo, August 10-11, 1992.  Copyright 1992, All rights reserved.
*
* implement: varying scales?
*
* This is an improved C version of the following BASIC program:
*
PI = 3.14159
C =  COS (PI / 3) : S =  SIN (PI / 3)
C1 =  COS (PI / 36) : S1 =  SIN (PI / 36)
SF = .95 : X = 95 : Y = 0 : CX = 140 : CY = 96 : SC = 1.16 : HGR2 : HCOLOR= 3
FOR J = 1 TO 40
FOR I = 0 TO 6
SX = X * SC + CX : SY = CY + Y
IF I = 0 THEN  HPLOT SX,SY
HPLOT  TO SX,SY
XN = X * C - Y * S : Y = X * S + Y * C : X = XN : NEXT I
XN = SF * (X * C1 - Y * S1) : Y = SF * (X * S1 + Y * C1) : X = XN : NEXT J
*
* v1.0a1 - 10-11 August 1992 - JRM:
*      = initial version
*      - 27 September 1992 - JRM
*      - 1, 6 October 1992 - JRM
*      - 30 November 1992 - JRM:
*      = new random routines used
* v1.0a2 - 23 December 92 - JRM:
*        = updated for new LoadConfigResource proc
*        = cleaned up code a LOT
* v1.0b1 - 23 December 92 - JRM:
*        = repositioned setup controls (yech)
*        = the options now work!  (before they were ignored)
*
*/

#pragma keep "spiro.d"
#pragma optimize -1
#pragma cdev Spirographics
#include "spiro.h"
#pragma lint -1

/* Strings */

char toT2String[]=toT2Str;
char ImageDelayStr[]="\pSpiro:  ImageDelay";
char SmallPenStr[]="\pSpiro:  SmallPen";

/* Prototypes */

	unsigned int draw_spirographic(extended, extended, int, int);
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

/*
asm {
	brk 0x00;
}*/

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

/*------ SPIROGRAPHICS main figure drawing routine ------*/

unsigned int draw_spirographic(extended side_vertex_angle,
           extended shape_rotation_angle, int shape_repetitions,
           int shape_sides)
{
	int i, j;
	unsigned int new_color, w, h;
	extended side_cosine, side_sine;
	extended shape_cosine, shape_sine;
	extended next_x;
	int screen_x, screen_y;
	extended x = 95;
	extended y = 0;
	extended scale_factor = 0.95;

/* No input parameters can be zero! */

	if (!side_vertex_angle || !shape_repetitions || !shape_rotation_angle ||
													!shape_sides)
		return(FALSE);

/* Get a new color and stuff it manually into the proper palette entries */

	new_color = random();

	asm
	{
		lda	new_color;
		and	#0x0FFF
		sta >0xE19E02
		sta >0xE19E04
		sta >0xE19E06
		sta >0xE19E0A
		sta >0xE19E0C
		sta >0xE19E0E
		sta >0xE19E12
		sta >0xE19E14
		sta >0xE19E16
		sta >0xE19E1A
		sta >0xE19E1C
		sta >0xE19E1E
		lda	#0		/* background color */
		sta >0xE19E08
		sta >0xE19E18
	}

/* Randomize a new pen size */

	switch (random() % 9) {
		case 0:
			w = 1; h = 4; /* "X" 1 (.5) long, 4 high */
			break;
		case 1:
			w = 8; h = 1; /* "----" 8 (4) long, 1 high */
			break;
		case 2:
			w = 4; h = 2; /* "==" 4 (2) long, 2 high */
			break;
		case 3:
			w = 8; h = 2; /* "====" 8 (4) long,  2 high */
			break;
		case 4:
			w = 4; h = 4; /* "XX" 4 (2) long, 4 high */
			break;
		case 5:
			w = 4; h = 1; /* "--" 4 (2) long, 1 high */
			break;
		case 6:
		case 7:
			w = 1; h = 1; /* "." 1 (.5) long, 1 high */
			break;
		case 8:
			w = 1; h = 2; /* ":" 1 (.5) long, 2 high */
			break;
		case 9:
			w = 2; h = 1; /* "'" 2 (1) long, 1 high */
			break;
	}

	if (!SmallPen)
		SetPenSize(w,h);

/*
* The matrix of the rotation transformation is:     | cos(TH)  sin(TH)  0 |
*                                               R = | -sin(TH) cos(TH)  0 |
*                                                   |    0        0     1 |.
* At each stage of calculation, we obtain the coordinates (XN, YN) of the
* next vertex from the coordinates of the current vertex by
* (XN, YN, 1) = (X, Y, 1)R, so that:
*    XN = X*cos(TH) - Y*sin(TH)
*    YN = X*sin(TH) + Y*cos(TH).
* For speed reasons, calculate sine and cosine only once here at the beginning,
* identifying cosine = cos(60dg) and sine = sin(60dg) so we can use them later.
* NOTE: 60 degrees is just for a hexagon figure (360/6).
* NOTE: side_vertex_angle must be 3 for a hexagon.  This is because
* 60 degrees = PI/3 radians.
* --> degrees = radians*180/PI
* --> radians = degrees*PI/180
* (Each exterior angle of a hexagon is 60 degrees.  (360 degrees / 6 sides).)
* To create an image of X sided figures rotating and being scaled smaller,
* set the side_vertex_angle to the radian measure of each exterior angle of
* the regular polygon you hope to reproduce. (360/number of sides (X) will
* give you the measure of each exterior angle).
* As an example, a real nice pattern can be created using regular hexagons
* (vertex_angle = 360/6 = 60 degrees = PI/3 radians) and a rotation_angle of
* 5 degrees (PI/36 radians).
* By this same token, to make a triangle, vertex_angle would have to be 1.5,
* for a true vertex angle of PI/1.5 radians, or 120 degrees.
*/

	side_cosine = cos(PI / side_vertex_angle);
	side_sine = sin(PI / side_vertex_angle);
	shape_cosine = cos(PI / shape_rotation_angle);
	shape_sine = sin(PI / shape_rotation_angle);

	for (j = 1; j <= shape_repetitions; j++) {
		if (*movePtr)
			return(TRUE);

		for (i = 0; i <= shape_sides; i++) {
			if (*movePtr)
				return(TRUE);

/*
* For each side, before plotting, translate to onscreen locations:
* Scale the points to make a 1:1 aspect ratio, and then adjust them so that
* they are centered on screen.
* Translate each point through (CENTER_X, CENTER_Y) by multiplication by the
* matrix:            |  1  0  0  |    CX = CENTER_X
*                    |  0  1  0  |    CY = CENTER_Y
*                    | CX CY  1  |. */

			screen_x = (int) (x*SCALE_X + CENTER_X);
			screen_y = (int) (y + CENTER_Y);

			if (!i)
				MoveTo(screen_x, screen_y);
			LineTo(screen_x, screen_y);

/*
* Since we have already precalculated the rotation sines and cosines, the
* calculation of the X and Y coordinates for the next vertex (XN, YN) becomes:
*    XN = X*cosine - Y*sine
*    YN = X*sine + Y*cosine. */

			next_x = x*side_cosine - y*side_sine;
			y = x*side_sine + y*side_cosine;
			x = next_x;
		}

/*
* Now we need to make the next figure (hexagon) smaller than the previous one.
* The size of the figures (hexagons) may be controlled by multiplication by the
* matrix: |SF 0  0| SF = scale_factor of our choice.
*         |0  SF 0|
*         |0  0  1|.
* To rotate each figure (hexagon) slightly, e agan will use the transformation
* matrix with a new value for theta.
* The transition from one hexagon to the next (scaling, rotation) is effected
* by:                     |SF 0  0||cos(TH)  sin(TH) 0|
*      (XN,YN,1) = (X,Y,1)|0  SF 0||-sin(TH) cos(TH) 0|
*                         |0  0  1||   0        0    1|
* or:
*    XN = X*SF*cos(TH) - Y*SF*sin(TH)
*    YN = X*SF*sin(TH) + Y*SF*cos(TH) */

		next_x = scale_factor * (x*shape_cosine - y*shape_sine);
		y = scale_factor * (x*shape_sine + y*shape_cosine);
		x = next_x;
	}
	return(FALSE);
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
|* Spirographics-
|*  This function checks the Twilight II message parameter and			  *|
|*  dispatches control to the appropriate message handler.				  *|
\*****************************************************************************/

LongWord Spirographics (LongWord data2, LongWord data1, Word message) {

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