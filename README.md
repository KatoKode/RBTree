


Just Another Armchair Programmer

(Red-Black) RB-Tree Implementation in x86_64 Assembly Language with C interface

by Jerry McIntosh
# INTRODUCTION
This is an Assembly Language implementation of a (Red-Black) RB-Tree.  The (Red-Black) RB-Tree is implemented as a shared-library with a C interface.  There is also a C demo program.

The (Red-Black) RB-Tree implementaton is based on the implementation found in:

Introduction to Algorithms, 3rd ed.
by Cormen, Leiserson, Rivest, and Stein

LIST OF REQUIREMENTS:

+ Linux OS
+ Programming languages: C and Assembly
+ Netwide Assembler (NASM), the GCC compiler, and the make utility
+ your favorite text editor
+ and working at the command line

FILE STRUCTURE:

util/
+ memmove64.asm
+ util.h
+ util.c
+ makefile

rbtree/
+ rbtree.asm
+ rbtree.inc
+ rbtree.h
+ rbtree.c
+ makefile

rbtest/
+ main.h
+ main.c
+ makefile
+ go_rbtest.sh
# CREATE THE DEMO WITH THE MAKE UTILITY:
Run the following command in the `Red-Black-Tree-main` folder:
```bash
sh rbtree_make.sh
```
# RUN THE DEMO:
In folder `rbtest` enter the following command:
```bash
./go_rbtest.sh
```
# THINGS TO KNOW:
You can modify a couple defines in the C header file `main.h`:
```c
#define DATA_COUNT    128
#define DELETE_COUNT    0
```
Modifying these defines will change the behavior of the demo program.

There are calls to `printf` in the `rbtree.asm` file.  They are for demo purposes only and can be removed or commented out.  The `printf` code sections are marked with comment lines: `BEGIN PRINTF`; and `END PRINTF`.  The format and text strings passed to `printf` are in the `.data` section of the `btree.asm` file.

Have Fun!
