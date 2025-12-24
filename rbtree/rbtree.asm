;-------------------------------------------------------------------------------
;   Red-Black-Tree (RBTREE) Implementation in x86_64 Assembly Language with
;   C interface
;
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
;
%ifndef RBTREE_ASM
%define RBTREE_ASM  1
;
;-------------------------------------------------------------------------------
;
extern calloc
extern free
extern get_null_node
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
section .text
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
      global rb_tree_minimum:function
rb_tree_minimum:
; while (node->left != tree->nil)
      mov       rax, QWORD [rdi + rb_tree.nil]    ; rax = tree->nil
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
; if (node_n->parent == tree->nil)
      mov       rax, QWORD [rdi + rb_tree.nil]      ; rax = tree->nil
      cmp       QWORD [rsi + rb_node.parent], rax
      jne       .else_if
;   tree->root = node_o;
      mov       QWORD [rdi + rb_tree.root], rdx
      jmp       .end_if_else
.else_if:
; else if (node_n == node_n->parent->left)
      mov       rax, QWORD [rsi + rb_node.parent]   ; rax = node_n->parent
      cmp       rsi, QWORD [rax + rb_node.left]
      jne       .else
;   node_n->parent->left = node_o;
      mov       QWORD [rax + rb_node.left], rdx
      jmp       .end_if_else
.else:
; else node_n->parent->right = node_o;
      mov       QWORD [rax + rb_node.right], rdx
.end_if_else:
; node_o->parent = node_n->parent;
      mov       rax, QWORD [rsi + rb_node.parent]   ; rax = node_n->parent
      mov       QWORD [rdx + rb_node.parent], rax
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_delete_fixup (rb_tree_t *tree, rb_node_t *node);
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
;   QWORD [rbp - 32]  = rbx (callee saved)
;-------------------------------------------------------------------------------
;
      static rb_delete_fixup
rb_delete_fixup:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 40
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 32], rbx
; rb_node_t *node_w = tree->nil;
      mov       rax, QWORD [rdi + rb_tree.nil]    ; rax = tree->nil
      mov       QWORD [rbp - 24], rax
