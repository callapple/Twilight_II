/*****************************************************************************\
|*																									  *|
|*											   Messages  										  *|
|*																									  *|
|*										by: Josef W. Wankerl									  *|
|*																									  *|
|*											 Version: 1.0										  *|
|*												06/15/92											  *|
|*																									  *|
\*****************************************************************************/

#pragma keep "Messages"
#pragma cdev Messages
#pragma optimize -1

#include "Messages.H"

#pragma lint -1

#pragma debug 0	/* was -1 */

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
		(Word **) NewHandle (sizeof (Word), MMStartUp (), attrLocked, 0L);
	**ConfigData = SaveValue;

/*********************************************/
/* Find a new ID for the resource and add it */
/*********************************************/

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource (ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle (ConfigData);
	else
	{

/**********************************************************/
/* Set the name of the resource if it was added correctly */
/**********************************************************/

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
	}
}

/*****************************************************************************\
|*																									  *|
|*		SaveT2Message-																			  *|
|*			This function saves the values of all setup controls.					  *|
|*																									  *|
\*****************************************************************************/

void SaveT2Message (void)
{
	Word FileNumber;
	char MultipleWorkString[7];

/***********************************************************/
/* Save current resource file and switch in Twilight.Setup */
/***********************************************************/

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/***********************/
/* Save control values */
/***********************/

	Message = GetCtlValue (GetCtlHandleFromID (SetupWindow, MessageCtl));
	SaveConfigResource (MessageString, Message);
	Request = GetCtlValue (GetCtlHandleFromID (SetupWindow, RequestCtl));
	SaveConfigResource (RequestString, Request);

	GetLETextByID (SetupWindow, MultipleCtl, &MultipleWorkString);
	Multiple = Dec2Int (&(MultipleWorkString[1]),
		((Word) MultipleWorkString[0]) & 0x00FF, 0);
	SaveConfigResource (MultipleString, Multiple);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}

/*****************************************************************************\
|*																									  *|
|*		LoadConfigResource-																	  *|
|*			This function attempts to load a named rT2ModuleWord resource.  If  *|
|*			the resource exists, the value of the rT2ModuleWord resource is	  *|
|*			returned, otherwise a default value is returned.						  *|
|*																									  *|
\*****************************************************************************/

Word LoadConfigResource (char *Name, Word DefaultValue)
{
	Word Result;
	Word **ConfigData;

/**************************************/
/* Attempt to load the named resource */
/**************************************/

	ConfigData = (Word **) RMLoadNamedResource (rT2ModuleWord, Name);
	if (toolerror ())

/********************************************************/
/* Resource does not exist, so return the default value */
/********************************************************/

		Result = DefaultValue;
	else

/****************************************************/
/* Resource exists, return the rT2Module word value */
/****************************************************/

		Result = **ConfigData;

	return Result;
}

/*****************************************************************************\
|*																									  *|
|*		LoadSetupT2Message-																	  *|
|*			This function loads in the messages configuration data.				  *|
|*																									  *|
\*****************************************************************************/

void LoadSetupT2Message (void)
{
	Message = LoadConfigResource (MessageString, 1);
	Request = LoadConfigResource (RequestString, 1);
	Multiple = LoadConfigResource (MultipleString, 5);
}

/*****************************************************************************\
|*																									  *|
|*		MakeT2Message-																			  *|
|*			This function creates the controls for the messages setup window	  *|
|*			and sets the value of the controls the the current setup.			  *|
|*																									  *|
\*****************************************************************************/

LongWord MakeT2Message (void)
{
	int i;
	Word FileNumber;
	char MultipleWorkString[7];

/***********************************************************/
/* Save current resource file and switch in Twilight.Setup */
/***********************************************************/

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/***********************************************************************/
/* Make absolutely sure that the messages configuration data is loaded */
/***********************************************************************/

	LoadSetupT2Message ();

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);

