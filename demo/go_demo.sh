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
# !/bin/sh
#
echo -e "\nRunning ./demo"
rnd=`shuf -i 10000000-99999999 -n 1`
./demo "${rnd}" > ./out.txt
echo -e "\nOutput in file ./out.txt\n"
read -r -p "View file ./out.txt [Y/n]: " YN
case ${YN:-Y} in
  'y'|'Y') less ./out.txt ;;
  'n'|'N') echo -e "\nExiting\n" ;;
  *) ;;
esac
