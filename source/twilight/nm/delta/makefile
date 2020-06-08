object/deltac.root: delta.cc
 compile -t -e delta.cc Keep=object/deltac

object/deltaa.root: delta.asm
 compile -t -e delta.asm Keep=object/deltaa

delta: object/deltac.root object/deltaa.root
 link -x object/deltac object/deltaa Keep=delta
 chtyp -t exe delta

object/udeltac.root: udelta.cc
 compile -t -e udelta.cc Keep=object/udeltac

object/udeltaa.root: udelta.asm
 compile -t -e udelta.asm Keep=object/udeltaa

udelta: object/udeltac.root object/udeltaa.root
 link -x object/udeltac object/udeltaa Keep=udelta
 chtyp -t exe udelta
