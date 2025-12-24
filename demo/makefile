#-------------------------------------------------------------------------------
#   Red-Black-Tree (RBTREE) Implementation in x86_64 Assembly Language with
#   C interface
#
#   Copyright (C) 2025  J. McIntosh
#
#   RBTREE is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   RBTREE is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with RBTREE; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#-------------------------------------------------------------------------------
# file: demo makefile
#-------------------------------------------------------------------------------
demo: main.o ../rbtree/librbtree.so ../util/libutil.so
	gcc -O3 -march=x86-64 -m64 -z noexecstack -pthread main.o ../rbtree/librbtree.so \
		../util/libutil.so -o demo
main.o: main.c
	gcc -O3 -march=x86-64 -m64 -Wall -c main.c -o main.o
.PHONY: clean
clean:
	rm -f demo main.o
