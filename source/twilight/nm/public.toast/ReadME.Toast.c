		Toast Twilight II Module
			v0.1b1, By Nathan Mates
What this is:
	This is a Freeware Demonstration of the Twilight II Toast Module. There are a number of known problems/limitations with this piece of software; most will be detailed below. This is PURELY an advance release in order to spark curiosity about the upcoming update to Twilight II v1.2, and get me some fan mail. :)

	IMPORTANT NOTICE: There are sample pictures for Fish and Globe included here. Do not try and view them using the toast module; they cannot be properly viewed. They are included simply as samples for the artwork contest (see below). In addition, Jim Maricondo (the programmer of the Twilight II CDev, and person I said to send all the artwork to) hasn’t given me any feedback on this yet at all. So, if there’s any problems, it‘s because this was done at the last moment, and it’s all my fault. Hopefully, I got all the contest details right.

	Basically, this is a module for Twilight II, so you must have Twilight II to be able to run this. After Christmas Vacation, I may make a GS/OS Application of Toast that does not require Twilight II, but don’t count on it. To install this module, simply copy the included Toast module (filename: “Toast”) into wherever you keep the other Twilight Modules (if you have a hard disk, this is probably in the Twilight folder in the CDevs folder in the System folder of your boot disk), and place the included picture file (filename: “ToastPix”) somewhere, preferably in the same folder as this module. Then, set up the Toast module, and tell it where your picture file is. (This is important!). Finally, test the Toast module and enjoy!

	After completing a Fish module (to be released with Twilight II 1.2) in about 8 hours, I decided to see exactly how long it would take me to do a Toast module. It only took about 30 minutes more, once the artwork was acquired. I have about 6 cool new modules for Twilight II v1.2, and I’ll only give the names as a teaser (Support the IIGS! Support Twilight II!): Fish, Flames, Globe, Spirals, Swirls, Toast, and maybe 1-2 more. :) I’ve got some ideas for 60fps 200 pt  graphics that’ll knock everyone’s socks off! 

	Note: DigiSoft Innovations is also seeking new effects for future versions of Twilight II.  We will pay for quality modules.  Contact us for more details.

Known Problems/Limitations
	Well, if you haven’t noticed yet, this is rather like “that other program’s” screen saver. It’d be real nice to release Twilight II v1.2 with this set of artwork, but they might get ticked off. Therefore, we’re having a contest for the best new original artwork for this and 2 other modules, see below.
	This is a beta version, so if there are any problems, that’s to be expected. I’ve tried this out on my system; it works, and that’s fine with me. If you run into any problems, feel free to contact me at the address below.
	Toast, at the moment, requires its artwork to be in a $C1 (one screen, unpacked) file. Since there are only 7 graphics frames, yes, this wastes a bit of disk space and all, but it’s much easier for me to handle these files. The formal release of Toast will support both $C1 pictures and standard APF ($C0/$0002) files. In the meantime, if you put the pictures on a ProDOS/GSOS disk, they will ”auto-sparse” the file, reducing it from 32K of disk space to about 21K. If you put this file on other media, such as HFS volumes, the picture file will use up 32K.
	Toast also only supports 320-mode pictures at the moment. You can tell it to display a 640-mode picture, but its colors will be off. This will change in the release.
	Toast really wants to have the “fast” SHR screen... The graphics are much smoother and nicer with that screen available. Most GS/OS programs, as long as there is enough memory, support and use the “fast” screen. If Twilight II is not in “Low Memory Mode” (see the setup screen), Toast will be able to use the “fast” screen. Certain programs, namely The Manager v1.0 (tm Seven Hills Software) deny programs the use of the fast screen. With the fast screen, everything is always in the same plane relative to everything else– if at one time one shape is in front of another, it will be ahead of that shape all the time. Without the fast screen available, objects will come to the foreground as they’re drawn, which can look ugly. I’ll try to make the slow screen drawing much smoother and all, but it will be at the expense of about 32K of memory....
	Toast may not have the best error checking yet. It does require that it be able to load its picture file into memory when it runs. Toast should therefore complain if it can’t find enough memory (32K in one chunk), and refuse to run. If it is told to display a bad file, or the file doesn’t exist, then it will most likely put some sort of garbage on the screen, but nothing worse than that. This will all be fixed for the release.
	Toast has no cute sound effects. Tough. Wait for the release version.
	Toast also doesn’t behave exactly like “that other” screen saver, in that shapes can be on top of others, and so on. Once again, the final version will support this.

