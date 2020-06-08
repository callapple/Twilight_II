
/*
** Ball, Release v1.0 - 19 July 1993.
** C Source Code - "Config.cc" - Source Support Segment
**
**  Routines here are mostly by Josef Wankerl (thanks Joe! & Diz :) & GS+
**  Suscribe to GS+; it's a great mag!
**
** Copyright 1993 DigiSoft Innovations, All Rights Reserved.
**
** Permission granted to use this source in any module designed for
**  Twilight II for the Apple IIGS.
*/

/*****************************************************************************\
|* LoadConfigResource-
|*  This function attempts to load a named rT2ModuleWord resource.  If
|*  the resource exists, the value of the rT2ModuleWord resource is	  
|*  returned, otherwise a default value is returned.				
\*****************************************************************************/

Word LoadConfigResource (char *Name, Word DefaultValue) {

	Word Result, fileID;
	Long rID;
	Handle ConfigData;
    struct {
        word Type;
        Long ID;
    } HandleInfo;


/* Attempt to load the named resource */

	rID = RMFindNamedResource((Word) rT2ModuleWord, (Ptr) Name, &fileID);

	ConfigData = LoadResource((Word) rT2ModuleWord, rID);
	if (toolerror ())
		Result = DefaultValue; /* Resource does not exist, so return the default value */
	else
   {
       HLock(ConfigData);  /* Resource exists, return the rT2Module word value */
		Result = **(word **)ConfigData;
		HUnlock(ConfigData);

		ReleaseResource(3, (Word) rT2ModuleWord, rID);
    }

	 return Result;
}



/*****************************************************************************\
|* SaveConfigResource-						
|*  This function takes a Word value and saves it as a rT2ModuleWord
|*	resource in the Twilight.Setup file.  The value is saved and a	
|*	name is added.  Any previous rT2ModuleWord with the same name is
|*	first removed before the new value is added.					
\*****************************************************************************/

void SaveConfigResource (char *Name, Word SaveValue) {

	Word FileID;
	Long ResourceID;
	Word **ConfigData;

/*  Check to see if the named resource already exists */

	ResourceID = RMFindNamedResource (rT2ModuleWord, Name, &FileID);
	if (!toolerror()) {
		char NullString = '\x000';

/* The resource already exists, so first remove the name from */
/*	the resource, then remove the resource itself  */

		RMSetResourceName (rT2ModuleWord, ResourceID, &NullString);
		RemoveResource (rT2ModuleWord, ResourceID);
	}

/* Create new handle for the future resource */

	ConfigData =
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, NULL);
	**ConfigData = SaveValue;

/* Find a new ID for the resource and add it */

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource ((Handle) ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle ((Handle) ConfigData);

	else {

/* Set the name of the resource if it was added correctly */

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
	}

}