; while (node != tree->root && node->color == RB_BLACK) {
.while_loop:
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, QWORD [rbp - 16]             ; rsi = node
      cmp       rsi, QWORD [rdi + rb_tree.root]
      je        .end_while
      mov       edx, DWORD [rsi + rb_node.color]
      cmp       edx, RB_BLACK
      jne       .end_while
;   if (node == node->parent->left) {
      mov       rbx, QWORD [rsi + rb_node.parent] ; rbx = node->parent
      cmp       rsi, QWORD [rbx + rb_node.left]
      jne       .else_1
;     node_w = node->parent->right;
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node->parent->right
      mov       QWORD [rbp - 24], rax             ; rax = node_w
;     if (node_w->color == RB_RED) {
      mov       edx, DWORD [rax + rb_node.color]
      cmp       edx, RB_RED
      jne       .end_if_1
;       node_w->color = RB_BLACK;
      mov       edx, RB_BLACK
      mov       DWORD [rax + rb_node.color], edx
;       node->parent->color = RB_RED;
      mov       edx, RB_RED
      mov       DWORD [rbx + rb_node.color], edx
;       rb_left_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, rbx                          ; rsi = node->parent
      call      rb_left_rotate
;       node_w = node->parent->right;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node->parent->right
      mov       QWORD [rbp - 24], rax
.end_if_1:
;     }
;     if (node_w->left->color == RB_BLACK && node_w->right->color == RB_BLACK) {
      mov       edx, RB_BLACK
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_w->left
      cmp       DWORD [rax + rb_node.color], edx
      jne       .else_2
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node_w->right
      cmp       DWORD [rax + rb_node.color], edx
      jne       .else_2
;       node_w->color = RB_RED;
      mov       edx, RB_RED
      mov       DWORD [rbx + rb_node.color], edx
;       node = node->parent;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       QWORD [rbp - 16], rax
      jmp       .while_loop
.else_2:
;     } else {
;       if (node_w->right->color == RB_BLACK) {
      mov       edx, RB_BLACK
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node_w->right
      cmp       DWORD [rax + rb_node.color], edx
      jne       .end_if_2
;         node_w->left->color = RB_BLACK;
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_w->left
      mov       DWORD [rax + rb_node.color], edx
;         node_w->color = RB_RED;
      mov       edx, RB_RED
      mov       DWORD [rbx + rb_node.color], edx
;         rb_right_rotate(tree, node_w);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, rbx                          ; rsi = node_w
      call      rb_right_rotate
;         node_w = node->parent->right;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node->parent->right
      mov       QWORD [rbp - 24], rax             ; rax = node_w
.end_if_2:
;       }
;       node_w->color = node->parent->color;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       edx, DWORD [rax + rb_node.color]  ; edx = node->parent->color
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       DWORD [rbx + rb_node.color], edx
;       node->parent->color = RB_BLACK;
      mov       edx, RB_BLACK
      mov       DWORD [rax + rb_node.color], edx
;       node_w->right->color = RB_BLACK;
      mov       rax, QWORD [rbx + rb_node.right]   ; rax = node_w->right
      mov       DWORD [rax + rb_node.color], edx
;       rb_left_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rsi, QWORD [rbx + rb_node.parent] ; rsi = node->parent
      call      rb_left_rotate
;       node = tree->root;
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.root]   ; rax = tree->root
      mov       QWORD [rbp - 16], rax
      jmp       .while_loop
;     }
.else_1:
;   } else {
;     node_w = node->parent->left;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node->parent->left
      mov       QWORD [rbp - 24], rax             ; rax = node_w
;     if (node_w->color == RB_RED) {
      mov       edx, RB_RED
      cmp       DWORD [rax + rb_node.color], edx
      jne       .end_if_3
;       node_w->color = RB_BLACK;
      mov       edx, RB_BLACK
      mov       DWORD [rax + rb_node.color], edx
;       node->parent->color = RB_RED;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       edx, RB_RED
      mov       DWORD [rax + rb_node.color], edx
;       rb_right_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, rax                          ; rsi = node->parent
      call      rb_right_rotate
;       node_w = node->parent->left;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node->parent->left
      mov       QWORD [rbp - 24], rax
.end_if_3:
;     }
;     if (node_w->right->color == RB_BLACK && node_w->left->color == RB_BLACK) {
      mov       edx, RB_BLACK                     ; edx = RB_BLACK
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node_w->right
      cmp       DWORD [rax + rb_node.color], edx
      jne       .else_3
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_w->left
      cmp       DWORD [rax + rb_node.color], edx
      jne       .else_3
;       node_w->color = RB_RED;
      mov       edx, RB_RED                       ; edx = RB_RED
      mov       DWORD [rbx + rb_node.color], edx
;       node = node->parent;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       QWORD [rbp - 16], rax             ; rax = node
      jmp       .while_loop
.else_3:
;     } else {
;       if (node_w->left->color == RB_BLACK) {
      mov       edx, RB_BLACK                     ; edx = RB_BLACK
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_w->left
      cmp       DWORD [rax + rb_node.color], edx
      jne       .end_if_4
;         node_w->right->color = RB_BLACK;
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node_w->right
      mov       DWORD [rax + rb_node.color], edx
;         node_w->color = RB_RED;
      mov       edx, RB_RED                       ; edx = RB_RED
      mov       DWORD [rbx + rb_node.color], edx
;         rb_left_rotate(tree, node_w);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, rbx                          ; rsi = node_w
      call      rb_left_rotate
;         node_w = node->parent->left;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node->parent->left
      mov       QWORD [rbp - 24], rax             ; rax = node_w
.end_if_4:
;       }
;       node_w->color = node->parent->color;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       edx, DWORD [rax + rb_node.color]  ; edx = node->parent->color
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_w
      mov       DWORD [rbx + rb_node.color], edx
;       node->parent->color = RB_BLACK;
      mov       edx, RB_BLACK                     ; edx = RB_BLACK
      mov       DWORD [rax + rb_node.color], edx
;       node_w->left->color = RB_BLACK;
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_w->left
      mov       DWORD [rax + rb_node.color], edx
;       rb_right_rotate(tree, node->parent);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rsi, QWORD [rbx + rb_node.parent] ; rsi = node->parent
      call      rb_right_rotate
;       node = tree->root;
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.root]   ; rax = tree->root
      mov       QWORD [rbp - 16], rax             ; rax = node
      jmp       .while_loop
;     }
;   }
.end_while:
; }
; node->color = RB_BLACK;
      mov       edx, RB_BLACK                     ; edx = RB_BLACK
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       DWORD [rax + rb_node.color], edx
.epilogue:
      mov       rbx, QWORD [rbp - 32]
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
;   QWORD [rbp - 24]  = (rb_node_t *node_z)
;   QWORD [rbp - 32]  = (rb_node_t *node_x)
;   QWORD [rbp - 40]  = (rb_node_t *node_y)
;   DWORD [rbp - 48]  = (int y_original_color)
;   QWORD [rbp - 56]  = rbx (callee saved)
;   QWORD [rbp - 64]  = r12 (callee saved)
;-------------------------------------------------------------------------------
;
      global rb_delete:function
rb_delete:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 72
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 56], rbx
      mov       QWORD [rbp - 64], r12
; if ((node_z = rb_find(tree, key)) == tree->nil) return;
      call      rb_find                             ; rax = node_z | tree->nil
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      cmp       rax, QWORD [rdi + rb_tree.nil]
      je        .epilogue
      mov       QWORD [rbp - 24], rax               ; rax = node_z
