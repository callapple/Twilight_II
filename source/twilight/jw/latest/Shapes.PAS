{*****************************************************************************}
{*																									  *}
{*												 Shapes  										  *}
{*																									  *}
{*										by: Josef W. Wankerl									  *}
{*																									  *}
{*											 Version: 1.0										  *}
{*												06/23/92											  *}
{*																									  *}
{*****************************************************************************}

{$CDev Shapes}
{$Keep 'Shapes'}
{$Optimize -1}

Program PascalShapes;

{$List+}
Uses
	Common,
	ControlMgr,
	EventMgr,
	MemoryMgr,
	MscToolSet,
	QuickDrawII,
	ResourceMgr,
	WindowMgr,
	T2;
{$List-}

Const
	MainControlList = 1;

	IconCtl = 1;
	ShapesTxtCtl = 2;

	OvalCtl = 3;
	RectangleCtl = 4;
	RoundRectangleCtl = 5;
	ArcCtl = 6;

	OvalString = 'Shapes:  Oval';
	RectangleString = 'Shapes:  Rectangle';
	RoundRectangleString = 'Shapes:  Round Rectange';
	ArcString = 'Shapes:  Arc';

Type
	rT2Word = Integer;
	rT2WordPtr = ^rT2Word;
	rT2WordHndl = ^rT2WordPtr;

Var
	Oval : Boolean;					{* Draw an oval flag *}
	Rectangle : Boolean;				{* Draw a rectangle flag *}
	RoundRectangle : Boolean;		{* Draw a round rectangle flag *}
	Arc : Boolean;						{* Draw an arc flag *}

	SetupFileNumber : Integer;
	SetupWindow : GrafPortPtr;

{*****************************************************************************}
{*																									  *}
{*		SaveConfigResource-																	  *}
{*			This procedure takes a word value and saves it as a rT2ModuleWord	  *}
{*			resource in the Twilight.Setup file.  The value is saved and a		  *}
{*			name is added.  Any previous rT2ModuleWord with the same name is	  *}
{*			first removed before the new value is added.								  *}
{*																									  *}
{*****************************************************************************}

Procedure SaveConfigResource (Name : pString; SaveValue : Integer);
Var
	NullString : pString;
	FileID : Integer;
	ResourceID : LongInt;
	ConfigData : rT2WordHndl;

Begin
{*****************************************************}
{* Check to see if the named resource already exists *}
{*****************************************************}

	ResourceID := RMFindNamedResource (rT2ModuleWord, Name, FileID);
	If ToolError <> 0
	Then Begin
		NullString[0] := Char(0);

{**************************************************************}
{* The resource already exists, so first remove the name from *}
{* the resource, then remove the resource itself				  *}
{**************************************************************}

		RMSetResourceName (rT2ModuleWord, ResourceID, NullString);
		RemoveResource (rT2ModuleWord, ResourceID)
	End;

{*********************************************}
{* Create new handle for the future resource *}
{*********************************************}

	ConfigData := rT2WordHndl (NewHandle (sizeof (Integer), MMStartUp,
		attrLocked, 0));
	ConfigData^^ := SaveValue;

{*********************************************}
{* Find a new ID for the resource and add it *}
{*********************************************}

	ResourceID := UniqueResourceID (0, rT2ModuleWord);
	AddResource (ConfigData, 0, rT2ModuleWord, ResourceID);
	If ToolError <> 0
	Then
		DisposeHandle (ConfigData)
	Else Begin

{**********************************************************}
{* Set the name of the resource if it was added correctly *}
{**********************************************************}

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber)
	End
End;

{*****************************************************************************}
{*																									  *}
{*		SaveT2Message-																			  *}
{*			This procedure saves the values of all setup controls.				  *}
{*																									  *}
{*****************************************************************************}

Procedure SaveT2Message;
Var
	FileNumber : Integer;

Begin

{***********************************************************}
{* Save current resource file and switch in Twilight.Setup *}
{***********************************************************}

	FileNumber := GetCurResourceFile;
	SetCurResourceFile (SetupFileNumber);

