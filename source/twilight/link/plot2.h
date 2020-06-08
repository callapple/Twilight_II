
/* Plot v2 - 18 Jan 93 JRM */
	extern void init_plot(char * screenPtr, char * lookupPtr, char * targetStr);
/* You should not have to call setup_plot - init_plot does it for you */
	extern void setup_plot(char * screenPtr, char * lookupPtr);
	extern int get_pixel(int x, int y);
/* set_pixel and getset_pixel return F if y>199, or 0 if x>319 */
	extern void set_pixel(int x, int y, int color);
	extern int getset_pixel(int x, int y, int color);