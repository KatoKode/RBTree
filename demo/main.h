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
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include "../rbtree/rbtree.h"
#include "../util/util.h"

//#define RBTREE_DEBUG  1
#define WALK_TREE 1

// defines you can modify
#define DATA_COUNT    (8 * 1024)
#define DELETE_COUNT  (DATA_COUNT * 0.75)

// defines you should not modify
#define STR_LEN   15

// index for tree walking
size_t ndx;

// data object
typedef struct data data_t;

struct data {
  long      lng;
  char      str[STR_LEN + 1];
};

#define data_alloc() (calloc(1, sizeof(data_t)))
#define data_free(P) (free(P), P = NULL)

long random_long_int [DATA_COUNT];

long val[DATA_COUNT] = {
  1000001, 1000002, 1000003, 1000004, 1000005, 1000006, 1000007, 1000008,
  1000009, 1000010, 1000011, 1000012, 1000013, 1000014, 1000015, 1000016,
  1000017, 1000018, 1000019, 1000020
};
// callback definitions
int find_cb (void const *, void const *);
void const * key_cb (void const *);
int nsrt_cb (void const *, void const *);
void term_cb (void *);
void trav_cb (void const *);
// output data_t object
void print_data (char const *, data_t const *);
// begin tree termination
void term_tree (rb_tree_t *);
// begin walking the tree
void walk_tree (rb_tree_t *);
