;-------------------------------------------------------------------------------
;   Red-Black-Tree (RBTREE) Implementation in x86_64 Assembly Language with
;   C interface
;
;   Copyright (C) 2025  J. McIntosh
;
;   RBTREE is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation; either version 2 of the License, or
;   (at your option) any later version.
;
;   RBTREE is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License along
;   with RBTREE; if not, write to the Free Software Foundation, Inc.,
;   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
;-------------------------------------------------------------------------------
;
%ifndef RBTREE_ASM
%define RBTREE_ASM  1
;
;-------------------------------------------------------------------------------
;
extern free
extern printf
extern null_node
;
;-------------------------------------------------------------------------------
;
ALIGN_SIZE    EQU     16
ALIGN_WITH    EQU     (ALIGN_SIZE - 1)
ALIGN_MASK    EQU     ~(ALIGN_WITH)
;
%macro ALIGN_STACK_AND_CALL 2-4
      mov     %1, rsp               ; backup stack pointer (rsp)
      and     rsp, QWORD ALIGN_MASK ; align stack pointer (rsp) to
                                    ; 16-byte boundary
      call    %2 %3 %4              ; call C function
      mov     rsp, %1               ; restore stack pointer (rsp)
%endmacro
;
; Example: Call LIBC function
;         ALIGN_STACK_AND_CALL r15, calloc, wrt, ..plt
;
; Example: Call C callback function with address in register (rcx)
;         ALIGN_STACK_AND_CALL r12, rcx
;-------------------------------------------------------------------------------
;
%include "rbtree.inc"
;
section .data
      hdr01       db      "rb_delete",0
      hdr02       db      "rb_delete_fixup",0
      hdr03       db      "rb_find",0
      hdr04       db      "rb_find_rcrs",0
      hdr05       db      "rb_insert",0
      hdr06       db      "rb_insert_fixup",0 
      hdr07       db      "rb_left_rotate",0
      hdr08       db      "rb_node_init",0
      hdr09       db      "rb_right_rotate",0
      hdr10       db      "rb_term_rcrs",0
      hdr11       db      "rb_transplant",0
      hdr12       db      "rb_traverse",0
      hdr13       db      "rb_tree_init",0
      hdr14       db      "rb_tree_minimum",0
      hdr15       db      "rb_tree_term",0
      hdr16       db      "rb_walk",0
      fmt         db      "---| %s |---",10,0
;
section .text
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_transplant (rb_tree_t *tree, rb_node_t *node_n, rb_node_t *node_o);
;
; param:
;
;   rdi = tree
;   rsi = node_n
;   rdx = node_o
;-------------------------------------------------------------------------------
;
      static rb_transplant
rb_transplant:
; BEGIN PRINTF
; printf(fmt, hdr11);
      push      rdx
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr11
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
      pop       rdx
; END PRINTF
; if (node_n->parent == tree->nil)
      mov       rcx, QWORD [rdi + rb_tree.nil]
      cmp       QWORD [rsi + rb_node.parent], rcx
      jne       .else_if
;   tree->root = node_o;
      mov       QWORD [rdi + rb_tree.root], rdx
      jmp       .cont
.else_if:
; else if (node_n == node_n->parent->left)
      mov       rcx, QWORD [rsi + rb_node.parent]
      cmp       rsi, QWORD [rcx + rb_node.left]
      jne       .else
;   node_n->parent->left = node_o;
      mov       QWORD [rcx + rb_node.left], rdx
      jmp       .cont
.else:
; else node_n->parent->right = node_o;
      mov       QWORD [rcx + rb_node.right], rdx
.cont:
; node_o->parent = node_n->parent;
      mov       QWORD [rdx + rb_node.parent], rcx
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   rb_node_t * rb_tree_minimum (rb_tree_t *tree, rb_node_t *node);
;
; param:
;
;   rdi = tree
;   rsi = node
;-------------------------------------------------------------------------------
;
      static rb_tree_minimum
rb_tree_minimum:
; BEGIN PRINTF
; printf(fmt, hdr14);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr14
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; while (node->left != tree->nil)
      mov       rax, QWORD [rdi + rb_tree.nil]
.loop:
      cmp       QWORD [rsi + rb_node.left], rax
      je        .return
;   node = node->left;
      mov       rsi, QWORD [rsi + rb_node.left]
      jmp       .loop
.return:
; return node;
      mov       rax, rsi
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_left_rotate (rb_tree_t *tree, rb_node_t *node);
;
; param:
;
;   rdi = tree
;   rsi = node
;-------------------------------------------------------------------------------
;
      static rb_left_rotate