; tree->term_cb(node_z->data);
      mov       rcx, QWORD [rdi + rb_tree.term_cb]  ; rcx = term_cb
      mov       rdi, QWORD [rax + rb_node.data]     ; rdi = node_z->data
      ALIGN_STACK_AND_CALL r12, rcx
; rb_node_t *node_x = tree->nil;
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.nil]      ; rax = tree->nil
      mov       QWORD [rbp - 32], rax
; rb_node_t *node_y = node_z
      mov       rax, QWORD [rbp - 24]               ; rax = node_z
      mov       QWORD [rbp - 40], rax
; int y_original_color = node_y->color
      mov       rax, QWORD [rbp - 40]               ; rax = node_y
      mov       edx, DWORD [rax + rb_node.color]
      mov       DWORD [rbp - 48], edx
; if (node_z->left == tree->nil) {
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.nil]      ; rax = tree->nil
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      cmp       QWORD [rbx + rb_node.left], rax
      jne       .else_if
;   node_x = node_z->right;
      mov       rax, QWORD [rbx + rb_node.right]     ; rax = node_z->right
      mov       QWORD [rbp - 32], rax
;   rb_transplant(tree, node_z, node_z->right);
      mov       rdx, QWORD [rbx + rb_node.right]    ; rdx = node_z->right
      mov       rsi, rbx                            ; rsi = node_z
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      call      rb_transplant
      jmp       .cont_1
.else_if:
; } else if (node_z->right == tree->nil) {
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.nil]      ; rax = tree->nil
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      cmp       QWORD [rbx + rb_node.right], rax
      jne       .else_1
;   node_x = node_z->left;
      mov       rax, QWORD [rbx + rb_node.left]     ; rax = node_z->left
      mov       QWORD [rbp - 32], rax               ; rax = nodx_x
;   rb_transplant(tree, node_z, node_z->left);
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rsi, rbx                            ; rsi = node_z
      mov       rdx, rax                            ; rdx = node_z->left
      call      rb_transplant
      jmp       .cont_1
.else_1:
; } else {
;   node_y = rb_tree_minimum(tree, node_z->right);
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      mov       rsi, QWORD [rbx + rb_node.right]    ; rsi = node_z->right
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      call      rb_tree_minimum
      mov       QWORD [rbp - 40], rax               ; rax = node_y
;   y_original_color = node_y->color;
      mov       edx, DWORD [rax + rb_node.color]
      mov       DWORD [rbp - 48], edx
;   node_x = node_y->right;
      mov       rbx, QWORD [rax + rb_node.right]    ; rbx = node_y->right
      mov       QWORD [rbp - 32], rbx
;   if (node_y->parent == node_z) {
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      cmp       QWORD [rax + rb_node.parent], rbx
      jne       .else_2
;     node_x->parent = node_y;
      mov       rbx, QWORD [rbp - 32]               ; rbx = node_x
      mov       QWORD [rbx + rb_node.parent], rax
      jmp       .cont_2
.else_2:
;   } else {
;     rb_transplant(tree, node_y, node_y->right);
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rsi, QWORD [rbp - 40]               ; rsi = node_y
      mov       rdx, QWORD [rsi + rb_node.right]    ; rdx = node_y->right
      call      rb_transplant
;     node_y->right = node_z->right;
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      mov       rax, QWORD [rbx + rb_node.right]    ; rax = node_z->right
      mov       rbx, QWORD [rbp - 40]               ; rbx = node_y
      mov       QWORD [rbx + rb_node.right], rax
;     node_y->right->parent = node_y;
      mov       rax, QWORD [rbx + rb_node.right]    ; rax = node_y->right
      mov       QWORD [rax + rb_node.parent], rbx
;   }
.cont_2:
;   rb_transplant(tree, node_z, node_y);
      mov       rdi, QWORD [rbp - 8]                ; rdi = tree
      mov       rsi, QWORD [rbp - 24]               ; rsi = node_z
      mov       rdx, QWORD [rbp - 40]               ; rdx = node_y
      call      rb_transplant
;   node_y->left = node_z->left;
      mov       rbx, QWORD [rbp - 24]               ; rbx = node_z
      mov       rax, QWORD [rbx + rb_node.left]     ; rax = node_z->left
      mov       rbx, QWORD [rbp - 40]               ; rbx = node_y
      mov       QWORD [rbx + rb_node.left], rax
;   node_y->left->parent = node_y;
      mov       rax, QWORD [rbx + rb_node.left]     ; rax = node_y->left
      mov       QWORD [rax + rb_node.parent], rbx
;   node_y->color = node_z->color;
      mov       rax, QWORD [rbp - 24]               ; rax = node_z
      mov       edx, DWORD [rax + rb_node.color]
      mov       DWORD [rbx + rb_node.color], edx
; }
.cont_1:
; if (y_original_color == RB_BLACK)
      mov       edx, RB_BLACK
      cmp       DWORD [rbp - 48], edx
      jne       .cont_3
