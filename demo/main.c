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
#include "main.h"

int main (int argc, char *argv[]) {

  if (argc < 2) {
    printf ("usage: ./btest [random number]\n");
    return -1;
  }

  // myrand will hold the random number paramenter
  size_t myrand = strtol(argv[1], NULL, 10);
  srand48(myrand);    // initialize the random number generator

  // allocate and initialize our b-tree
  rb_tree_t *tree = rb_tree_alloc();
  rb_tree_init(tree, find_cb, key_cb, nsrt_cb, term_cb, trav_cb);

  for (size_t i = 0L; i < DATA_COUNT; ++i) {
    data_t *d = data_alloc();

    do {
      // populate d->lng field
      do { d->lng = lrand48(); } while (d->lng < 10000000 || d->lng > 40000000);

      // record random long int
      random_long_int[i] = d->lng;

      // populate d->str field
      (void) snprintf(d->str, STR_LEN + 1, "%ld", d->lng);

      // search tree for duplicate data_t object
    } while ((rb_find(tree, (void const *)&d->lng)) != tree->nil);

    // allocate and initialize node, then insert into tree
    rb_node_t *node = rb_node_alloc();
    rb_node_init(node, tree, d);
    rb_insert(tree, node);
  }
#ifdef WALK_TREE
  // walk the tree
  walk_tree(tree);
#endif
  size_t delete_count = (size_t)DELETE_COUNT;

  // delete some data_t objects from the tree
  for (size_t n = 0L; n < delete_count; ++n) {
#ifdef RBTREE_DEBUG
    printf("\n---| begin delete | delete: %ld ---\n", random_long_int[n]);
#endif
    // search for a matching data_t object and delete it from the tree
    rb_delete(tree, (void const *)&random_long_int[n]);

#ifdef RBTREE_DEBUG
    puts("\n---| begin search after delete |---\n");
    // search for deleted data_t object to test deletion
    if ((rb_find(tree, (void const *)&random_long_int[n])) != tree->nil) {
      puts("\n---| DELETION ERROR! |---\n");
    }
#endif
  }
  // try to delete a data_t object that is not in the tree
#ifdef RBTREE_DEBUG
  puts("\n---| begin delete of key not in tree |---\n");
#endif
  long lng = lrand48();
  rb_delete(tree, (void const *)&lng);
#ifdef WALK_TREE
  // walk the tree
  walk_tree(tree);
#endif
  // terminate and free the tree
  term_tree(tree);
  rb_tree_free(tree);

  return 0;
}
//------------------------------------------------------------------------------
//
// FIND_CB
//
//------------------------------------------------------------------------------
int find_cb (void const * vp1, void const * vp2) {
  long const k = *(long const *)vp1;
  data_t const *d = (data_t const *)vp2;
#ifdef RBTREE_DEBUG
  printf("%s:  k: %ld <=> d->lng: %ld\n", __func__, k, d->lng);
#endif
  // do comparsions
  if (k < d->lng) return -1;
  else if (k > d->lng) return 1;
  return 0;
}
//------------------------------------------------------------------------------
//
// KEY_CB
//
//------------------------------------------------------------------------------
void const * key_cb (void const *vp) {
  return &((data_t const *)vp)->lng;
}
//------------------------------------------------------------------------------
//
// NSRT_CB
//
//------------------------------------------------------------------------------
int nsrt_cb (void const *vp1, void const *vp2) {
  data_t const *d1 = (data_t const*)vp1;
  data_t const *d2 = (data_t const*)vp2;
#ifdef RBTREE_DEBUG
  printf("%s:  d1->lng: %ld d1->str: %s <=> d2->lng: %ld d2->str: %s\n",
      __func__,d1->lng, d1->str, d2->lng,d2->str);
#endif
  // do comparsions
  if (d1->lng < d2->lng) return -1;
  else if (d1->lng > d2->lng) return 1;
  return 0;
}
//------------------------------------------------------------------------------
//
// TERM_CB
//
//------------------------------------------------------------------------------
void term_cb (void *vp) {
#ifdef RBTREE_DEBUG
  data_t const *d = (data_t const *)vp;
  printf("%s: \t\t\t%6lu:  d->lng: %ld  d->str: %s\n",
      __func__, ndx++, d->lng, d->str);

  fflush(stdout);
#endif
  free(vp);
}
//------------------------------------------------------------------------------
//
// PRINT_DATA
//
//------------------------------------------------------------------------------
void print_data (char const *s, data_t const *d) {
  printf("%s:  d->lng: %ld d->str: %s\n", s, d->lng, d->str);
}
//------------------------------------------------------------------------------
//
// TRAV_CB
//
//------------------------------------------------------------------------------
void trav_cb (void const *vp) {
  data_t const *d = (data_t const*)vp;

  printf("\t\t\t%6lu:  d->lng: %ld  d->str: %s\n", ndx++, d->lng, d->str);

  fflush(stdout);
}
//------------------------------------------------------------------------------
//
// TERM_TREE
//
//------------------------------------------------------------------------------
void term_tree (rb_tree_t *tree) {
  puts("\n---| tree termination |---\n");

  // initialize index used by tree walking callback
  ndx = 0L;

  rb_tree_term(tree);
}
//------------------------------------------------------------------------------
//
// WALK_TREE
//
//------------------------------------------------------------------------------
void walk_tree (rb_tree_t *tree) {
  puts("\n---| walk tree |---\n");

  // initialize index used by tree walking callback
  ndx = 0L;

  rb_walk(tree);

  puts("\n");
}