rb_left_rotate:
; BEGIN PRINTF
; printf(fmt, hdr07);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr07
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; rb_node_t *node_y = node->right;
      mov       rax, QWORD [rsi + rb_node.right]
; node->right = node_y->left;
      mov       rcx, QWORD [rax + rb_node.left]
      mov       QWORD [rsi + rb_node.right], rcx
; if (node_y->left != tree->nil)
      mov       rdx, QWORD [rdi + rb_tree.nil]
      cmp       rcx, rdx
      je        .end_if
;   node_y->left->parent = node;
      mov       QWORD [rcx + rb_node.parent], rsi
.end_if:
; node_y->parent = node->parent;
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       QWORD [rax + rb_node.parent], rcx
; if (node->parent == tree->nil)
      cmp       rcx, rdx
      jne       .else_if
;   tree->root = node_y;
      mov       QWORD [rdi + rb_tree.root], rax
      jmp       .end_if_2
.else_if:
; else if (node == node->parent->left)
      cmp       rsi, QWORD [rcx + rb_node.left]
      jne       .else
;   node->parent->left = node_y;
      mov       QWORD [rcx + rb_node.left], rax
      jmp       .end_if_2
.else:
;  else node->parent->right = node_y;
      mov       QWORD [rcx + rb_node.right], rax
.end_if_2:
;  node_y->left = node;
      mov       QWORD [rax + rb_node.left], rsi
;  node->parent = node_y;
      mov       QWORD [rsi + rb_node.parent], rax
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_right_rotate (rb_tree_t *tree, rb_node_t *node);
;
; param:
;
;   rdi = tree
;   rsi = node
;-------------------------------------------------------------------------------
;
      static rb_right_rotate
rb_right_rotate:
; BEGIN PRINTF
; printf(fmt, hdr09);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr09
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; rb_node_t *node_y = node->left;
      mov       rax, QWORD [rsi + rb_node.left]
; node->left = node_y->right;
      mov       rcx, QWORD [rax + rb_node.right]
      mov       QWORD [rsi + rb_node.left], rcx
; if (node_y->right != tree->nil)
      mov       rdx, QWORD [rdi + rb_tree.nil]
      cmp       rcx, rdx
      je        .end_if
;   node_y->right->parent = node;
      mov       QWORD [rcx + rb_node.parent], rsi
.end_if:
; node_y->parent = node->parent;
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       QWORD [rax + rb_node.parent], rcx
; if (node->parent == tree->nil)
      cmp       rcx, rdx
      jne       .else_if
;   tree->root = node_y;
      mov       QWORD [rdi + rb_tree.root], rax
      jmp       .end_if_2
.else_if:
; else if (node == node->parent->right)
      cmp       rsi, QWORD [rcx + rb_node.right]
      jne       .else
;   node->parent->right = node_y;
      mov       QWORD [rcx + rb_node.right], rax
      jmp       .end_if_2
.else:
; else node->parent->left = node_y;
      mov       QWORD [rcx + rb_node.left], rax
.end_if_2:
; node_y->right = node;
      mov       QWORD [rax + rb_node.right], rsi
; node->parent = node_y;
      mov       QWORD [rsi + rb_node.parent], rax
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_delete_fixup (rb_tree_t *tree, rb_node_t *n);
;
; param:
;
;   rdi = tree
;   rsi = node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (tree)
;   QWORD [rbp - 16]  = rsi (node)
;   QWORD [rbp - 24]  = (rb_node_t *node_w)
;-------------------------------------------------------------------------------
;
      static rb_delete_fixup
rb_delete_fixup:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
; QWORD [rbp - 8] = rdi (tree)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (node)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr02);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr02
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; while (node != tree->root && node->color == RB_BLACK) {
.loop:
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 16]
      cmp       rsi, QWORD [rdi + rb_tree.root]
      je        .epilogue
      xor       edx, edx
      mov       dl, BYTE [rsi + rb_node.color]
      cmp       dl, BYTE RB_BLACK
      jne       .epilogue
