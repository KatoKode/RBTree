/*------------------------------------------------------------------------------
    Red-Black-Tree Implementation in x86_64 Assembly Language with
    C interface

    Copyright (C) 2025  J. McIntosh

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
------------------------------------------------------------------------------*/
#ifndef RBTREE_H
#define RBTREE_H  1

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pthread.h>

#define RB_BLACK      0x00000000
#define RB_RED        0x000000FF

typedef struct rb_tree rb_tree_t;

typedef struct rb_node rb_node_t;

struct rb_node {
  rb_tree_t *   tree;
  rb_node_t *   parent;
  rb_node_t *   left;
  rb_node_t *   right;
  void *        data;
  uint32_t      color;
};

#define rb_node_alloc() (calloc(1, sizeof(rb_node_t)))
#define rb_node_free(P) (free(P), P = NULL)

typedef int (*rb_find_cb) (void const *, void const *);
typedef void const * (*rb_key_cb) (void const *);
typedef int (*rb_nsrt_cb) (void const *, void const *);
typedef void (*rb_term_cb) (void *);
typedef void (*rb_trav_cb) (void const *);

struct rb_tree {
  rb_node_t *   nil;
  rb_node_t *   root;
  rb_find_cb    find_cb;
  rb_key_cb     key_cb;
  rb_nsrt_cb    nsrt_cb;
  rb_term_cb    term_cb;
  rb_trav_cb    trav_cb;
  pthread_rwlock_t * rwlock;
};

#define rb_tree_alloc() (calloc(1, sizeof(rb_tree_t)))
#define rb_tree_free(P) (free(P), P = NULL)

void rb_delete (rb_tree_t *, void const *);
rb_node_t * rb_find (rb_tree_t *, void const *);
int rb_tree_init (rb_tree_t *, rb_find_cb, rb_key_cb, rb_nsrt_cb,
    rb_term_cb, rb_trav_cb);
int rb_insert (rb_tree_t *, rb_node_t *);
void rb_nil_init (rb_node_t *node, rb_tree_t const *tree);
void rb_node_init (rb_node_t *, rb_tree_t const *, void const *);
void rb_tree_term (rb_tree_t *);
void rb_walk (rb_tree_t *);

void rb_left_rotate (rb_tree_t *, rb_node_t *);
void rb_right_rotate (rb_tree_t *, rb_node_t *);
rb_node_t * rb_tree_minimum (rb_tree_t *, rb_node_t *);
void rb_delete_fixup (rb_tree_t *, rb_node_t *);
#endif
