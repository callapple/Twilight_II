{*****************************************************************************}
{*																									  *}
{*												 Shapes  										  *}
{*																									  *}
{*										by: Josef W. Wankerl									  *}
{*																									  *}
{*											 Version: 1.0										  *}
{*												06/08/92											  *}
{*																									  *}
{*****************************************************************************}

{$CDev Shapes}
{$Keep 'Shapes'}
{$Optimize -1}

Program PascalShapes;

Uses Common, QuickDrawII, T2;

Procedure DrawAShape;
Const
	Shapes = 4;

Var
	RandomRect : rect;
	RandomPattern : pattern;
	PatternElement : Byte;
	I : Integer;

Begin
	PatternElement := ((+QDRandom) Mod 16);
	PatternElement := PatternElement + (PatternElement << 4);

	For I := 0 to 31 Do
		RandomPattern[I] := PatternElement;

	SetPenPat (RandomPattern);

	With RandomRect Do
	Begin
		v1 := (+QDRandom) Mod 200;
		h1 := (+QDRandom) Mod 320;
		v2 := (+QDRandom) Mod 200;
		h2 := (+QDRandom) Mod 320;
	End;

	Case (+QDRandom) Mod Shapes Of
		0 : PaintOval (RandomRect);
		1 : PaintRect (RandomRect);
		2 : PaintRRect (RandomRect, (+QDRandom) Mod 150, (+QDRandom) Mod 150);
		3 : PaintArc (RandomRect, (+QDRandom) Mod 360, (+QDRandom) Mod 360)
	End
End;

Function BlankT2Message (movePtr : movePtrType) : LongInt;
Begin
	While Not movePtr^ Do
		DrawAShape;

	BlankT2Message := LongInt (NIL)
End;

Function Shapes (message : Integer; data1 : LongInt; data2 : LongInt): LongInt;
Begin
	If message = BlankT2
		Then Shapes := BlankT2Message (movePtrType (data1))
		Else Shapes := 1
End;

Begin  {Main}
End.  {Main}