;   rb_delete_fixup(tree, node_x);
      mov       rdi, QWORD [rbp - 8]    ; rdi = tree
      mov       rsi, QWORD [rbp - 32]   ; rsi = node_x
      call      rb_delete_fixup
.cont_3:
; free(node_z);
      mov       rdi, QWORD [rbp - 24]   ; rdi = node_z
      ALIGN_STACK_AND_CALL r12, free, wrt, ..plt
.epilogue:
      mov       r12, QWORD [rbp - 64]
      mov       rbx, QWORD [rbp - 56]
      mov       rsp, rbp
      pop       rbp
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
;
; stack:
;
;   QWORD [rbp - 8] = rbx (callee saved)
;-------------------------------------------------------------------------------
;
      global rb_left_rotate:function
rb_left_rotate:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 8
      mov       QWORD [rbp - 8], rbx
; rb_node_t *node_y = node->right;
      mov       rax, QWORD [rsi + rb_node.right]    ; rax = node->right = node_y
; node->right = node_y->left;
      mov       rbx, QWORD [rax + rb_node.left]     ; rbx = node_y->left
      mov       QWORD [rsi + rb_node.right], rbx
; if (node_y->left != tree->nil)
      cmp       rbx, QWORD [rdi + rb_tree.nil]
      je        .end_if
;   node_y->left->parent = node;
      mov       QWORD [rbx + rb_node.parent], rsi
.end_if:
; node_y->parent = node->parent;
      mov       rbx, QWORD [rsi + rb_node.parent]   ; rbx = node->parent
      mov       QWORD [rax + rb_node.parent], rbx
; if (node->parent == tree->nil)
      cmp       rbx, QWORD [rdi + rb_tree.nil]
      jne       .else_if
;   tree->root = node_y;
      mov       QWORD [rdi + rb_tree.root], rax
      jmp       .end_if_else
.else_if:
; else if (node == node->parent->left)
      cmp       rsi, QWORD [rbx + rb_node.left]
      jne       .else
;   node->parent->left = node_y;
      mov       QWORD [rbx + rb_node.left], rax
      jmp       .end_if_else
.else:
;  else node->parent->right = node_y;
      mov       QWORD [rbx + rb_node.right], rax
.end_if_else:
;  node_y->left = node;
      mov       QWORD [rax + rb_node.left], rsi
;  node->parent = node_y;
      mov       QWORD [rsi + rb_node.parent], rax
; epilogue
      mov       rbx, QWORD [rbp - 8]
      mov       rsp, rbp
      pop       rbp
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
;
; stack:
;
;   QWORD [rbp - 8]  = rbx (callee saved)
;-------------------------------------------------------------------------------
;
      global rb_right_rotate:function
rb_right_rotate:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 8
      mov       QWORD [rbp - 8], rbx
; rb_node_t *node_y = node->left;
      mov       rax, QWORD [rsi + rb_node.left]     ; rax = node->left = node_y
; node->left = node_y->right;
      mov       rbx, QWORD [rax + rb_node.right]    ; rbx = node_y->right
      mov       QWORD [rsi + rb_node.left], rbx
; if (node_y->right != tree->nil)
      cmp       rbx, QWORD [rdi + rb_tree.nil]
      je        .end_if
;   node_y->right->parent = node;
      mov       QWORD [rbx + rb_node.parent], rsi
.end_if:
; node_y->parent = node->parent;
      mov       rbx, QWORD [rsi + rb_node.parent]   ; rbx = node->parent
      mov       QWORD [rax + rb_node.parent], rbx
; if (node->parent == tree->nil)
      cmp       rbx, QWORD [rdi + rb_tree.nil]
      jne       .else_if
;   tree->root = node_y;
      mov       QWORD [rdi + rb_tree.root], rax
      jmp       .end_if_else
.else_if:
; else if (node == node->parent->right)
      cmp       rsi, QWORD [rbx + rb_node.right]
      jne       .else
;   node->parent->right = node_y;
      mov       QWORD [rbx + rb_node.right], rax
      jmp       .end_if_else
.else:
; else node->parent->left = node_y;
      mov       QWORD [rbx + rb_node.left], rax
.end_if_else:
; node_y->right = node;
      mov       QWORD [rax + rb_node.right], rsi
; node->parent = node_y;
      mov       QWORD [rsi + rb_node.parent], rax
