/*------------------------------------------------------------------------------
    Red-Black-Tree (RBTREE) Implementation in x86_64 Assembly Language with
    C interface

    Copyright (C) 2025  J. McIntosh

    RBTREE is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    RBTREE is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with RBTREE; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
------------------------------------------------------------------------------*/
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include "../rbtree/rbtree.h"
#include "../util/util.h"

// defines you can modify
#define DATA_COUNT    128
#define DELETE_COUNT  0

// defines you should not modify
#define STR_LEN   15

// index for tree walking
size_t ndx;

// data object
typedef struct data data_t;

struct data {
  double    d;
  char      s[STR_LEN + 1];
};

#define data_alloc() (calloc(1, sizeof(data_t)))
#define data_free(P) (free(P), P = NULL)

// array of doubles
double da [DATA_COUNT];

// callback definitions
int find_cb (void const *, void const *);
int nsrt_cb (void const *, void const *);
void term_cb (void *);
void walk_cb (rb_node_t *);
// output data_t object
void print_data (char const *, data_t const *);
// begin tree termination
void term_tree (rb_tree_t *);
// begin walking the tree
void walk_tree (rb_tree_t *);
