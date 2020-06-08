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

#pragma keep "frantic"
#pragma cdev frantic
/*#pragma optimize -1*/

#include "frantic.H"

#pragma lint -1

#pragma debug 0	/* was -1 */

/*****************************************************************************\
|*																									  *|
|*		BlankT2Message-																		  *|
|*			This function performs the screen blanking activities.				  *|
|*																									  *|
\*****************************************************************************/

LongWord BlankT2Message (Word *movePtr)
{
	int i;							/* number of messages displayed on the screen */
	Long TargetTick;				/* end of wait tick number */

/******************************************************************/
/* Set the correct pen size so vertical lines do not appear wimpy */
/******************************************************************/

/*	SetPenSize (2, 1);*/

/************************************/
/* Seed the random number generator */
/************************************/

	SetRandSeed (GetTick ());

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

LongWord frantic (LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 1L;

	switch (message)
	{
		case MakeT2:
			break;
		case SaveT2:
			break;
		case BlankT2:
			Result = BlankT2Message ((Word *) data1);
			break;
		case LoadSetupT2:
			break;
		case UnloadSetupT2:
			break;
		case KillT2:
			break;
		case HitT2:
			break;
	}

	return Result;
}