Why we’re releasing this:
	I like just having this on my screen. But, the artwork is too reminiscent of “that other screen saver’s.” Therefore, Jim Maricondo (the author of the Twilight II CDev and some modules) and I decided to have a contest for the best original artwork. Basically, we’re looking for the coolest artwork that we could publish for Toast, Fish, and Globe, for Twilight II v1.2. All you have to do is submit your artwork, and adhere to the below rules.
	Note: Feel free to draw anything you want for the toast module; while we want some good toaster artwork, we also are looking for other objects for variety.

	As a teaser, here are the prizes. Since there are 3 contests (one each for Fish, Toast & Globe), there a unique set of winners and runner ups for each category.
Winner: $50 + Twilight II v1.2
Runner Up: Twilight II v1.2
Anything we decide to publish: Twilight II v1.2, additional module packages, etc.

For every five people that enter in a given category, the winner of that category will receive an additional $10 over the above amount.

Even if you don’t win, you still could have your name in print and get cool new software!

Here are the rules:
1. Sumbit all pictures to:
	DigiSoft Innovations
	P.O. Box 380
	Trumbull, CT 06611-0380
or, electronically, at
	America Online:  DigiSoft
	Delphi                  DYAJIM
	GEnie                  A2PRO.DYAJIM
      Internet: digisoft@aol.com or afcdyajim@aol.com

	If you want to submit electronically, it’s best to send some email first arranging the submission, so that we can specify how the file will be transmitted, and so forth. All disks sumbitted will become properties of DigiSoft Innovations. Include a stamped postcard or email address if you want us to confirm that we received your disk.

2. All entries must be received by February 14th, 1994. The contest will be judged, and the winners announced by February 28, 1994. Decisions of the judges are final.  Entries will be judged on characteristics including, but not limited to, originality, quality of artwork, and design. Entries MUST be original; we do not want any “ripped” pictures from other copyrighted software.  We reserve the right to extend or modify portions of this contest due to lack of participation.

3. Entries must be compatible with Fish, Toast and Globe. For Fish & Toast, this means that there must be a certain number of 32*40 pixel frames, and 16 colors only. Globe’s picture must be 140*60 pixels in size, and can be 16 or 256 colors. For examples of legitimate pictures, see the sample files included with this release of Toast. 

4. By sumbitting a picture, if you are selected, you agree to let your picture be released in any DigiSoft Innovations products.  All entries become the property of DigiSoft Innovations.

5. This contest is open to all who can submit, including DigiSoft members and associated programmers / staff.

6. Anything else I can’t think of at the moment. (Finals just finished here, and my brain’s not working too well)


