
---

(Red-Black) RB-Tree Implementation in x86_64 Assembly Language with C interface

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%202.0-blue.svg)](https://opensource.org/licenses/GPL-2.0)
[![Stars](https://img.shields.io/github/stars/KatoKode/RBTree?style=social)](https://github.com/KatoKode/RBTree/stargazers)

by Jerry McIntosh

---

# INTRODUCTION
This is an x86_64 Assembly language implementation of a Red-Black-Tree.  The Red-Black-Tree is implemented as a shared-library with a C interface.  There is also a C demo program.

The Red-Black-Tree implementaton is based on the implementation found in:

Introduction to Algorithms, 3rd ed.
by Cormen, Leiserson, Rivest, and Stein

---

## FEATURES
**Generic B-Tree Structure:

+ Separate comparison callbacks for full objects (nrst_cb) and keys to full objects (find_cb).
+ Key extraction callback (k_get_cb) for searching with keys only.
+ Object deletion callback (term_cb) for cleanup during removal/termination.
+ Tree traversal callback (trav_cb) for user supplied output of objects.

**Classic Red-Black Tree Implementation:**

+ Faithful to Cormen et al. (CLRS) pseudocode, using a single allocated sentinel node for simplified, efficient operations.
+ Full dynamic node allocation and cleanup via user-provided termination callback.

**Core Operations:**

+ Insertion with automatic rebalancing (rotations and recoloring).
+ Deletion by key with complete fixup (transplant, rotations, and case handling).
+ Search by key returning the matching node (or sentinel if not found).
+ In-order traversal via user-provided walk callback for verification or enumeration.

**Balancing Mechanisms:**

+ Left and right rotations implemented efficiently.
+ Insertion fixup with classic uncle/sibling cases.
+ Deletion fixup handling all symmetric cases, including double-black propagation and final recoloring.

**Performance Optimizations:**

+ All critical routines (insert, delete, delete_fixup, rotations, transplant, find) hand-written in x86-64 Assembly.
+ Tight, predictable control flow with minimal branching overhead.
+ Sentinel node eliminates null checks, enabling unconditional parent updates.
+ Stack-aligned calls to external functions and careful register preservation.

**Memory Management:**

+ Nodes dynamically allocated on demand.
+ Full tree termination recursively frees all nodes and invokes user cleanup on data.
+ Valgrind-clean: zero leaks or errors across 16.7M+ allocs/frees in stress tests.

**Single-Threaded Design:**

+ No locking — pure sequential performance focus.
+ Ideal for embedded, systems, or high-performance single-threaded use cases.

**Demo/Testing:**

+ Comprehensive demo performs ~8.39M random insertions and ~6.29M deletions.
+ Optional tree walks for ordering validation.
+ Proven scalable: ~41s average wall-clock for full benchmark runs, clean Valgrind, excellent perf metrics (2.72 IPC, low branch mispredicts).

---

## Performance Profile (perf)

On a modern x86-64 system, this hand-written assembly implementation of a red-black tree demonstrates excellent real-world performance. Across 10 runs performing 8,388,607 random insertions followed by 6,291,455 random deletions (75% of inserted nodes), the program consistently completed in an average wall-clock time of 40.97 seconds (min: 40.01s, max: 41.89s), with average user time of 30.55 seconds and system time of 10.48 seconds. These results highlight the efficiency of the low-level optimizations, tight rotation and fixup routines, and faithful CLRS-style sentinel-node design, delivering robust throughput even under millions of dynamic operations with full tree rebalancing.

---

## Valgrind-certified leak-free

### Run: A

Memcheck, a memory error detector
Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
Command: ./demo 62832110


HEAP SUMMARY:
    in use at exit: 0 bytes in 0 blocks
  total heap usage: 16,777,219 allocs, 16,777,219 frees, 603,983,980 bytes allocated
 
All heap blocks were freed -- no leaks are possible
 
ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)

### Run: B

Memcheck, a memory error detector
Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
Command: ./demo 11741663


HEAP SUMMARY:
    in use at exit: 0 bytes in 0 blocks
  total heap usage: 16,777,219 allocs, 16,777,219 frees, 603,983,980 bytes allocated

All heap blocks were freed -- no leaks are possible

ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)

### Run: C

Memcheck, a memory error detector
Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
Command: ./demo 28217687


HEAP SUMMARY:
    in use at exit: 0 bytes in 0 blocks
  total heap usage: 16,777,219 allocs, 16,777,219 frees, 603,983,980 bytes allocated

All heap blocks were freed -- no leaks are possible

ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)

---

## LIST OF REQUIREMENTS:
+ Linux OS
+ Programming languages: C and Assembly
+ Netwide Assembler (NASM), the GCC compiler, and the make utility
+ your favorite text editor
+ and working at the command line

---

# CREATE THE DEMO
Run the following command in the `Red-Black-Tree-main` folder:
```bash
sh rbtree_make.sh
```

---

# RUN THE DEMO
In folder `demo` enter the following command:
```bash
./go_demo.sh
```

---

# THINGS TO KNOW
You can modify a couple defines in the C header file `main.h`:
```c
#define DATA_COUNT    128
#define DELETE_COUNT    0
```
Modifying these defines will change the behavior of the demo program.

There are calls to `printf` in the `rbtree.asm` file.  They are for demo purposes only and can be removed or commented out.  The `printf` code sections are marked with comment lines: `BEGIN PRINTF`; and `END PRINTF`.  The format and text strings passed to `printf` are in the `.data` section of the `rbtree.asm` file.

Have Fun!

---