; epilogue
      mov       rbx, QWORD [rbp - 8]
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
;   rax = &matched_node | &null_node
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (node)
;   QWORD [rbp - 16]  = rsi (find_cb)
;   QWORD [rbp - 24]  = rdx (key)
;   QWORD [rbp - 32]  = rbx (callee saved)
;   QWORD [rbp - 40]  = r12 (callee saved)
;-------------------------------------------------------------------------------
;
      static rb_find_rcrs
rb_find_rcrs:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 40
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 24], rdx
      mov       QWORD [rbp - 32], rbx
      mov       QWORD [rbp - 40], r12
; if (node == node->tree->nil || find_cb(key, node->data) == 0) return node
      mov       rbx, QWORD [rdi + rb_node.tree] ; rbx = node->tree
      cmp       rdi, QWORD [rbx + rb_tree.nil]
      je        .match
      mov       rcx, rsi                        ; rcx = find_cb
      mov       rsi, QWORD [rdi + rb_node.data] ; rsi = node->data
      mov       rdi, rdx                        ; rdi = key
      ALIGN_STACK_AND_CALL r12, rcx
      test      eax, eax
      jz        .match
      mov       rbx, QWORD [rbp - 8]              ; rdx = node
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node->left
      js        .go_left
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node->right
.go_left:
; return rb_find_rcrs(node, find_cb, key);
      mov       rdi, rax                ; rdi = node->left/right
      mov       rsi, QWORD [rbp - 16]   ; rsi = find_cb
      mov       rdx, QWORD [rbp - 24]   ; rdx = key
      call      rb_find_rcrs
      jmp       .epilogue
.match:
      mov       rax, QWORD [rbp - 8]
.epilogue:
      mov       r12, QWORD [rbp - 40]
      mov       rbx, QWORD [rbp - 32]
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
;   rax = matched_node | tree->nil
;-------------------------------------------------------------------------------
;
      global rb_find:function
