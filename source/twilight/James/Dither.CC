#pragma keep "Dither"
#pragma optimize -2
#pragma debug 0

#include <Types.h>

#define NumColors 7              /* number of colors we can access from our custom color palette */
#define NumShades 11             /* number of shades we can derive from each color */


typedef longword Pattern2 [8];  /* this is another, more convenient way of representing QuickDraw's Pattern data structure */
Pattern2 ditherColor [NumColors][NumShades]; /* the array of dithered colors with shades per color */
/*    SetPenPat (&ditherColor [color][shade]); */ /* here we set the dithered color indexed by the shade and color */


/* Sets my patterns. Note array format: ditherColor [color, shade, pattern]. */
void SetCustomDitherColorPatterns (void)
{
integer i, c, s, p;

ditherColor[0][0][0] = 0x00000000; /* 0% mixture */
ditherColor[0][0][1] = 0x00000000;
ditherColor[0][0][2] = 0x00000000;
ditherColor[0][0][3] = 0x00000000;
ditherColor[0][0][4] = 0x00000000;
ditherColor[0][0][5] = 0x00000000;
ditherColor[0][0][6] = 0x00000000;
ditherColor[0][0][7] = 0x00000000;
 
ditherColor[0][1][0] = 0x00100000; /* 6.25% mixture */
ditherColor[0][1][1] = 0x00000000;
ditherColor[0][1][2] = 0x00000010;
ditherColor[0][1][3] = 0x00000000;
ditherColor[0][1][4] = 0x10000000;
ditherColor[0][1][5] = 0x00000000;
ditherColor[0][1][6] = 0x00001000;
ditherColor[0][1][7] = 0x00000000;
 
ditherColor[0][2][0] = 0x10000000; /* 12.5% mixture */
ditherColor[0][2][1] = 0x00001000;
ditherColor[0][2][2] = 0x00100000;
ditherColor[0][2][3] = 0x00000010;
ditherColor[0][2][4] = 0x10000000;
ditherColor[0][2][5] = 0x00001000;
ditherColor[0][2][6] = 0x00100000;
ditherColor[0][2][7] = 0x00000010;
 
ditherColor[0][3][0] = 0x10001000; /* 25% mixture */
ditherColor[0][3][1] = 0x00100010;
ditherColor[0][3][2] = 0x01000100;
ditherColor[0][3][3] = 0x00010001;
ditherColor[0][3][4] = 0x10001000;
ditherColor[0][3][5] = 0x00100010;
ditherColor[0][3][6] = 0x01000100;
ditherColor[0][3][7] = 0x00010001;
 
ditherColor[0][4][0] = 0x10001000; /* 37.5% mixture */
ditherColor[0][4][1] = 0x01010101;
ditherColor[0][4][2] = 0x00100010;
ditherColor[0][4][3] = 0x01010101;
ditherColor[0][4][4] = 0x10001000;
ditherColor[0][4][5] = 0x01010101;
ditherColor[0][4][6] = 0x00100010;
ditherColor[0][4][7] = 0x01010101;
 
ditherColor[0][5][0] = 0x10101010; /* 50% mixture */
ditherColor[0][5][1] = 0x01010101;
ditherColor[0][5][2] = 0x10101010;
ditherColor[0][5][3] = 0x01010101;
ditherColor[0][5][4] = 0x10101010;
ditherColor[0][5][5] = 0x01010101;
ditherColor[0][5][6] = 0x10101010;
ditherColor[0][5][7] = 0x01010101;

/* Create 62.5%, 75%, 87.5%, 93.75%, and 100% mixtures by inverting
   the first 5 mixtures: */
for (s = 6, i = 4; s < NumShades; s++, i--)
  for (p = 0; p < 8; p++)
    ditherColor[0][s][p] = 0x11111111 - ditherColor[0][i][p];
 
/* Now with the first dithered color semi-complete, use it as a template
   to generate the rest of the dithered colors' shades: */
for (c = 1; c < NumColors; c++)
  for (s = 0; s < NumShades; s++)
    for (p = 0; p < 8; p++)
      ditherColor[c][s][p] = (0x11111111 - ditherColor[0][s][p]) * ( ((c+1) * 2)-1 ) +
                                         ( ditherColor[0][s][p]  *   ((c+1) * 2) );
 
/* With all of the dithered colors created, complete the first color's
   shades by using itself as a template: */
c = 0;
  for (s = 0; s < NumShades; s++)
    for (p = 0; p < 8; p++)
      ditherColor[c][s][p] = (0x11111111 - ditherColor[0][s][p]) * ( ((c+1) * 2)-1 ) +
                                         ( ditherColor[0][s][p]  *   ((c+1) * 2) );
}