{***********************}
{* Save control values *}
{***********************}

	Oval := Boolean (GetCtlValue (GetCtlHandleFromID (SetupWindow, OvalCtl)));
	SaveConfigResource (OvalString, Oval);

	Rectangle := Boolean (
		GetCtlValue (GetCtlHandleFromID (SetupWindow, RectangleCtl)));
	SaveConfigResource (RectangleString, Rectangle);

	RoundRectangle := Boolean (
		GetCtlValue (GetCtlHandleFromID (SetupWindow, RoundRectangleCtl)));
	SaveConfigResource (RoundRectangleString, RoundRectangle);

	Arc := Boolean (GetCtlValue (GetCtlHandleFromID (SetupWindow, ArcCtl)));
	SaveConfigResource (ArcString, Arc);

{*****************************}
{* Restore old resource file *}
{*****************************}

	SetCurResourceFile (FileNumber)
End;

{*****************************************************************************}
{*																									  *}
{*		LoadConfigResource-																	  *}
{*			This function attempts to load a named rT2ModuleWord resource.  If  *}
{*			the resource exists, the value of the rT2ModuleWord resource is	  *}
{*			returned, otherwise a default value is returned.						  *}
{*																									  *}
{*****************************************************************************}

Function LoadConfigResource (Name : pString; DefaultValue : Integer) : Integer;
Var
	Result : Integer;
	ConfigData : rT2WordHndl;

Begin

{**************************************}
{* Attempt to load the named resource *}
{**************************************}

	ConfigData := rT2WordHndl (RMLoadNamedResource (rT2ModuleWord, Name));
	If ToolError <> 0
	Then

{********************************************************}
{* Resource does not exist, so return the default value *}
{********************************************************}

		Result := DefaultValue
	Else

{****************************************************}
{* Resource exists, return the rT2Module word value *}
{****************************************************}

		Result := ConfigData^^;

	LoadConfigResource := Result
End;

{*****************************************************************************}
{*																									  *}
{*		LoadSetupT2Message-																	  *}
{*			This procedure loads in the messages configuration data.				  *}
{*																									  *}
{*****************************************************************************}

Procedure LoadSetupT2Message;
Begin
	Oval := Boolean (LoadConfigResource (OvalString, 1));
	Rectangle := Boolean (LoadConfigResource (RectangleString, 1));
	RoundRectangle := Boolean (LoadConfigResource (RoundRectangleString, 1));
	Arc := Boolean (LoadConfigResource (ArcString, 1))
End;

{*****************************************************************************}
{*																									  *}
{*		MakeT2Message-																			  *}
{*			This function creates the controls for the messages setup window	  *}
{*			and sets the value of the controls the the current setup.			  *}
{*																									  *}
{*****************************************************************************}

Function MakeT2Message : LongInt;
Const
	resourceToResource = $0009;

Var
	FileNumber : Integer;
	NC2Result : ctlRecHndl;

Begin

{***********************************************************}
{* Save current resource file and switch in Twilight.Setup *}
{***********************************************************}

	FileNumber := GetCurResourceFile;
	SetCurResourceFile (SetupFileNumber);

{***********************************************************************}
{* Make absolutely sure that the messages configuration data is loaded *}
{***********************************************************************}

	LoadSetupT2Message;

{*****************************}
{* Restore old resource file *}
{*****************************}

	SetCurResourceFile (FileNumber);

{*********************************************************************}
{* Create setup controls and set their states to match current setup *}
{*********************************************************************}

	NC2Result := NewControl2 (SetupWindow, resourceToResource, MainControlList);

	SetCtlValue (Oval, GetCtlHandleFromID (SetupWindow, OvalCtl));
	SetCtlValue (Rectangle, GetCtlHandleFromID (SetupWindow, RectangleCtl));
	SetCtlValue (RoundRectangle,
		GetCtlHandleFromID (SetupWindow, RoundRectangleCtl));
	SetCtlValue (Arc, GetCtlHandleFromID (SetupWindow, ArcCtl));

{*****************************************}
{* Return the number of the last control *}
{*****************************************}

	MakeT2Message := ArcCtl
End;

{*****************************************************************************}
{*																									  *}
{*		HitT2Message-																			  *}
{*			This function checks to see which control has been hit, and if a	  *}
{*			control that requires the "Update" button has been hit, the			  *}
{*			EnableFlag is set to true.														  *}
{*																									  *}
{*****************************************************************************}

Function HitT2Message (ControlID : LongInt) : LongInt;
Var
	EnableFlag : LongInt;

