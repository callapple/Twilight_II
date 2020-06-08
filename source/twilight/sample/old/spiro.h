
#include <types.h>
#include <quickdraw.h>
#include <orca.h>
#include <math.h>
#include <memory.h>
#include <sane.h>
#include <control.h>
#include <quickdraw.h>
#include <resources.h>
#include <window.h>
#include <locator.h>
#include <misctool.h>

#include "22:t2.h"

#define MAX_X		640
#define MAX_Y		200
#define CENTER_Y	MAX_Y/2
#define CENTER_X	MAX_X/2
/* Aspect ratio = 1.27 for 320 mode    for standard displays
                  2.54 for 640 mode    for standard displays
                  2.10 for 640 mode    for Jim's condensed-type display */
#define SCALE_X	2.10
#define PI			3.141592653589793

/* resource IDs */

#define imageDelayCtl_rID			1L
#define forceSmallPenCtl_rID 		2L
#define imageDelayStatTextCtl_rID 	3L
#define spiroOptsStatTextCtl_rID 	4L
#define iconCtl_rID				5L

#define MainControlList			1L

/* Control IDs */

#define forceSmallPenCtl	1L
#define imageDelayTxtCtl	2L
#define iconCtl			3L
#define imageDelayCtl		4L

#define LastCtl			imageDelayCtl

  