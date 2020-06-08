
#include "types.rez"
#include ":jim4:dya:twilight:t2common.rez"

resource rT2ModuleFlags (0x1) {
	wantFadeOut+wantFadeIn
};


// --- Module name resource

resource 0x8006 (0x1) {
       "Foreground Fader"
};

// --- About text resource

resource rTextForLETextBox2 ($0010DD01) {
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
       "\$00"
       "\$08"
       "\$01"
       "C"
       "\$11"
       "\$11"
       "\$01"
       "B"
       "\$FF"
       "\$FF"
       "This module fades your screen to black when it's time to "
       "blank the screen and fades it back in when it's time to restore the "
       "screen."
};

// --- Version resource

resource rVersion (0x1) {
       { $1,$0,$0,beta,$3 },             // Version 1.0b3
       verUS,                             // US Version
       "Twilight II Foreground Fader Module",     // program's name
       "By Jim Maricondo.\n"
       "Copyright 1991 Jim Maricondo."    // copyright notice
};

// --- About icon resource

resource rIcon ($0010DD01) {
       $8000,                  // kind
       $0014,                  // height
       $001C,                  // width

       $"FFF0000000000000000000000FFF"
       $"FFF0FFFFFFFFFFFFFFFFFFFF0FFF"
       $"FFF0F000000000000000000F0FFF"
       $"FFF0F011111111111111110F0FFF"
       $"FFF0F000000000000000000F0FFF"
       $"FFF0F000000000000000000F0FFF"
       $"FFF0F011111111111111110F0FFF"
       $"FFF0F000000000000000000F0FFF"
       $"FFF0F011111111111111110F0FFF"
       $"FFF0F011111111111111110F0FFF"
       $"FFF0F011111111111111110F0FFF"
       $"FFF0F000000000000000000F0FFF"
       $"FFF0FFFFFFFFFFFFFFFFAFFF0FFF"
       $"FFF0000000000000000000000FFF"
       $"FFFF0FFFFFFFFFFFFFFFFFF0FFFF"
       $"FFFF0FFFFFFFFFFFFFFFFFF0FFFF"
       $"FFFF0FF4AFFFFFFFFFFFFFF0FFFF"
       $"FFFF0CCCCCCCCCCCCCCCCCC0FFFF"
       $"FFFF0FFFFFFFFFFFFFFFAFF0FFFF"
       $"FFFF00000000000000000000FFFF",

       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"000FFFFFFFFFFFFFFFFFFFFFF000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000"
       $"0000FFFFFFFFFFFFFFFFFFFF0000";
};