Miscellaneous Guidelines for Pictures:
	For Globe, it should be a picture that looks nice when wrapped around a sphere. Yes, there is no way to see what Globe does to pictures at the moment, but if some quality sumbissions are received, DigiSoft will consider releasing a “tagged” beta of Globe to let individual authors see how things are going. Your picture mut fit within the 140*60 area, no more, no less. You can use 16-256 colors; NO 3200 color pictures.

	Toast and Fish both take pictures that consist of a certain # of 32*40 pixel frames. Each frame must fit in the specified cells exactly. One 16-color pallette is allowed. (There can be 20 shapes on one line; if they had different pallettes, it’d get really ugly).

	Let’s take a look at Toast’s pictures first: on the top line, there are 6 boxes, two of them X’d out. These are the four frams of animation for the first kind of shape. Basically, if we number those 4 shapes in order, 1, 2, 3, 4, the frames will be shown on the screen in this order: 1-2-3-4-3-2-1-2-3-4-3-2-..... and so on. The second row contains 3 pictures and 3 X’d out squares. Those 3 shapes are static shapes that will be put on the screen, unanimated. Just watch Toast if you have any problems.... Some ideas of my own (I can’t draw anything, so it’s up to you): Triplanes & (blimps/clouds/whatever). Cars & ?. People walking.... Whatever. I’m great at cloning other things, maybe not imaginational. There is a Toast viewer T2 module, so you can see immediately what your creations are like.

	Well, there’s a Fish screen here, but no fish viewer. Well, there’s a trick to check out some fish by using Toast. (The one remaining problem is that Fish move horizontally; Toast go diagonally). Each fish consists of only 2 frames, not four like Toast. Therefore, if you put the 2 frames, A & B into the Toast picture such that they go A B A B, Toast will play one frame, then the other, just like Fish does. Therefore, you can use this to test out how your fish look when animated. Fish also should be facing right in their picture file (otherwise they’ll appear to swim backwards), but Toast face left. That should be no problem whatsoever. There should be 15 types of fish, each having 2 frames, for a total of 30 frames. If you develop your fish using Toast to view them, you can then put them into the Fish picture. If some quality submissions are received, we will consider releaseing tagged Fish betas so you can actually see what things will look like.

	So, whip out that drawing program, and get started!

Legal stuff, etc.:
	Toast was written by Nathan Mates in 100% IIGS Assembly. This version is classified Freeware– you can freely distribute it, but not sell it. Future versions of this program will not be Freeware; I’m the author and can chose to have it sold as part of the Twilight II v1.2 package.
	The Toast beta may be distributed as long as the following conditions are met:
1. All of the files in this archive remain untouched: Toast [T2 module], Read.Toast.Tch [This file], ToastPix [pictures for Toast], FishPix [pictures for Fish], and a picture for Globe.
2. This archive (which can be unpacked) may not be sold. Permission is granted for online groups to make it a publically available download. This archive can be included on disk collections, so long as a charge of no more than $5 per disk is charged for distribution. Any other methods of distribution/modification must be cleard in advance with me.

	DigiSoft Innovations., Inc. makes no claims regarding suitability of this release for use with anything. Please report any problems encountered directly to the author. Void where prohibited or restricted by law. Blah blah blah.....

	Special Hellos go out to everyone on IRC: jsanford, B_Francis, RushServ, GSServ, Fever, Calamity, Mach, AutoMach (aka NickServ :), Bryer, Moet, Meekins, dwsSteve, Med, Janiee, and  everyone on comp.sys.apple2. If I forgot your name, ooops. Oh yeah,  no thanks to the people on IRC who constantly harsh on Twilight II: Abaddon (James Brookes), IRSMan (Ian Schmidt), and to a lesser degree, Bazyar (Da ’Waid :). “Except ye be nice to me, ye shall all likewise be dissed.”

How to contact me:
	Well, I’ve been a IIGS software author for some time now, and frankly speaking, the user support I’ve gotten stinks. In my other programs, I’ve asked for something, even just a letter / postcard, and what do I get? Diddly Squat. (Those of you who have sent things, thank you from the bottom of my heart. It‘s just that the number of responses that I get in relation to the total number of copies that must be floating around is pretty darn small). This is Freeware, but you are not disallowed to send me praises, complaints, whatever just so that I know you’re out there and alive. If you really want to help support a IIGS author, you can check out my other IIGS programs (GameHacker, Mine Hunt, Multi Tris, Power Grid) and send in the shareware fees for a few of them.........

	To get in contact with me, you can do it either by U.S. mail or electronically. My address is:

	Nathan Mates
	MSC #850, Caltech
	Pasadena, CA 91126-0001

	or, on the internet:    nathan@cco.caltech.edu

	(There are gateways from other online services (Compuserve, Genie, AOL, Delphi, and others) to the internet so ask a local expert if you want to send email from the non-internet).

	I’ll be away from Caltech from December 12th to the 29th, just as a word of warning. (Don’t expect an immediate reponse if you send mail during that time).


	Have fun, and APPLE II FOREVER!
Nathan Mates. 12/10/93 17:52
