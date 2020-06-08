{$keep 'T2PAS'}

Unit T2;

Interface

{********************************************************
*
*	Twilight II Interface File
*
*	By:  Josef W. Wankerl
*
*	Other USES Files Needed: - None -
*
*	Other Tool Sets Needed:	 - None -
*
*	Copyright 1992
*	By EGO Systems
*	All Rights Reserved
*
*********************************************************}

Const
{ Action message codes sent to modules. }
	MakeT2			= 0;
	SaveT2			= 1;
	BlankT2			= 2;
	LoadSetupT2		= 3;
	UnloadSetupT2	= 4;
	KillT2			= 5;
	HitT2				= 6;

{ Resources types. }
	rT2ModuleFlags = $1000;
	rT2ExtSetup1	= $1001;
	rT2ModuleWord	= $1002;

Type
	movePtrType = ^Boolean;

Implementation
End.