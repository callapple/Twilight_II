
#pragma keep "fr"
#pragma optimize 0
#pragma rtl
#pragma debug 0	/* was -1 */

#include <types.h>
#include <quickdraw.h>
#include <orca.h>
#include <misctool.h>

#define MAX_X	640
#define MAX_Y	200

#pragma lint -1

/* Prototypes */

	int GetKey(int *, int);
	void main(void);

/* Global Variables */

	int modifier;

/* Routines */

void main(void)
{
   unsigned int color;
	unsigned int dh,dv,sh,sv,len,dir,k,old_dir,j;
	unsigned int screenwidth = 642;     /* 2, -1 */
	unsigned int screenheight = 202;
	Rect newr;
	Long TargetTick;				/* end of wait tick number */

	startgraph(MAX_X);
	SetPenMode(modeCopy);
	SetSolidPenPat(-1);
	SetRandSeed (GetTick());
	ClearScreen(0xffff);

	sh = 6;
	sv = 3;
	newr.h1 = (+Random()) % (screenwidth-2);
	newr.v1 = (+Random()) % (screenheight-0);  /* -2 */
	newr.h2 = newr.h1 + sh;
   newr.v2 = newr.v1 + sv;
	old_dir = 0;

	while (!GetKey(&modifier, FALSE)) {

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
/*  			newr.v1 -= 2;
				newr.h1 -= 2;*/
				PaintRect(&newr);
/*				newr.v1 += 2;
				newr.h1 += 2;*/
			}
		}
	}
	endgraph();
}