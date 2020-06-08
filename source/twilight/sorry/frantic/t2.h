/********************************************
; File:	T2.h
;
; By:	 Josef W. Wankerl
;
; Copyright EGO Systems 1992
; All Rights Reserved
;
********************************************/

#ifndef __T2__
#define __T2__

/* Action message codes sent to modules. */
#define MakeT2				0
#define SaveT2				1
#define BlankT2			2
#define LoadSetupT2		3
#define UnloadSetupT2	4
#define KillT2				5
#define HitT2				6

/* Resources types. */
#define rT2ModuleFlags	0x1000
#define rT2ExtSetup1		0x1001
#define rT2ModuleWord	0x1002

#endif