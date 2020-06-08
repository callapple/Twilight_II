#pragma keep "Lines"

#include <Orca.h>


void Line(int,int,int,int,int);
void SmoothLine(int,int,int,int,int,int);
void Plot(int,int,int);
int GetKey(void);
extern int random(void);
extern void set_random_seed(void);

int main(void)
{
    int x1,y1,x2,y2,i;

    startgraph(320);
    set_random_seed();
    do {
        x1=random() % 160;
        x2=random() % 160;
        y1=random() % 100;
        y2=random() % 100;
        Line(x1,y1,x2,y2,15);
        SmoothLine(x1+160,y1,x2+160,y2,15,1);
        SmoothLine(x1+160,y1+100,x2+160,y2+100,3,10);
    }  while(0x1B != GetKey());
    endgraph();
}

void SmoothLine(x1,y1,x2,y2,Color, OtherColor)
{
    int xDelta, yDelta, xStep=1, yStep=1, Cycle;

    xDelta=x2-x1;
    yDelta=y2-y1;
    if(xDelta<0)
    {
        xDelta=-xDelta;
        xStep=-1;
    }
    if(yDelta<0)
    {
        yDelta=-yDelta;
        yStep=-1;
    }
    if(yDelta<xDelta)
    {
        Cycle=xDelta >>1;
        while(x1 != x2)
        {
            Plot(x1, y1, Color);
            Cycle+=yDelta;
            if(Cycle>xDelta)
            {
                Plot(x1+xStep, y1, OtherColor);
                Cycle-=xDelta;
                y1+=yStep;
                Plot(x1, y1, OtherColor);
            }
            x1+=xStep;
        }
        Plot(x1,y1,Color);
    }
    else
    {
        Cycle=yDelta >>1;

        while(y1 != y2)
        {
            Plot(x1, y1, Color);
            Cycle+=xDelta;
            if(Cycle>yDelta)
            {
                Plot(x1, y1+yStep, OtherColor);
                Cycle-=yDelta;
                x1+=xStep;
                Plot(x1, y1, OtherColor);
            }
            y1+=yStep;
        }
        Plot(x1,y1,Color);
    }
}



void Line(x1,y1,x2,y2,Color)
{
    int xDelta, yDelta, xStep=1, yStep=1, Cycle;

    xDelta=x2-x1;
    yDelta=y2-y1;
    if(xDelta<0)
    {
        xDelta=-xDelta;
        xStep=-1;
    }
    if(yDelta<0)
    {
        yDelta=-yDelta;
        yStep=-1;
    }
    if(yDelta<xDelta)
    {
        Cycle=xDelta >>1;
        while(x1 != x2)
        {
            Plot(x1, y1, Color);
            Cycle+=yDelta;
            if(Cycle>xDelta)
            {
                Cycle-=xDelta;
                y1+=yStep;
            }
            x1+=xStep;
        }
        Plot(x1,y1,Color);
    }
    else
    {
        Cycle=yDelta >>1;

        while(y1 != y2)
        {
            Plot(x1, y1, Color);
            Cycle+=xDelta;
            if(Cycle>yDelta)
            {
                Cycle-=yDelta;
                x1+=xStep;
            }
            y1+=yStep;
        }
        Plot(x1,y1,Color);
    }
}





void Plot(int x, int y, int color)
{
    char *PP;

    if(x<0 || y<0 || x>319 || y>199)
        return;
    PP=(char *) (0xE12000 + 160 * y + (x>>1));
    if(x & 0x01)
        *PP=(*PP & 0xF0) | color;
    else
        *PP=(*PP & 0x0F) | (color<<4);
}

int GetKey()
{
	char ch, *cp;

	cp = (char *) 0x00C000;                 /* wait for keypress */
	while ((*cp & 0x80) == 0) ;
	ch = (*cp) & 0x7F;                               /* save the key */
	cp = (char *) 0x00C010;                 /* clear the strobe */
	*cp = 0;
	return ch;
}