Begin
	EnableFlag := 0;

	If ControlID = OvalCtl Then EnableFlag := 1;
	If ControlID = RectangleCtl Then EnableFlag := 1;
	If ControlID = RoundRectangleCtl Then EnableFlag := 1;
	If ControlID = ArcCtl Then EnableFlag := 1;

{****************************************}
{* Return the update button enable flag *}
{****************************************}

	HitT2Message := EnableFlag
End;

{*** ==== CUT HERE FOR AN ORCA/Pascal TWILIGHT II BLANKER SHELL ==== ***}

{*****************************************************************************}
{*																									  *}
{*		DrawAShape-																				  *}
{*			This procedure draws a random QuickDraw II shape on the screen.	  *}
{*																									  *}
{*****************************************************************************}

Procedure DrawAShape;
Const
	Shapes = 5;

Var
	ValidShape : Integer;
	RandomRect : rect;

Begin

{*********************************}
{* Set a random color to draw in *}
{*********************************}

	SetSolidPenPat ((+QDRandom) Mod 16);

{******************************************}
{* Generate a random rectangle to draw in *}
{******************************************}

	With RandomRect Do
	Begin
		v1 := (+QDRandom) Mod 200;
		h1 := (+QDRandom) Mod 320;
		v2 := (+QDRandom) Mod 200;
		h2 := (+QDRandom) Mod 320;
	End;

{*******************************}
{* Find a random shape to draw *}
{*******************************}

	ValidShape := (+QDRandom) Mod Shapes;

{*************************************************}
{* Make sure the shape is configured to be drawn *}
{*************************************************}

	If (ValidShape = 0) And (Not Oval) Then ValidShape := 1;
	If (ValidShape = 1) And (Not Rectangle) Then ValidShape := 2;
	If (ValidShape = 2) And (Not RoundRectangle) Then ValidShape := 3;
	If (ValidShape = 3) And (Not Arc) Then ValidShape := 4;

{*************************}
{* Draw the random shape *}
{*************************}

	Case ValidShape Of
		0 : PaintOval (RandomRect);
		1 : PaintRect (RandomRect);
		2 : PaintRRect (RandomRect, (+QDRandom) Mod 150, (+QDRandom) Mod 150);
		3 : PaintArc (RandomRect, (+QDRandom) Mod 360, (+QDRandom) Mod 360)
	End
End;

{*** ==== CUT HERE FOR AN ORCA/Pascal TWILIGHT II BLANKER SHELL ==== ***}

{*****************************************************************************}
{*																									  *}
{*		BlankT2Message-																		  *}
{*			This function performs the screen blanking activities.				  *}
{*																									  *}
{*****************************************************************************}

Function BlankT2Message (movePtr : movePtrType) : LongInt;
Begin

{************************************}
{* Seed the random number generator *}
{************************************}

	SetRandSeed (GetTick);

{*****************************************************}
{* Animate the screen until the movePtr becomes true *}
{*****************************************************}

	While Not movePtr^ Do
		DrawAShape;

{**********************************************}
{* No error occurred, so return a NULL handle *}
{**********************************************}

	BlankT2Message := LongInt (NIL)
End;

{*****************************************************************************}
{*																									  *}
{*		Shapes-																					  *}
{*			This function checks the Twilight II message parameter and			  *}
{*			dispatches control to the appropriate message handler.				  *}
{*																									  *}
{*****************************************************************************}

Function Shapes (message : Integer; data1 : LongInt; data2 : LongInt): LongInt;
Var
	Result : LongInt;

Begin
	Result := 1;

	Case message Of
		MakeT2 :
		Begin

{***************************************************************************}
{* Save pointer to setup window and resource file number of Twilight.Setup *}
{***************************************************************************}

			SetupWindow := GrafPortPtr (data1);
			SetupFileNumber := Integer (data2);

{*****************************}
{* Create the setup controls *}
{*****************************}

			Result := MakeT2Message
		End;
		SaveT2 : SaveT2Message;
		BlankT2 : Result := BlankT2Message (movePtrType (data1));
		LoadSetupT2 : LoadSetupT2Message;
		UnloadSetupT2 : ;
		KillT2 : ;
		HitT2 : Result := HitT2Message (data1)
	End;

	Shapes := Result
End;

Begin  {Main}
End.  {Main}