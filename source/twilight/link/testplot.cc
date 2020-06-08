
#include "plot.h"
#include <quickdraw.h>
#include <stdlib.h>

/*#pragma rtl*/
#pragma debug 0
#pragma optimize -1
#pragma lint -1
#pragma keep "testplot"

	void main(void);

void main(void) {

	int line,p;

	init_plot((char *)0xE10000l,(char *)GetAddress(1));
/*	InitColorTable(0xE19E00l);
	SetAllSCBs(00);
	ClearScreen(NIL);*/

asm {
	brk 0xff;
}
	p = get_pixel(7,201);

	for (line = 0; line < 200; line++) {
		set_pixel(0,line,0xFu);
		set_pixel(7,line,0x3u);
		set_pixel(4,line,0x7u);
	}

/*	p = get_pixel(0,132);
asm {
	brk 0xff;
}
	p = get_pixel(7,0);
asm {
	brk 0xff;
}
	p = get_pixel(4,89);
asm {
	brk 0xff;
} */

	exit(0);
}