rb_find:
; return rb_find_rcrs (tree->root, tree->find_cb, key);
      mov       rdx, rsi
      mov       rsi, QWORD [rdi + rb_tree.find_cb]
      mov       rax, QWORD [rdi + rb_tree.root]
      mov       rdi, rax
      call      rb_find_rcrs
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   int rb_tree_init (rb_tree_t *tree,
;               rb_find_cb find_cb,
;               rb_key_cb key_cb,
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
;
; stack:
;
;   QWORD [rbp - 8]   = tree (rdi)
;   QWORD [rbp - 16]  = rbx (callee saved)
;   QWORD [rbp - 24]  = r12 (callee saved)
;-------------------------------------------------------------------------------
;
      global rb_tree_init:function
rb_tree_init:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rbx
      mov       QWORD [rbp - 24], r12
; initialize tree structure
      xor       rax, rax
      mov       QWORD [rdi + rb_tree.root], rax
      mov       QWORD [rdi + rb_tree.find_cb], rsi
      mov       QWORD [rdi + rb_tree.key_cb], rdx
      mov       QWORD [rdi + rb_tree.nsrt_cb], rcx
      mov       QWORD [rdi + rb_tree.term_cb], r8
      mov       QWORD [rdi + rb_tree.trav_cb], r9
; if ((tree->nil = calloc(1, sizeof(rb_node_t))) == NULL) return -1;
      mov       rdi, 1
      mov       rsi, rb_node_size
      ALIGN_STACK_AND_CALL r12, calloc, wrt, ..plt
      mov       rdi, QWORD [rbp - 8]
      mov       QWORD [rdi + rb_tree.nil], rax
      test      rax, rax
      jnz       .end_if
      mov       eax, -1
      jmp       .epilogue
.end_if:
; tree->nil->tree = tree;
      mov       rbx, QWORD [rbp - 8]
      mov       rax, QWORD [rbx + rb_tree.nil]
      mov       QWORD [rax + rb_node.tree], rbx
; tree->nil->parent = tree->nil;
      mov       QWORD [rax + rb_node.parent], rax
; tree->nil->left = tree->nil;
      mov       QWORD [rax + rb_node.left], rax
; tree->nil->right = tree->nil;
      mov       QWORD [rax + rb_node.right], rax
; tree->nil->data = NULL;
      xor       rcx, rcx
      mov       QWORD [rax + rb_node.data], rcx
; tree->nil->color = RB_BLACK;
      mov       edx, RB_BLACK
      mov       DWORD [rax + rb_node.color], edx
; tree->root = tree->nil;
      mov       QWORD [rbx + rb_tree.root], rax
      xor       eax, eax  ; return 0;
.epilogue:
      mov       r12, QWORD [rbp - 24]
      mov       rbx, QWORD [rbp - 16]
      mov       rsp, rbp
      pop       rbp
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
;   QWORD [rbp - 32]  = rbx (callee saved)
;-------------------------------------------------------------------------------
;
      static rb_insert_fixup
rb_insert_fixup:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 40
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 32], rbx
; while (node->parent->color == RB_RED) {
.while_loop:
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       edx, DWORD [rax + rb_node.color]
      cmp       edx, RB_RED
      jne       .end_while
;   if (node->parent == node->parent->parent->left) {
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent->parent
      mov       rcx, QWORD [rbx + rb_node.left]   ; rcx = node->parent->parent->left
      cmp       rax, rcx
      jne       .else_1
;     rb_node_t *node_y = node->parent->parent->right;
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node->parent->parent->right
      mov       QWORD [rbp - 24], rax             ; rax = node_y
;     if (node_y->color == RB_RED) {
      mov       edx, DWORD [rax + rb_node.color]
      cmp       edx, RB_RED
      jne       .else_2
;       node->parent->color = RB_BLACK;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       DWORD [rax + rb_node.color], RB_BLACK
;       node_y->color = RB_BLACK;
      mov       rax, QWORD [rbp - 24]             ; rax = node_y
      mov       DWORD [rax + rb_node.color], RB_BLACK
;       node->parent->parent->color = RB_RED;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent->parent
      mov       DWORD [rbx + rb_node.color], RB_RED
;       node = node->parent->parent;
      mov       QWORD [rbp - 16], rbx
      jmp       .while_loop
;     } else {
.else_2:
;       if (node == node->parent->right) {
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rcx, QWORD [rbx + rb_node.right]  ; rcx = node->parent->right
      cmp       rax, rcx
      jne       .end_if_1
;         node = node->parent;
      mov       QWORD [rbp - 16], rbx
;         rb_left_rotate(tree, node);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, QWORD [rbp - 16]             ; rsi = node
      call      rb_left_rotate
;        }
.end_if_1:
;        node->parent->color = RB_BLACK;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       DWORD [rax + rb_node.color], RB_BLACK
;        node->parent->parent->color = RB_RED;
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent->parent
      mov       DWORD [rbx + rb_node.color], RB_RED
;        rb_right_rotate(tree, node->parent->parent);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, rbx                          ; rsi = node->parent->parent
      call      rb_right_rotate
      jmp       .while_loop
;     }
;   } else {
.else_1:
;     rb_node_t *node_y = node->parent->parent->left;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent->parent
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node->parent->parent->left
      mov       QWORD [rbp - 24], rax             ; rax = node_y
;     if (node_y->color == RB_RED) {
      cmp       DWORD [rax + rb_node.color], RB_RED
      jne       .else_3
;       node_y->color = RB_BLACK;
      mov       DWORD [rax + rb_node.color], RB_BLACK
;       node->parent->color = RB_BLACK;
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       rax, QWORD [rbx + rb_node.parent] ; rax = node->parent
      mov       DWORD [rax + rb_node.color], RB_BLACK
;       node->parent->parent->color = RB_RED;
      mov       rbx, QWORD [rax + rb_node.parent]  ; rbx = node->parent->parent
      mov       DWORD [rbx + rb_node.color], RB_RED
;       node = node->parent->parent;
      mov       QWORD [rbp - 16], rbx
      jmp       .while_loop
;     } else {
.else_3:
;       if (node == node->parent->left) {
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent] ; rbx = node->parent
      mov       rcx, QWORD [rbx + rb_node.left]   ; rcx = node->parent->left
      cmp       rax, rcx
      jne       .end_if_2
;         node = node->parent;
      mov       QWORD [rbp - 16], rbx             ; rbx = node
;         rb_right_rotate(tree, node);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rbx
      call      rb_right_rotate
;       }
.end_if_2:
;       node->parent->color = RB_BLACK;
      mov       rax, QWORD [rbp - 16]                 ; rax = node
      mov       rbx, QWORD [rax + rb_node.parent]     ; rbx = node->parent
      mov       DWORD [rbx + rb_node.color], RB_BLACK
;       node->parent->parent->color = RB_RED;
      mov       rax, QWORD [rbx + rb_node.parent]     ; rax = node->parent->parent
      mov       DWORD [rax + rb_node.color], RB_RED
;       rb_left_rotate(tree, node->parent->parent);
      mov       rdi, QWORD [rbp - 8]
      mov       rsi, rax
      call      rb_left_rotate
      jmp       .while_loop
;     }
;   }
; }
.end_while:
; tree->root->color = RB_BLACK;
      mov       rdi, QWORD [rbp - 8]            ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.root] ; rax = tree->root
      mov       DWORD [rax + rb_node.color], RB_BLACK
; epilogue
      mov       rbx, QWORD [rbp - 32]
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
;   QWORD [rbp - 40]  = rbx (callee saved)
;   QWORD [rbp - 48]  = r12 (callee saved)
;-------------------------------------------------------------------------------
;
      global rb_insert:function
