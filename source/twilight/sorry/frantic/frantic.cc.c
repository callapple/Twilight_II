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

/*#include "frantic.H"*/
#include <t2.h>
#include <quickdraw.h>
pascal longword GetTick(void) inline(0x2503,dispatcher);

/*#pragma lint -1*/

#pragma debug 0	/* was -1 */

#define SCREENWIDTH 640
#define SCREENHEIGHT 200

/*****************************************************************************\
|*																									  *|
|*		BlankT2Message-																		  *|
|*			This function performs the screen blanking activities.				  *|
|*																									  *|
\*****************************************************************************/

LongWord BlankT2Message (Word *movePtr)
{

   unsigned int color;
	unsigned int dh,dv,sh,sv,len,dir,k,old_dir,j;
	Rect newr;
	
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

	sh = 6;
	sv = 3;
	newr.left = Randomize(SCREENWIDTH + 1);
	newr.top = Randomize(SCREENHEIGHT + 1);
	newr.right = (newr.left + sh);
   newr.bottom = (newr.top + sv);
	old_dir = 0;

	while (!(*movePtr)) {

		SetDithColor(Randomize(16));

		for (j = 1; j <= 20; ++j) {
			dir = Randomize(2);
			switch (old_dir)
			{
				case 0:
					if (dir == 0)
						dir = 3;
					else dir = 1;
					break;
				case 1:
					if (dir == 1)
						dir = 2;
					break;
				case 2:
					if (dir == 0)
						dir = 1;
					else dir = 3;
					break;
				case 3:
					if (dir == 1)
						dir = 2;
					break;
			}
			old_dir = dir;
			switch (dir)
			{
				case 0:
					len = (Randomize(newr.top) / sv);
					dh = 0;
					dv = -sv;
					break;
				case 1:
					len = (Randomize(SCREENWIDTH-newr.right) / sh);
					dh = sh;
					dv = 0;
					break;
				case 2:
					len = (Randomize(SCREENHEIGHT-newr.bottom) / sv);
					dh = 0;
					dv = sv;
					break;
				case 3:
					len = (Randomize(newr.left) / sh);
					dh = -sh;
					dv = 0;
					break;
			}
			for (k = 1; k <= len; ++k) {
				OffsetRect(&newr,dh,dv);
				PaintRect(&newr);
			}
		}
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


Randomize (int range)
{
  long    rawResult;

  /* Generate a random number using QuickDraw's Random() function.          */

  rawResult = Random ();
  rawResult &= 0x7FFFL;
  return ((rawResult * range) / 32768);
}