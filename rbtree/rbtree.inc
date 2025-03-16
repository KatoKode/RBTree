;-------------------------------------------------------------------------------
;   Assembly Language Implementation of a (Red-Black) RBTree
;   Copyright (C) 2025  J. McIntosh
;
;   This program is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation; either version 2 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License along
;   with this program; if not, write to the Free Software Foundation, Inc.,
;   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
;-------------------------------------------------------------------------------
%ifndef RBTREE_INC
%define RBTREE_INC  1
;-------------------------------------------------------------------------------
; file:   rbtree.inc
; author: J. McIntosh
; brief:  red-black tree implementation
;-------------------------------------------------------------------------------
;
RB_BLACK        EQU     0x00
RB_RED          EQU     0xFF
;
;-------------------------------------------------------------------------------
;
struc rb_node
  .parent:      resq      1
  .left:        resq      1
  .right:       resq      1
  .data:        resq      1
  .color:       resb      1
endstruc
;
;-------------------------------------------------------------------------------
;
struc rb_tree
  .nil:         resq      1 
  .root:        resq      1
  .find_cb:     resq      1
  .nsrt_cb:     resq      1
  .term_cb:     resq      1
  .trav_cb:     resq      1
endstruc
;
%endif