;   if (node == node->parent->left) {
      mov       rcx, QWORD [rsi + rb_node.parent]
      cmp       rsi, QWORD [rcx + rb_node.left]
      jne       .else_1
;     node_w = node->parent->right;
      mov       rax, QWORD [rcx + rb_node.right]
      mov       QWORD [rbp - 24], rax
;     if (node_w->color == RB_RED) {
      mov       dl, BYTE [rax + rb_node.color]
      cmp       dl, BYTE RB_RED
      jne       .end_if_1
;       node_w->color = RB_BLACK;
      mov       dl, RB_BLACK
      mov       BYTE [rax + rb_node.color], dl
;       node_n->parent->color = RB_RED;
      mov       dl, RB_RED
      mov       BYTE [rcx + rb_node.color], dl
;       left_rotate(tree, node->parent);
      mov       rsi, rcx
      call      rb_left_rotate
;       node_w = node->parent->right;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rcx + rb_node.right]
      mov       QWORD [rbp - 24], rax
.end_if_1:
;     }
;     if (node_w->left->color == RB_BLACK && node_w->right->color == RB_BLACK) {
      mov       dl, BYTE RB_BLACK
      mov       rcx, QWORD [rax + rb_node.left]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .else_2
      mov       rcx, QWORD [rax + rb_node.right]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .else_2
;       node_w->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       BYTE [rax + rb_node.color], dl
;       node = node->parent;
      mov       rsi, QWORD [rsi + rb_node.parent]
      mov       QWORD [rbp - 16], rsi
      jmp       .loop
.else_2:
;     } else {
;       if (node_w->right->color == RB_BLACK) {
      mov       dl, BYTE RB_BLACK
      mov       rcx, QWORD [rax + rb_node.right]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .end_if_2
;         node_w->left->color = RB_BLACK;
      mov       rcx, QWORD [rax + rb_node.left]
      mov       BYTE [rcx + rb_node.color], dl
;         node_w->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       BYTE [rax + rb_node.color], dl
;         right_rotate(tree, node_w);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      call      rb_right_rotate
;         node_w = node->parent->right;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rcx + rb_node.right]
      mov       QWORD [rbp - 24], rax
.end_if_2:
;       }
;       node_w->color = node->parent->color;
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       dl, BYTE [rcx + rb_node.color]
      mov       BYTE [rax + rb_node.color], dl
;       node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       BYTE [rcx + rb_node.color], dl
;       left_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rcx
      call      rb_left_rotate
;       node = tree->root;
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rdi + rb_tree.root]
      mov       QWORD [rbp - 16], rsi
      jmp       .loop
;     }
.else_1:
;   } else {
;     node_w = node->parent->left;
      mov       rax, QWORD [rcx + rb_node.left]
      mov       QWORD [rbp - 24], rax
;     if (node_w->color == RB_RED) {
      mov       dl, BYTE [rax + rb_node.color]
      cmp       dl, BYTE RB_RED
      jne       .end_if_3
;       node_w->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       BYTE [rax + rb_node.color], dl
;       node->parent->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       BYTE [rcx + rb_node.color], dl
;       right_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rcx
      call      rb_right_rotate
;       node_w = node->parent->left;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rcx + rb_node.left]
      mov       QWORD [rbp - 24], rax
.end_if_3:
;     }
;     if (node_w->right->color == RB_BLACK && node_w->left->color == RB_BLACK) {
      mov       dl, BYTE RB_BLACK
      mov       rcx, QWORD [rax + rb_node.right]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .else_3
      mov       rcx, QWORD [rax + rb_node.left]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .else_3
;       node_w->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       BYTE [rax + rb_node.color], dl
;       node = node->parent;
      mov       rsi, QWORD [rsi + rb_node.parent]
      mov       QWORD [rbp - 16], rsi
      jmp       .loop
.else_3:
;     } else {
;       if (node_w->left->color == RB_BLACK) {
      mov       dl, BYTE RB_BLACK
      mov       rcx, QWORD [rax + rb_node.left]
      cmp       BYTE [rcx + rb_node.color], dl
      jne       .end_if_4
;         node_w->right->color = RB_BLACK;
      mov       rcx, QWORD [rax + rb_node.right]
      mov       BYTE [rcx + rb_node.color], dl
;         node_w->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       BYTE [rax + rb_node.color], dl
;         left_rotate(tree, node_w);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      call      rb_left_rotate
;         node_w = node->parent->left;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rcx + rb_node.left]
      mov       QWORD [rbp - 24], rax
.end_if_4:
;       }
;       node_w->color = node->parent->color;
      mov       rcx, QWORD [rsi + rb_node.parent]
      mov       dl, BYTE [rcx + rb_node.color]
      mov       BYTE [rax + rb_node.color], dl
;       node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       BYTE [rcx + rb_node.color], dl
;       right_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rcx
      call      rb_right_rotate