rb_insert:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 56
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 40], rbx
      mov       QWORD [rbp - 48], r12
; rb_node_t *node_x = tree->root
      mov       rax, QWORD [rdi + rb_tree.root]   ; rax = tree->root
      mov       QWORD [rbp - 24], rax             ; rax = node_x
; rb_node_t *node_y = tree->nil                   ;
      mov       rbx, QWORD [rdi + rb_tree.nil]    ; rbx = tree->nil
      mov       QWORD [rbp - 32], rbx             ; rbx = node_y
; while (node_x != tree->nil) {
.while_loop:
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rbx, QWORD [rdi + rb_tree.nil]    ; rbx = tree->nill
      mov       rax, QWORD [rbp - 24]             ; rax = node_x
      cmp       rax, rbx
      je        .end_while
;   node_y = node_x;
      mov       QWORD [rbp - 32], rax
;   if (tree->nsrt_cb(node->data, node_x->data) < 0)
      mov       rcx, [rdi + rb_tree.nsrt_cb]
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rdi, [rax + rb_node.data]
      mov       rax, QWORD [rbp - 24]             ; rax = node_x
      mov       rsi, [rax + rb_node.data]
      ALIGN_STACK_AND_CALL r12, rcx
      test      eax, eax
      jns       .else_1
;     node_x = node_x->left;
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_x
      mov       rax, QWORD [rbx + rb_node.left]   ; rax = node_x->left
      mov       QWORD [rbp - 24], rax             ; rax = node_x
      jmp       .end_if_else
.else_1:
;   else node_x = node_x->right;
      mov       rbx, QWORD [rbp - 24]             ; rbx = node_x
      mov       rax, QWORD [rbx + rb_node.right]  ; rax = node_x->right
      mov       QWORD [rbp - 24], rax             ; rax = node_x
.end_if_else:
      jmp       .while_loop
; }
.end_while:
; node->parent = node_y;
      mov       rax, QWORD [rbp - 32]             ; rax = node_y
      mov       rbx, QWORD [rbp - 16]             ; rbx = node_x
      mov       QWORD [rbx + rb_node.parent], rax
; if (node_y == tree->nil)
      mov       rdi, QWORD [rbp - 8]
      cmp       rax, QWORD [rdi + rb_tree.nil]
      jne       .else_if
;   tree->root = node;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       QWORD [rdi + rb_tree.root], rax
      jmp       .end_else_3
.else_if:
;  else if (tree->nsrt_cb(node->data, node_y->data) < 0)
      mov       rcx, [rdi + rb_tree.nsrt_cb]      ; rcx = tree->nsrt_cb
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rdi, [rax + rb_node.data]         ; rdi = node->data
      mov       rax, QWORD [rbp - 32]             ; rax = node_y
      mov       rsi, [rax + rb_node.data]         ; rsi = node_y->data
      ALIGN_STACK_AND_CALL r12, rcx
      test      eax, eax
      jns       .else_3
;    node_y->left = node;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rbp - 32]             ; rbx = node_y
      mov       QWORD [rbx + rb_node.left], rax
      jmp       .end_else_3
.else_3:
;  else node_y->right = node;
      mov       rax, QWORD [rbp - 16]             ; rax = node
      mov       rbx, QWORD [rbp - 32]             ; rbx = node_y
      mov       QWORD [rbx + rb_node.right], rax
.end_else_3:
;  node->left = tree->nil;
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rax, QWORD [rdi + rb_tree.nil]    ; rax = tree->nil
      mov       rbx, QWORD [rbp - 16]             ; rbx = node
      mov       QWORD [rbx + rb_node.left], rax
;  node->right = tree->nil;
      mov       QWORD [rbx + rb_node.right], rax
;  node->color = RB_RED;
      mov       DWORD [rbx + rb_node.color], RB_RED
;  rb_insert_fixup(tree, node);
      mov       rdi, QWORD [rbp - 8]              ; rdi = tree
      mov       rsi, QWORD [rbp - 16]             ; rsi = node
      call      rb_insert_fixup
; epilogue
      mov       r12, QWORD [rbp - 48]
      mov       rbx, QWORD [rbp - 40]
      mov       rsp, rbp
      pop       rbp
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_nil_init (rb_node_t *node, rb_tree_t const *tree);
;
; param:
;
;   rdi = node
;   rsi = tree
;-------------------------------------------------------------------------------
;
      global rb_nil_init:function
rb_nil_init:
; initialize node
      mov       QWORD [rdi + rb_node.tree], rsi
      mov       rax, QWORD [rsi + rb_tree.nil]
      mov       QWORD [rdi + rb_node.parent], rax
      mov       QWORD [rdi + rb_node.left], rax
      mov       QWORD [rdi + rb_node.right], rax
      xor       rax, rax
      mov       QWORD [rdi + rb_node.data], rax
      mov       DWORD [rdi + rb_node.color], RB_BLACK
      ret