/*********************************************************************/
/* Create setup controls and set their states to match current setup */
/*********************************************************************/

	NewControl2 (SetupWindow, resourceToResource, MainControlList);

	SetCtlValue (Message, GetCtlHandleFromID (SetupWindow, MessageCtl));
	SetCtlValue (Request, GetCtlHandleFromID (SetupWindow, RequestCtl));

	Int2Dec (Multiple, &(MultipleWorkString[1]), 5, 0);
	for (i = 1; (i < 7) && (MultipleWorkString[i] == ' '); i++);
	MultipleWorkString[i - 1] = 6 - i;
	SetLETextByID (SetupWindow, MultipleCtl, &(MultipleWorkString[i - 1]));

/*****************************************/
/* Return the number of the last control */
/*****************************************/

	return ZeroTxtCtl;
}

/*****************************************************************************\
|*																									  *|
|*		HitT2Message-																			  *|
|*			This function checks to see which control has been hit, and if a	  *|
|*			control that requires the "Update" button has been hit, the			  *|
|*			EnableFlag is set to true.														  *|
|*																									  *|
\*****************************************************************************/

LongWord HitT2Message (LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == MessageCtl)
		EnableFlag = 1L;
	if (ControlHit == RequestCtl)
		EnableFlag = 1L;
	if (ControlHit == MultipleCtl)
		EnableFlag = 1L;

/****************************************/
/* Return the update button enable flag */
/****************************************/

	return EnableFlag;
}

/*****************************************************************************\
|*																									  *|
|*		BlankT2Message-																		  *|
|*			This function performs the screen blanking activities.				  *|
|*																									  *|
\*****************************************************************************/

LongWord BlankT2Message (Word *movePtr)
{
	int i;							/* number of messages displayed on the screen */
	int Count;						/* number of messages to display */
	int Offset;						/* offset in message handle to start of string */
	int Override;					/* not showing messages or requests flag */
	int wrap;						/* message index wraped flag */
	Word Fore;						/* foreground color for text */
	Word Back;						/* background color for text */
	Long StartIndex;				/* anchor point for message index */
	Long MessageIndex = 1L;		/* current index into the messages */
	Long TargetTick;				/* end of wait tick number */
	Handle MessageHandle;		/* handle to the current message */

/******************************************************************/
/* Set the correct pen size so vertical lines do not appear wimpy */
/******************************************************************/

	SetPenSize (2, 1);

/************************************/
/* Seed the random number generator */
/************************************/

	SetRandSeed (GetTick ());

/***********************************************************************/
/* If the number of messages to draw is zero, change the count so that */
/* it draws all the messages.  Otherwise, set the count to the number  */
/* of messages to draw																  */
/***********************************************************************/

	if (Multiple == 0)
		Count = 32767;
	else
		Count = Multiple;

/****************************************************************************/
/* If both messages and requests are not being shown, set the override flag */
/****************************************************************************/

	if ((!Message) && (!Request))
		Override = 1;
	else
		Override = 0;

/*****************************************************/
/* Animate the screen until the movePtr becomes true */
/*****************************************************/

	while (!(*movePtr))

  	{

/************************************************************/
/* Wait for five seconds, or until the movePtr becomes true */
/************************************************************/

		TargetTick = GetTick () + (5 * 60);
		while ((!(*movePtr)) && (GetTick () < TargetTick));
	}

/**********************************************/
/* No error occurred, so return a NULL handle */
/**********************************************/

	return (LongWord) NULL;
}

/*****************************************************************************\
|*																									  *|
|*		Messages-																				  *|
|*			This function checks the Twilight II message parameter and			  *|
|*			dispatches control to the appropriate message handler.				  *|
|*																									  *|
\*****************************************************************************/

LongWord Messages (LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 1L;

	switch (message)
	{
		case MakeT2:

/***************************************************************************/
/* Save pointer to setup window and resource file number of Twilight.Setup */
/***************************************************************************/

			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;

/*****************************/
/* Create the setup controls */
/*****************************/

			Result = MakeT2Message ();
			break;
		case SaveT2:
			SaveT2Message ();
			break;
		case BlankT2:
			Result = BlankT2Message ((Word *) data1);
			break;
		case LoadSetupT2:
			LoadSetupT2Message ();
			break;
		case UnloadSetupT2:
			break;
		case KillT2:
			break;
		case HitT2:
			Result = HitT2Message (data2);
			break;
	}

	return Result;
}