;       node = tree->root;
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rdi + rb_tree.root]
      mov       QWORD [rbp - 16], rsi
      jmp       .loop
;     }
;   }
; }
; node->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       rsi, QWORD [rbp - 16]
      mov       BYTE [rsi + rb_node.color], dl
.epilogue:
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_delete (rb_tree_t *tree, uint64_t key);
;
; param:
;
;   rdi = tree
;   rdx = key
;
; return:
;
; rax = &(matched node) | &null_node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (tree)
;   QWORD [rbp - 16]  = rsi (key)
;   QWORD [rbp - 24]  = (rb_node_t *node_n)
;   QWORD [rbp - 32]  = (rb_node_t *node_x)
;   QWORD [rbp - 40]  = (rb_node_t *node_y)
;   QWORD [rbp - 44]  = (int y_original_color)
;-------------------------------------------------------------------------------
;
      global rb_delete:function
rb_delete:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 44
      push      r12
; QWORD [rbp - 8] = rdi (tree)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (key)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr01);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr01
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; if ((node_n = rb_find(tree, key)) == NULL) return;
      call      rb_find
      test      rax, rax
      jz        .epilogue
      mov       QWORD [rbp - 24], rax
; tree->term_cb(node_n->data);    // user callback on data
      mov       rdi, QWORD [rbp - 8]
      mov       rcx, QWORD [rdi + rb_tree.term_cb]
      mov       rdi, QWORD [rax + rb_node.data]
      ALIGN_STACK_AND_CALL r12, rcx
; rb_node_t *node_x = NULL
      xor       rax, rax
      mov       QWORD [rbp - 32], rax
; rb_node_t *node_y = node_n
      mov       rax, QWORD [rbp - 24]
      mov       QWORD [rbp - 40], rax
; int y_original_color = node_y->color
      xor       edx, edx
      mov       dl, BYTE [rax + rb_node.color]
      mov       DWORD [rbp - 44], edx
; if (node_n->left == tree->nil) {
      mov       rdi, QWORD [rbp - 8]
      mov       rdx, QWORD [rdi + rb_tree.nil]
      cmp       QWORD [rax + rb_node.left], rdx
      jne       .else_if
;   node_x = node_n->left;
      mov       rcx, QWORD [rax + rb_node.left]
      mov       QWORD [rbp - 32], rcx
;   rb_transplant(tree, node_n, node_n->right)
      mov       rsi, rax
      mov       rdx, QWORD [rax + rb_node.right]
      call      rb_transplant
      jmp       .cont_1
.else_if:
; } else if (node_n->right == tree->nil) {
      mov       rdx, QWORD [rdi + rb_tree.nil]
      cmp       QWORD [rax + rb_node.right], rdx
      jne       .else_1
;   node_x = node_n->left;
      mov       rdx, QWORD [rax + rb_node.left]
      mov       QWORD [rbp - 32], rdx
;   rb_transplant(tree, node_n, node_n->left)
      mov       rsi, rax
      call      rb_transplant
      jmp       .cont_1
.else_1:
; } else {
;   node_y = rb_tree_minimum(tree, node_n->right)
      mov       rsi, QWORD [rax + rb_node.right]
      call      rb_tree_minimum
      mov       QWORD [rbp - 40], rax
;   y_original_color = node_y->color
      xor       edx, edx
      mov       dl, BYTE [rax + rb_node.color]
      mov       DWORD [rbp - 44], edx
;   node_x = node_y->right
      mov       rcx, QWORD [rax + rb_node.right]
      mov       QWORD [rbp - 32], rcx
;   if (node_y != node_n->right) {
      mov       rcx, QWORD [rbp - 24]
      cmp       rax, QWORD [rcx + rb_node.right]
      je        .else_2
;     rb_transplant(tree, node_y, node_y->right)
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      mov       rdx, QWORD [rax + rb_node.right]
      call      rb_transplant
;     node_y->right = node_n->right
      mov       rcx, QWORD [rbp - 24]
      mov       rcx, QWORD [rcx + rb_node.right]
      mov       rax, QWORD [rbp - 40]
      mov       QWORD [rax + rb_node.right], rcx
;     node_y->right->parent = node_y
      mov       QWORD [rcx + rb_node.parent], rax
      jmp       .cont_2
.else_2:
;   } else node_x->parent = node_y
      mov       rcx, QWORD [rbp - 32]
      mov       QWORD [rcx + rb_node.parent], rax
.cont_2:
;   rb_transplant(tree, node_n, node_y)
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 24]
      mov       rdx, rax
      call      rb_transplant