;
;-------------------------------------------------------------------------------
; C definition:
;
;   void rb_node_init (rb_node_t *node, rb_tree_t const *tree, void const *data);
;
; param:
;
;   rdi = node
;   rsi = tree
;   rdx = data
;-------------------------------------------------------------------------------
;
      global rb_node_init:function
rb_node_init:
; initialize node
      mov       QWORD [rdi + rb_node.tree], rsi
      mov       rax, QWORD [rsi + rb_tree.nil]
      mov       QWORD [rdi + rb_node.parent], rax
      mov       QWORD [rdi + rb_node.left], rax
      mov       QWORD [rdi + rb_node.right], rax
      mov       QWORD [rdi + rb_node.data], rdx
      mov       DWORD [rdi + rb_node.color], RB_RED
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
;   QWORD [rbp - 24]  = rbx (callee saved)
;   QWORD [rbp - 32]  = r12 (callee saved)
;-------------------------------------------------------------------------------
;
      static rb_term_rcrs
rb_term_rcrs:
      push      rbp
      mov       rbp, rsp
      sub       rsp, 40
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 24], rbx
      mov       QWORD [rbp - 32], r12
; if (node == node->tree->nil) return
      mov       rbx, QWORD [rdi + rb_node.tree]     ; rbx = tree
      cmp       rdi, QWORD [rbx + rb_tree.nil]
      je        .epilogue
; rb_term_rcrs(node->left, term_cb)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.left]     ; rdi = node->left
      mov       rsi, QWORD [rbp - 16]               ; rsi = term_cb
      call      rb_term_rcrs
; term_cb(node->data)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.data]     ; rdi = node->data
      mov       rcx, QWORD [rbp - 16]               ; rcx = term_cb
      ALIGN_STACK_AND_CALL r12, rcx
; rb_term_rcrs(node->right, term_cb)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.right]    ; rdi = node->right
      mov       rsi, QWORD [rbp - 16]               ; rsi = term_cb
      call      rb_term_rcrs
; free(node)
      mov       rdi, QWORD [rbp - 8]                ; rdi = node
      ALIGN_STACK_AND_CALL r12, free, wrt, ..plt
.epilogue:
      mov       r12, QWORD [rbp - 32]
      mov       rbx, QWORD [rbp - 24]
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
;
; stack:
;
;   QWORD [rbp - 8]   = rdi (tree)
;   QWORD [rbp - 16]  = rbx (callee saved)
;-------------------------------------------------------------------------------
      global rb_tree_term:function
rb_tree_term:
; prologue
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rbx
; rb_term_rcrs(tree->root, tree->term_cb)
      mov       rsi, QWORD [rdi + rb_tree.term_cb]
      mov       rax, QWORD [rdi + rb_tree.root]
      mov       rdi, rax
      call      rb_term_rcrs
      mov       rdi, QWORD [rbp - 8]
      mov       rax, QWORD [rdi + rb_tree.nil]
      mov       rdi, rax
      ALIGN_STACK_AND_CALL rbx, free, wrt, ..plt
; epilogue
      mov       rbx, QWORD [rbp - 16]
      mov       rsp, rbp
      pop       rbp
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
;   QWORD [rbp - 24]  = rbx (callee saved)
;-------------------------------------------------------------------------------
;
      static rb_traverse
rb_traverse:
      push      rbp
      mov       rbp, rsp
      sub       rsp, 24
      mov       QWORD [rbp - 8], rdi
      mov       QWORD [rbp - 16], rsi
      mov       QWORD [rbp - 24], rbx
; if (node == node->tree->nil) return
      mov       rax, QWORD [rdi + rb_node.tree]     ; rax = tree
      cmp       rdi, QWORD [rax + rb_tree.nil]
      je        .epilogue
; rb_traverse(node->left)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.left]     ; rdi = node->left
      mov       rsi, QWORD [rbp - 16]               ; rsi = trav_cb
      call      rb_traverse
; trav_cb(node->data)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.data]     ; rdi = node->data
      mov       rcx, QWORD [rbp - 16]               ; rcx = trav_cb
      ALIGN_STACK_AND_CALL rbx, rcx
; rb_traverse(node->right)
      mov       rax, QWORD [rbp - 8]                ; rax = node
      mov       rdi, QWORD [rax + rb_node.right]    ; rdi = node->right
      mov       rsi, QWORD [rbp - 16]               ; rsi = trav_cb
      call      rb_traverse
.epilogue:
      mov       rbx, QWORD [rbp - 24]
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
      mov       rsi, QWORD [rdi + rb_tree.trav_cb]
      mov       rax, QWORD [rdi + rb_tree.root]
      mov       rdi, rax
      call      rb_traverse
      ret
%endif
