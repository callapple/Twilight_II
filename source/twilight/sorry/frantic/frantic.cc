
#pragma keep "frantic"
#pragma cdev frantic
#pragma optimize -1

/*#include "frantic.H"*/
#include <t2.h>
#include <quickdraw.h>
pascal longword GetTick(void) inline(0x2503,dispatcher);

#pragma lint -1
#pragma debug 0	/* was -1 */

/* Prototypes */

	LongWord BlankT2Moire(void);

/* Global Variables */

Word *movePtr;
   
/*****************************************************************************\
|*																									  *|
|*		BlankT2Message-																		  *|
|*			This function performs the screen blanking activities.				  *|
|*																									  *|
\*****************************************************************************/

LongWord BlankT2Message (void)
{

   unsigned int color;
	unsigned int dh,dv,sh,sv,len,dir,k,old_dir,j;
	unsigned int screenwidth = 640;
	unsigned int screenheight = 200;
	Rect newr;
	Long TargetTick;				/* end of wait tick number */

	SetRandSeed (GetTick ());

/*****************************************************/
/* Animate the screen until the movePtr becomes true */
/*****************************************************/

	sh = 6;
	sv = 3;
	newr.h1 = (+Random()) % (screenwidth + 1);
	newr.v1 = (+Random()) % (screenheight + 1);
	newr.h2 = newr.h1 + sh;
   newr.v2 = newr.v1 + sv;
	old_dir = 0;

	while (!(*movePtr)) {

		Set640Color(Random() & 0xF);

		for (j = 1; j <= 20; ++j) {
			dir = Random() % 2;
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
					len = (Random() % newr.v1) / sv;
					dh = 0;
					dv = -sv;
					break;
				case 1:
					len = (Random() % (screenwidth - newr.h2)) / sh;
					dh = sh;
					dv = 0;
					break;
				case 2:
					len = (Random() % (screenheight - newr.v2)) / sv;
					dh = 0;
					dv = sv;
					break;
				case 3:
					len = (Random() % newr.h1) / sh;
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
		case BlankT2:
			movePtr=(Word *) data1;
			Result=BlankT2Message();
		case MakeT2:
		case SaveT2:
		case LoadSetupT2:
		case UnloadSetupT2:
		case KillT2:
		case HitT2:
			break;
	}

	return Result;
}