;   node_y->left = node_n->left
      mov       rcx, QWORD [rbp - 24]
      mov       rcx, QWORD [rcx + rb_node.left]
      mov       rax, QWORD [rbp - 40]
      mov       QWORD [rax + rb_node.left], rcx
;   node_y->left->parent = node_y
      mov       rcx, QWORD [rax + rb_node.left]
      mov       QWORD [rcx + rb_node.parent], rax
;   node_y->color = node_n->color
      mov       rcx, QWORD [rbp - 24]
      mov       dl, BYTE [rcx + rb_node.color]
      mov       BYTE [rax + rb_node.color], dl
; }
.cont_1:
; if (y_original_color == RB_BLACK)
      mov       edx, DWORD [rbp - 44]
      cmp       dl, BYTE RB_BLACK
      jne       .cont_3
;   delete_fixup(tree, node_x)
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 32]
      call      rb_delete_fixup
.cont_3:
; free(node_n);    // free memory of deleted node
      mov       rdi, QWORD [rbp - 24]
      ALIGN_STACK_AND_CALL r12, free, wrt, ..plt
.epilogue:
      pop       r12
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   rb_node_t * rb_find_rcsr (rb_node_t *node,
;                             rb_find_cb find_cb,
;                             void const *key);
;
; param:
;
;   rdi = node
;   rsi = find_cb
;   rdx = key
;
; return:
;
;   rax = &(matched node) | &null_node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (node)
;   QWORD [rbp - 16]  = rsi (find_cb)
;   QWORD [rbp - 24]  = rdx (key)
;-------------------------------------------------------------------------------
;
      static rb_find_rcrs
rb_find_rcrs:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
      push      r12
; QWORD [rbp - 8] = rdi (node)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (find_cb)
      mov       QWORD [rbp - 16], rsi
; QWORD [rbp - 24] = rdx (key)
      mov       QWORD [rbp - 24], rdx
; BEGIN PRINTF
; printf(fmt, hdr04);
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr04
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 16]
      mov       rdx, QWORD [rbp - 24]
; END PRINTF
; if (node == &null_node || find_cb(node->data, key) == 0) return node
      mov       rax, null_node wrt ..sym
      cmp       rdi, rax
      je        .epilogue
      mov       rdi, QWORD [rdi + rb_node.data]
      mov       rcx, rsi
      mov       rsi, rdx
      ALIGN_STACK_AND_CALL r12, rcx
      test      eax, eax
      jz        .match
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.left]
      test      eax, eax
      js        .continue
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.right]
.continue:
      mov       rsi, QWORD [rbp - 16]
      mov       rdx, QWORD [rbp - 24]
      call      rb_find_rcrs
      jmp       .epilogue
.match:
      mov       rax, QWORD [rbp - 8]
.epilogue:
      pop       r12
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   rb_node_t * rb_find (rb_tree_t *tree, void const *key);
;
; param:
;
;   rdi = tree
;   rsi = key
;
; return:
;
;   rax = &(matched node) | NULL
;-------------------------------------------------------------------------------
;
      global rb_find:function
rb_find:
; BEGIN PRINTF
; printf(fmt, hdr03);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr03
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; if (((rax) = rb_find_rcrs (tree->root, tree->find_cb, key)) == &null_node)
      mov       rdx, rsi
      mov       rsi, QWORD [rdi + rb_tree.find_cb]
      mov       rdi, QWORD [rdi + rb_tree.root]
      call      rb_find_rcrs
      mov       rdx, null_node wrt ..sym
      cmp       rax, rdx
      jne       .return
;   return NULL;
      xor       rax, rax
.return:
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_tree_init (rb_tree_t *tree,
;               rb_find_cb find_cb,
;               rb_nsrt_cb nsrt_cb,
;               rb_term_cb term_cb,
;               rb_trav_cb trav_cb);
;
; param:
;
;   rdi = tree
;   rsi = find_cb
;   rdx = nsrt_cb
;   rcx = term_cb
;   r8  = trav_cb
;-------------------------------------------------------------------------------
;
      global rb_tree_init:function
rb_tree_init:
      mov       rax, null_node wrt ..sym
      mov       QWORD [rdi + rb_tree.nil], rax
      mov       QWORD [rdi + rb_tree.root], rax
      mov       QWORD [rdi + rb_tree.find_cb], rsi
      mov       QWORD [rdi + rb_tree.nsrt_cb], rdx
      mov       QWORD [rdi + rb_tree.term_cb], rcx
      mov       QWORD [rdi + rb_tree.trav_cb], r8
