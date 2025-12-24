#-------------------------------------------------------------------------------
#   Red-Black-Tree Implementation in x86_64 Assembly Language with
#   C interface
#
#   Copyright (C) 2025  J. McIntosh
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#-------------------------------------------------------------------------------
#
librbtree.so: rbtree_asm.o rbtree.o
	gcc -O3 -march=x86-64 -m64 -z noexecstack -shared rbtree_asm.o rbtree.o -o librbtree.so
rbtree.o: rbtree.c
	gcc -O3 -march=x86-64 -m64 -Wall -fPIC -c rbtree.c -o rbtree.o
rbtree_asm.o: rbtree.asm
	nasm -O3 -f elf64 rbtree.asm -o rbtree_asm.o
.PHONY: clean
clean:
	rm -f librbtree.so rbtree.o
	rm -f rbtree_asm.o
