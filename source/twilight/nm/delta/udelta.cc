#include <stdio.h>
#pragma lint -1
#pragma optimize -1

/*
 * Fcn prototype for asm subroutine that does 90% of the work
 *
 */

int DoDelta (char *filename);

/*
 * C language preprocessor for
 * delta engine... gets the command line args and all
 *
 */

int main (int argc, char *argv[])
{
 int i;
 int err=0;
 int count;

/* printf("Number of args=%d\n",argc);
 printf("Command name:'%s \n", argv[0]);
 for (i=1;i<argc;i++)
   printf("arg #%d, is:'%s'\n",i,argv[i]);
 printf("End of args\n"); */
 if (argc>=2)
   {
     for (count=1;count<argc;count++)
       {
         printf("Undelta'ing file %s.\n",argv[count]);
         err=DoDelta(argv[count]);
       }
   }
 else
   {
     printf("Delta Undoer 0.1 by Nathan Mates\n");
     printf("Usage:\n");
     printf("   udelta infile [infile2 infile3....]\n\n");
     printf("The input file(s) are undeltad, and written over.\n");
   }
 return err;
}