; BEGIN PRINTF
; printf(fmt, hdr13);
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr13
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
; END PRINTF
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_insert_fixup (rb_tree_t *tree, rb_node_t *node);
;
; param:
;
;   rdi = tree
;   rsi = node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (tree)
;   QWORD [rbp - 16]  = rsi (node)
;   QWORD [rbp - 24]  = (rb_node_t *node_y)
;-------------------------------------------------------------------------------
;
      static rb_insert_fixup
rb_insert_fixup:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
; QWORD [rbp - 8] = rdi (tree)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (n)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr06);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr06
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; while (node->parent->color == RB_RED) {
.loop:
      mov       rsi, QWORD [rbp - 16]
      mov       rax, QWORD [rsi + rb_node.parent]
      mov       dl, BYTE [rax + rb_node.color]
      cmp       dl, BYTE RB_RED
      jne       .cont_1
;   if (node->parent == node->parent->parent->left) {
      mov       rcx, QWORD [rax + rb_node.parent]
      mov       rcx, QWORD [rcx + rb_node.left]
      cmp       rax, rcx
      jne       .else_1
;     rb_node_t *node_y = node->parent->parent->right;
      mov       rcx, QWORD [rax + rb_node.parent]
      mov       rcx, QWORD [rcx + rb_node.right]
      mov       QWORD [rbp - 24], rcx
;     if (node_y->color == RB_RED) {
      mov       dl, BYTE [rcx + rb_node.color]
      cmp       dl, BYTE RB_RED
      jne       .else_2
;       node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       BYTE [rax + rb_node.color], RB_BLACK
;       node_y->color = RB_BLACK;
      mov       BYTE [rcx + rb_node.color], dl
;       node->parent->parent->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       rcx, QWORD [rax + rb_node.parent]
      mov       BYTE [rcx + rb_node.color], dl
;       node = node->parent->parent;
      mov       QWORD [rbp - 16], rcx
      jmp       .loop
;     } else {
.else_2:
;       if (node == node->parent->right) {
      mov       rsi, QWORD [rbp - 16]
      mov       rax, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rax + rb_node.right]
      cmp       rsi, rax
      jne       .cont_2
;         node = node->parent;
      mov       rsi, QWORD [rsi + rb_node.parent]
      mov       QWORD [rbp - 16], rsi
;         rb_left_rotate(tree, node);
      mov       rdi, QWORD [rbp - 8]
      call      rb_left_rotate
;        }
.cont_2:
;        node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       rax, QWORD [rsi + rb_node.parent]
      mov       BYTE [rax + rb_node.color], dl
;        node->parent->parent->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       rax, QWORD [rax + rb_node.parent]
      mov       BYTE [rax + rb_node.color], dl
;        rb_right_rotate(tree, node->parent->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      call      rb_right_rotate
      jmp       .loop
;     }
;   } else {
.else_1:
;     rb_node_t *node_y = node->parent->parent->left;
      mov       rcx, QWORD [rax + rb_node.parent]
      mov       rcx, QWORD [rcx + rb_node.left]
      mov       QWORD [rbp - 24], rcx
;     if (node_y->color == RB_RED) {
      mov       dl, BYTE [rcx + rb_node.color]
      cmp       dl, BYTE RB_RED
      jne       .else_3
;       node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       BYTE [rax + rb_node.color], RB_BLACK
;       node_y->color = RB_BLACK;
      mov       BYTE [rcx + rb_node.color], dl
;       node->parent->parent->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       rcx, QWORD [rax + rb_node.parent]
      mov       BYTE [rcx + rb_node.color], dl
;       node = node->parent->parent;
      mov       QWORD [rbp - 16], rcx
      jmp       .loop
;     } else {
.else_3:
;       if (node == node->parent->left) {
      mov       rsi, QWORD [rbp - 16]
      mov       rax, QWORD [rsi + rb_node.parent]
      mov       rax, QWORD [rax + rb_node.left]
      cmp       rsi, rax
      jne       .cont_3
;         node = node->parent;
      mov       rsi, QWORD [rsi + rb_node.parent]
      mov       QWORD [rbp - 16], rsi
;         rb_right_rotate(tree, node);
      mov       rdi, QWORD [rbp - 8]
      call      rb_right_rotate
;       }
.cont_3:
;       node->parent->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       rax, QWORD [rsi + rb_node.parent]
      mov       BYTE [rax + rb_node.color], dl
;       node->parent->parent->color = RB_RED;
      mov       dl, BYTE RB_RED
      mov       rax, QWORD [rax + rb_node.parent]
      mov       BYTE [rax + rb_node.color], dl
;       rb_left_rotate(tree, node->parent->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      call      rb_left_rotate
      jmp       .loop
;     }
;   }
; }
.cont_1:
; tree->root->color = RB_BLACK;
      mov       dl, BYTE RB_BLACK
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_tree.root]
      mov       BYTE [rdi + rb_node.color], dl
