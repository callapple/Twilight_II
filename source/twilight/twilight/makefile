*
* AV 202005 - An Orca/m makefile
*
*
* init things
*
prefix 22 /t2/export/twilight
*
* make Twilight II
*
compile +w blank.asm keep=o/blank
compile +w init.asm keep=o/init
compile +w beat.asm keep=o/beat
compile +w request.asm keep=o/request
compile +w ipc.asm keep=o/ipc
compile +w library.asm keep=o/library
link +w -x o/init o/beat o/request o/blank o/ipc o/library keep=o/init
*
* make the CDEV
*
compile +w cdev.asm keep=o/cdev
compile +w setup.asm keep=o/setup
compile +w misc.asm keep=o/misc
compile +w list.asm keep=o/list
link +w -x o/cdev o/setup o/misc o/list keep=o/cdev
*
* make the resources
*
compile tii.rez keep=Twilight.II rez=(-t $C7)
copy -C Twilight.II cdevs:Twilight.II
compile newboth.rez keep=Twilight.II rez=(-a -t $C7)
copy -C Twilight.II cdevs:Twilight.II
*
* Copy the version on my startup disk
*
copy -C cdevs:Twilight.II /systeme/system/cdevs/Twilight.II
