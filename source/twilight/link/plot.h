
/* Plot v1.2 */
	extern void init_plot(char * screenPtr, char * lookupPtr);
	extern int get_pixel(int x, int y);
/* set_pixel and getset_pixel return F if y>199, or 0 if x>319 */
	extern void set_pixel(int x, int y, int color);
	extern int getset_pixel(int x, int y, int color);