; epilogue
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_insert (rb_tree_t *tree, rb_node_t *node);
;
; param:
;
;   rdi = tree
;   rsi = node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (tree)
;   QWORD [rbp - 16]  = rsi (node)
;   QWORD [rbp - 24]  = (rb_node_t *node_x)
;   QWORD [rbp - 32]  = (rb_node_t *node_y)
;-------------------------------------------------------------------------------
;
      global rb_insert:function
rb_insert:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 32
      push      r12
; QWORD [rbp - 8]  = rdi (tree)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (n)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr05);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr05
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; rb_node_t *node_x = tree->root
      mov       rax, QWORD [rdi + rb_tree.root]
      mov       QWORD [rbp - 24], rax
; rb_node_t *node_y = tree->nil
      mov       rcx, QWORD [rdi + rb_tree.nil]
      mov       QWORD [rbp - 32], rcx
; while (node_x != tree->nil) {
.loop:
      cmp       rax, rcx
      je        .cont_1
;   node_y = node_x;
      mov       QWORD [rbp - 32], rax
;   if (tree->nsrt_cb(n->data, node_x->data) < 0)
      mov       rdx, [rdi + rb_tree.nsrt_cb]
      mov       rdi, QWORD [rbp - 16]
      mov       rdi, [rdi + rb_node.data]
      mov       rsi, [rax + rb_node.data]
      ALIGN_STACK_AND_CALL r12, rdx
      test      eax, eax
      jns       .else_1
;     node_x = node_x->left;
      mov       rax, QWORD [rbp - 24]
      mov       rax, QWORD [rax + rb_node.left]
      mov       QWORD [rbp - 24], rax
      jmp       .loop_cont
.else_1:
;   else node_x = node_x->right;
      mov       rax, QWORD [rbp - 24]
      mov       rax, QWORD [rax + rb_node.right]
      mov       QWORD [rbp - 24], rax
.loop_cont:
      mov       rdi, QWORD [rbp - 8]
      mov       rcx, QWORD [rdi + rb_tree.nil]
      jmp       .loop
; }
.cont_1:
; node->parent = node_y;
      mov       rcx, QWORD [rbp - 32]
      mov       rsi, QWORD [rbp - 16]
      mov       QWORD [rsi + rb_node.parent], rcx
; if (node_y == tree->nil)
      mov       rdx, QWORD [rdi + rb_tree.nil]
      cmp       rcx, rdx
      jne       .else_if
;   tree->root = node;
      mov       QWORD [rdi + rb_tree.root], rsi
      jmp       .cont_2
.else_if:
;  else if (tree->nsrt_cb(node->data, node_y->data) < 0)
      mov       rdx, [rdi + rb_tree.nsrt_cb]
      mov       rdi, QWORD [rbp - 16]
      mov       rdi, [rdi + rb_node.data]
      mov       rsi, [rcx + rb_node.data]
      ALIGN_STACK_AND_CALL r12, rdx
      test      eax, eax
      jns       .else_2
;    node_y->left = node;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rbp - 32]
      mov       QWORD [rcx + rb_node.left], rsi
      jmp       .cont_2
.else_2:
;  else node_y->right = node;
      mov       rsi, QWORD [rbp - 16]
      mov       rcx, QWORD [rbp - 32]
      mov       QWORD [rcx + rb_node.right], rsi
.cont_2:
;  node->left = tree->nil;
      mov       rdi, QWORD [rbp - 8]
      mov       rcx, QWORD [rdi + rb_tree.nil]
      mov       QWORD [rsi + rb_node.left], rcx
;  node->right = tree->nil;
      mov       QWORD [rsi + rb_node.right], rcx
;  node->color = RB_RED;
      mov       al, BYTE RB_RED
      mov       BYTE [rsi + rb_node.color], al
;  rb_insert_fixup(tree, node);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 16]
      call      rb_insert_fixup
