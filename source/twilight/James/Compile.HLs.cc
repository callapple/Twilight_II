#pragma keep "Compile.HLs"

#include <stdio.h>
#include <string.h>

#define MaxSubsPerKeyWord 256
#define MaxKeyWordLength  32
#define MaxNumKeyWords 256
#define MaxLineLength 256

/* first pass
**      build table of all key words that are DEFINED and count the number substitutions for each key word
**
**
** second pass
**      skip space for header on output file
**          skip space for poniters to substitutions
**          write first substitution replacing key word references with key word opcode numbers
**          fill in poniter to first word
**          do next text substitution
**       do next key word
**       write header pointers
*/

typedef unsigned int FileAddress;
FILE *SourceFile, *CompiledFile;

struct {
    char            KeyWord[MaxKeyWordLength];
    int             NumberOfSubstitutions;
    FileAddress     Location; /* of list of substitutions in output file */
} SymboleTable[MaxNumKeyWords];
int NumKeyWords;

FileAddress SubstitutionList[MaxSubsPerKeyWord];
int NumSubstitutions;
char work[MaxLineLength];

void Pass1(void);
void Pass2(void);
void MyRead(void);
int Find(char *, int);

void main(void)
{
    printf("Opening files...\n");
    SourceFile=fopen("Headlines.Src", "r");
    CompiledFile=fopen("Headlines.DATA", "wb");
    fputs("Headlines data file version 1.00\n", CompiledFile);
    printf("Pass 1...\n");
    Pass1();
    printf("Pass 2...\n");
    Pass2();
    printf("Closing files...\n");
    fclose(SourceFile);
    fclose(CompiledFile);
    printf("Done\n");
}

void Pass1(void)
{
    NumKeyWords=0;
    do{
        do{
            MyRead();
            if(feof(SourceFile))
                break;
        } while (work[0] != '#');          /* read lines untill you find one starting with a key word marker */
        if(feof(SourceFile))
            break;
        NumKeyWords++;
        strcpy(SymboleTable[NumKeyWords-1].KeyWord, work+1);
        printf("%d Key Word:%s...", NumKeyWords-1, work+1);
        do{
            MyRead();
            if(work[0])
                SymboleTable[NumKeyWords-1].NumberOfSubstitutions++;
        } while (work[0]);          /* read lines untill you find a blank one */
        printf("has %d substitutions.\n", SymboleTable[NumKeyWords-1].NumberOfSubstitutions);
    } while (!feof(SourceFile));
}

void Pass2(void)
{
    FileAddress LocKeyWord, LocSubText;
    int SubNumber, KeyWordNumber=-1;
    int KeyWordPos, KeyWordEndPos, KeyWordLength, SearchStart, tmp;

    fseek(SourceFile, 0, SEEK_SET);
    LocKeyWord=50 + NumKeyWords*(2+ (sizeof (FileAddress)));
    do{
        do{
            MyRead();
            if(feof(SourceFile))
                break;
        } while (work[0] != '#');          /* read lines untill you find one starting with a key word marker */
        if(feof(SourceFile))
            break;
        KeyWordNumber++;
        SymboleTable[KeyWordNumber].Location=LocKeyWord;

        LocSubText=LocKeyWord+(SymboleTable[KeyWordNumber].NumberOfSubstitutions*(sizeof (FileAddress)));
        SubNumber=-1;
        fseek(CompiledFile, LocSubText, SEEK_SET);
        printf("Key Word:%s\n", work+1);
        do{
            MyRead();
            if(work[0]) {
                SubNumber++;
                /* replace any key words with key word opcodes */
                SearchStart=0;
                while(-1 != (tmp=(strpos(work+SearchStart, '<'))))
                {
                    KeyWordPos=tmp+SearchStart;
                    SearchStart=KeyWordPos+2;

                    work[KeyWordPos]=0xFF;  /* replace the < with a key word flag */

                    work[KeyWordPos+1]=
                    (char) Find(work+KeyWordPos+1, KeyWordLength=strpos(work+KeyWordPos+1, '>'));
                    (work[KeyWordPos+1])+=32;
                    KeyWordEndPos=KeyWordPos+1+KeyWordLength;

                    if(strlen(work)>KeyWordEndPos)
                        memmove(work+KeyWordPos+2, work+KeyWordEndPos+1, strlen(work)-KeyWordEndPos);
                }
                fputs(work, CompiledFile);
                fputc('\n', CompiledFile);
                SubstitutionList[SubNumber]=LocSubText;
                LocSubText+=strlen(work)+1;
            }
        } while (work[0]);          /* read lines untill you find a blank one */
        fseek(CompiledFile, LocKeyWord, SEEK_SET);  /* get into position to write aray of pointers to substitution text */
        fwrite(SubstitutionList, sizeof (FileAddress), SubNumber+1, CompiledFile);
        LocKeyWord=LocSubText;
    } while (!feof(SourceFile));
    fseek(CompiledFile, 50, SEEK_SET);  /* get into position to write master header */
    for(KeyWordNumber=0; KeyWordNumber<NumKeyWords; KeyWordNumber++)
    {
        fwrite(&SymboleTable[KeyWordNumber].NumberOfSubstitutions, 2+(sizeof (FileAddress)), 1, CompiledFile);
    }
}


void MyRead(void)
{
    fgets(work, sizeof work, SourceFile);
    work[strlen(work)-1]=0;
}

char FindWork[MaxKeyWordLength];

int Find(char *Text, int Length)
{
    int i;

    memcpy(FindWork, Text, Length);
    FindWork[Length]=0;
    for(i=0; i<NumKeyWords; i++)
        if(strcmp(FindWork, SymboleTable[i].KeyWord)==0)
            return i;
    printf("Key word \x22%s\x22 not found!\n\x07", FindWork);
    return 0;
}