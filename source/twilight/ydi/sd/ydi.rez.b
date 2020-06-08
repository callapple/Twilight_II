
#include "types.rez"
#include ":jim4:dya:twilight:t2common.rez"

// --- type $8001 defines
#define YDI_Icon $10dd01
// --- type $8003 defines
#define YDI_CtlLst $00000005
// --- type $8004 defines
#define YDISetAnimPathCtl $00006FFF
#define YDIAnimPathStrCtl $00007000
#define YDIStrCtl $00007001
#define YDIIconCtl $00007002
// --- type $8006 defines
#define YDISetAnimPathStr $00000011
// --- type $800B defines
#define YDI_LText $00000001
#define AnimPath_LText $00000002


resource rT2ModuleFlags (moduleFlags) {
	fSetupSupported+fWantFadeOut+fWantFadeIn+fForceLoadSetupAtBlank
};


// --- Module name resource

resource rPString (moduleName) {
 "YouDrawIt!"
};


// --- About text resource

resource rTextForLETextBox2 (moduleMessage) {
	TBLeftJust
//	TBLeftMargin
//       "\$00\$00"
	TBForeColor TBColor1
	TBBackColor TBColorF
       "The YouDrawIt! module allows you to create your own animations to"
       " be displayed when it's time to blank!"
};

// --- Version resource

resource rVersion (moduleVersion) {
       { $1,$0,$0,beta,$3 },              // Version 1.0b3
       verUS,                             // US Version
       "Twilight II YouDrawIt! Module",        // program's name
       "By Jim Maricondo.\n"
       "Copyright 1991, 1992 Jim Maricondo."    // copyright notice
};



// --- Icon Definitions

resource rIcon (moduleIcon) {
       $8000,                  // kind
       $0014,                  // height
       $0016,                  // width

       $"0000000000000000000000"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0F000000000000000000F0"
       $"0F0F0FC0FFFFFFFFFFF0F0"
       $"0F0F0FC0FFFFFFFFFFF0F0"
       $"0F0F0003FFFFFFFFFFF0F0"
       $"0F0F0880FFFFFFFFFFF0F0"
       $"0F0F0AA0FFFF888F8FF0F0"
       $"0F0FC0103FFAAAFAFFF0F0"
       $"0F0FFF000F1111111FF0F0"
       $"0F0FFFFFFFFFFFFFFFF0F0"
       $"0F000000000000000000F0"
       $"0FFFFFFFFFFFFFFFFAFFF0"
       $"0000000000000000000000"
       $"F0FFFFFFFFFFFFFFFFFF0F"
       $"F0FFFFFFFFFFFFFFFFFF0F"
       $"F0FF4AFFFFFFFFFFFFFF0F"
       $"F0CCCCCCCCCCCCCCCCCC0F"
       $"F0FFFFFFFFFFFFFFFAFF0F"
       $"F00000000000000000000F",

       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"FFFFFFFFFFFFFFFFFFFFFF"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0FFFFFFFFFFFFFFFFFFFF0"
       $"0FFFFFFFFFFFFFFFFFFFF0";
};

// --- Control List Definitions

resource rControlList (YDI_CtlLst, $0000) {
       {
       YDIIconCtl,        // control 3
       YDIStrCtl,        // control 4
//       YDIAnimPathStrCtl,        // control 5
       YDISetAnimPathCtl,        // control 6
       };
};

// --- Control Templates

resource rControlTemplate (YDISetAnimPathCtl, $0000) {
       $00000001,              // ID
       { 72, 92, 85,250},      // rect
       simpleButtonControl {{
               $0000,          // flag
               $3002,          // moreFlags
               $00000000,      // refCon
               YDISetAnimPathStr,  // titleRef
               0,              // colorTableRef
               {"S","s",$0100,$0100}  // key equivalents
       }};
};

resource rControlTemplate (YDIAnimPathStrCtl, $0000) {
       $00000002,              // ID
       { 93, 12,125,331},      // rect
       statTextControl {{
               $0000,          // flag
               $1002,          // moreFlags
               $00000000,      // refCon
               AnimPath_LText,     // textRef
               NIL, // textSize
               $0000           // just
       }};
};

resource rControlTemplate (YDIStrCtl, $0000) {
       $00000003,              // ID
       { 56,128, 64,247},      // rect
       statTextControl {{
               $0000,          // flag
               $1002,          // moreFlags
               $00000000,      // refCon
               YDI_LText,     // textRef
               NIL, // textSize
               $0000           // just
       }};
};

resource rControlTemplate (YDIIconCtl, $0000) {
       $00000004,              // ID
       { 33,146, 53,194},      // rect
       iconButtonControl {{
               $000C,          // flag
               $1020,          // moreFlags
               $00000000,      // refCon
               YDI_Icon,  // iconRef
               0,              // titleRef
               0,              // colorTableRef
               $0000          // displayMode
       }};
};

// --- rPString Templates

resource rPString (YDISetAnimPathStr, $0000) {
       "Set Animation Path"
};

// --- rTextForLETextBox2 Templates

resource rTextForLETextBox2 (YDI_LText, $0000) {
       "You Draw It!"
};

resource rTextForLETextBox2 (AnimPath_LText, $0000) {
       "\$01"
       "J"
       "\$00"
       "\$00"
       "\$01"
       "L"
       "\$00"
       "\$00"
       "\$01"
       "R"
       "\$04"
       "\$00"
       "\$01"
       "F"
       "\$FE"
       "\$FF"
       "\$02"
       "\$08"
       "\$01"
       "C"
       "\$00"
       "\$00"
       "\$01"
       "B"
       "\$FF"
       "\$FF"
       "Animation Path:"
       "\$01"
       "F"
       "\$FE"
       "\$FF"
       "\$00"
       "\$08"
       "\$01"
       "C"
       "\$00"
       "\$00"
       "\$01"
       "B"
       "\$FF"
       "\$FF"
       " "
       "\$D2"
       "*0"
       "\$D3"
       "\$01"
       "F"
       "\$FE"
       "\$FF"
       "\$00"
       "\$08"
       "\$01"
       "C"
       "\$00"
       "\$00"
       "\$01"
       "B"
       "\$FF"
       "\$FF"
};