; epilogue
      pop       r12
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_node_init (rb_node_t *node, void const *data);
;
; param:
;
;   rdi = node
;   rsi = data
;-------------------------------------------------------------------------------
;
      global rb_node_init:function
rb_node_init:
      xor       rax, rax
      mov       QWORD [rdi + rb_node.parent], rax
      mov       QWORD [rdi + rb_node.left], rax
      mov       QWORD [rdi + rb_node.right], rax
      mov       QWORD [rdi + rb_node.data], rsi
      mov       al, RB_RED
      mov       BYTE [rdi + rb_node.color], al
; BEGIN PRINTF
; printf(fmt, hdr08);
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr08
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
; END PRINTF
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_term_rcrs (rb_node_t *node, rb_term_cb term_cb);
;
; param:
;
;   rdi = node
;   rsi = term_cb
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (node)
;   QWORD [rbp - 16]  = rsi (term_cb)
;-------------------------------------------------------------------------------
;
      static rb_term_rcrs
rb_term_rcrs:
      push      rbp
      mov       rbp, rsp
      sub       rsp, 16
      push      12
; QWORD [rbp - 8] = rdi (node)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (term_cb)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr10);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr10
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; if (n == &null_node) return
      mov       rax, null_node wrt ..sym
      cmp       rdi, rax
      je        .epilogue
; rb_term_rcrs(node->left, term_cb)
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.left]
      mov       rsi, QWORD [rbp - 16]
      call      rb_term_rcrs
; rb_term_rcrs(node->right, term_cb)
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.right]
      mov       rsi, QWORD [rbp - 16]
      call      rb_term_rcrs
; term_cb(node->data)
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.data]
      mov       rsi, QWORD [rbp - 16]
      ALIGN_STACK_AND_CALL r12, rsi
; free(node)
      mov       rdi, QWORD [rbp - 8]
      ALIGN_STACK_AND_CALL r12, free, wrt, ..plt
.epilogue:
      pop       r12
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_tree_term (rb_tree_t *tree);
;
; param:
;
;   rdi = tree
;-------------------------------------------------------------------------------
      global rb_tree_term:function
rb_tree_term:
; BEGIN PRINTF
; printf(fmt, hdr15);
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr15
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
; END PRINTF
; rb_term_rcrs(tree->root, tree->term_cb)
      mov       rsi, QWORD [rdi + rb_tree.term_cb]
      mov       rdi, QWORD [rdi + rb_tree.root]
      call      rb_term_rcrs
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_traverse (rb_node_t *node, rb_trav_cb trav_cb);
;
; param:
;
;   rdi = node
;   rsi = trav_cb
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (node)
;   QWORD [rbp - 16]  = rsi (trav_cb)
;-------------------------------------------------------------------------------
;
      static rb_traverse
rb_traverse:
      push      rbp
      mov       rbp, rsp
      sub       rsp, 16
      push      r12
; QWORD [rbp - 8] = rdi (node)
      mov       QWORD [rbp - 8], rdi
; QWORD [rbp - 16] = rsi (trav_cb)
      mov       QWORD [rbp - 16], rsi
; BEGIN PRINTF
; printf(fmt, hdr12);
      push      rsi
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr12
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
      pop       rsi
; END PRINTF
; if (node == &null_node) return
      mov       rax, null_node wrt ..sym
      cmp       rdi, rax
      je        .epilogue
; rb_traverse(node->left)
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.left]
      mov       rsi, QWORD [rbp - 16]
      call      rb_traverse
; data_cb(node->data)
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, QWORD [rbp - 16]
      ALIGN_STACK_AND_CALL r12, rsi
; rb_traverse(node->right)
      mov       rdi, QWORD [rbp - 8]
      mov       rdi, QWORD [rdi + rb_node.right]
      mov       rsi, QWORD [rbp - 16]
      call      rb_traverse
.epilogue:
      pop       r12
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_walk (rb_tree_t *tree);
;
; param:
;
;   rdi = tree
;-------------------------------------------------------------------------------
;
      global rb_walk:function
rb_walk:
; BEGIN PRINTF
; printf(fmt, hdr16);
      push      rdi
      xor       rax, rax
      mov       rdi, fmt
      mov       rsi, hdr16
      ALIGN_STACK_AND_CALL r12, printf, wrt, ..plt
      pop       rdi
; END PRINTF
      mov       rsi, QWORD [rdi + rb_tree.trav_cb]
      mov       rdi, QWORD [rdi + rb_tree.root]
      call      rb_traverse
      ret
%endif
