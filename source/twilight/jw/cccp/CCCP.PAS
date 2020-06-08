{$keep 'CCCPPAS'}

Unit CCCP;

Interface

{********************************************************
*
*	Cool Cursor Interface File
*
*	By:  Josef W. Wankerl
*
*	Other USES Files Needed: Common
*
*	Other Tool Sets Needed:	 - None -
*
*	Copyright 1993
*	By EGO Systems
*	All Rights Reserved
*
*********************************************************}

Uses
	Common;

Const
	{ target name for SendRequest to Cool Cursor }
	name_of_cccp = 'EGO Systems~Cool Cursor~';

	{ SendRequest codes sent to Cool Cursor (target = "EGO Systems~Cool Cursor~") }
	cccpAreYouThere	= $8000;
	cccpGetActive		= $8001;
	cccpSetActive		= $8002;
	cccpGetSpeed		= $8003;
	cccpSetSpeed		= $8004;
	cccpGetAppPriority = $8005;
	cccpSetAppPriority = $8006;
	cccpGetSafe			= $8007;
	cccpSetSafe			= $8008;
	cccpGetCursorList	= $8009;
	cccpSetCursorList	= $800A;
	cccpGetCursor		= $800B;
	cccpSetCursor		= $800C;
	cccpLoadCursor		= $800D;
	cccpDisposeCursor	= $800E;
	cccpAnimateCursor	= $800F;
	cccpGetCursortype	= $8010;

{ Cool Cursor constants }

	cccpMode320			= $0000;
	cccpMode640			= $0001;

	cccpPointer			= $0000;
	cccpWait				= $0001;
	cccpIBeam			= $0002;
	cccpCustom			= $0003;
	cccpOther			= $0004;

	rSmooth				= $0001;

	cccpVersionError	= $CCC9;

Type
{ Cool Cursor DataIn Structures }

	cccpSetActiveIn = Record
		cccpActiveFlag : Integer
	End;
	cccpSetActiveInPtr = ^cccpSetActiveIn;

	cccpSetSpeedIn = Record
		cccpSpeed : Integer
	End;
	cccpSetSpeedInPtr = ^cccpSetSpeedIn;

	cccpSetAppPriorityIn = Record
		cccpPriority : Integer
	End;
	cccpSetAppPriorityInPtr = ^cccpSetAppPriorityIn;

	cccpSetSafeIn = Record
		cccpSafeFlag : Integer
	End;
	cccpSetSafeInPtr = ^cccpSetSafeIn;

	cccpSetCursorListIn = Record
		cccpCursorListHandle : Handle
	End;
	cccpSetCursorListInPtr = ^cccpSetCursorListIn;

	cccpGetCursorIn = Record
		cccpCursorMode : Integer
	End;
	cccpGetCursorInPtr = ^cccpGetCursorIn;

	cccpSetCursorIn = Record
		cccpCursorMode : Integer;
		cccpMasterHandle : Handle
	End;
	cccpSetCursorInPtr = ^cccpSetCursorIn;

	cccpLoadCursorIn = Record
		cccpPathnamePtr : gsosInStringPtr;
		cccpCursorStartID : LongInt
	End;
	cccpLoadCursorInPtr = ^cccpLoadCursorIn;

	cccpDisposeCursorIn = Record
		cccpMasterHandle : Handle
	End;
	cccpDisposeCursorInPtr = ^cccpDisposeCursorIn;

	cccpAnimateCursorIn = Record
		cccpMasterHandle : Handle
	End;
	cccpAnimateCursorInPtr = ^cccpAnimateCursorIn;

{*****************************************************************************}

{ Cool Cursor DataOut Structures }

	cccpAreYouThereOut = Record
		recvCount : Integer;
		cccpID : Integer;
		cccpVersion : LongInt
	End;
	cccpAreYouThereOutPtr = ^cccpAreYouThereOut;

	cccpGetActiveOut = Record
		recvCount : Integer;
		cccpActiveFlag : Integer
	End;
	cccpGetActiveOutPtr = ^cccpGetActiveOut;

	cccpGetSpeedOut = Record
		recvCount : Integer;
		cccpSpeed : Integer
	End;
	cccpGetSpeedOutPtr = ^cccpGetSpeedOut;

	cccpGetAppPriorityOut = Record
		recvCount : Integer;
		cccpPriority : Integer
	End;
	cccpGetAppPriorityOutPtr = ^cccpGetAppPriorityOut;

	cccpGetSafeOut = Record
		recvCount : Integer;
		cccpSafeFlag : Integer
	End;
	cccpGetSafeOutPtr = ^cccpGetSafeOut;

	cccpGetCursorListOut = Record
		recvCount : Integer;
		cccpCursorListHandle : Handle
	End;
	cccpGetCursorListOutPtr = ^cccpGetCursorListOut;

	cccpGetCursorOut = Record
		recvCount : Integer;
		cccpMasterHandle : Handle
	End;
	cccpGetCursorOutPtr = ^cccpGetCursorOut;

	cccpLoadCursorOut = Record
		recvCount : Integer;
		cccpError : Integer;
		cccpMasterHandle : Handle
	End;
	cccpLoadCursorOutPtr = ^cccpLoadCursorOut;

	cccpGetCursorTypeOut = Record
		recvCount : Integer;
		cccpCursorType : Integer
	End;
	cccpGetCursorTypeOutPtr = ^cccpGetCursorTypeOut;

Implementation
End.