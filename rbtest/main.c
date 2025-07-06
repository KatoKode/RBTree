/*------------------------------------------------------------------------------
    Assembly Language Implementation of a (Red-Black) RB-Tree
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
#include "main.h"
/*------------------------------------------------------------------------------
  file:    main.c
  author:  J. McIntosh
  brief:   Red-Black-Tree demo program
------------------------------------------------------------------------------*/
int main (int argc, char *argv[]) {

  if (argc < 2) {
    printf ("usage: ./btest [random number]\n");
    return -1;
  }

  // myrand will hold the random number paramenter
  size_t myrand = strtol(argv[1], NULL, 10);
  srand48(myrand);    // initialize the random number generator

  // some constants
  size_t const o_size = sizeof(data_t);

  // allocate and initialize our b-tree
  rb_tree_t *tree = rb_tree_alloc();
  rb_tree_init(tree, find_cb, nsrt_cb, term_cb, walk_cb);

  // data_t object used by b_search to hold return value
  data_t db = {0.0, "0.0"};

  for (size_t i = 0L; i < DATA_COUNT; ++i) {
    data_t *d = data_alloc();
    size_t x = 0L;

    // get a random double, populate a data_t object, and search the tree for a
    // duplicate
    do {
      // get a random double that is greater-than 0.000001F
      do { d->d = drand48(); } while (d->d < 0.000001F);

      // assign the random double to our data array
      da[i] = d->d;

      // convert the random double to a string and store in our data object
      (void) snprintf(d->s, STR_LEN + 1, "%8.6f", d->d);

      // yield the CPU when dealing with duplicates
      if ((x++ & 0x2) == 0L) sched_yield();

      // search tree for duplicate data_t object
    } while ((rb_find(tree, (void const *)&da[i])) != NULL);

    // got a unique data_t object to add to the tree
    rb_node_t *node = rb_node_alloc();
    rb_node_init(node, d);
    rb_insert(tree, node);
  }

  // walk the tree outputing data_t objects
  walk_tree(tree);

  // delete some data_t objects from the tree
  for (size_t n = 0L; n < DELETE_COUNT; ++n) {
    puts("\n---| begin delete |---\n");

    // search for a matching data_t object and delete it from the tree
    rb_delete(tree, (void const *)&da[n]);

    puts("\n---| begin search after delete |---\n");

    // search for deleted data_t object to test deletion
    if ((rb_find(tree, (void const *)&da[n])) != NULL) {
      print_data("\n---| DELETION ERROR! |---\n", &db);
    }

    // yield the CPU
    if ((n & 0x2) == 0L) sched_yield();
  }

  // try to delete a data_t object that is not in the tree
  puts("\n---| begin delete of key not in tree |---\n");
  double b = drand48();
  rb_delete(tree, (void const *)&b);

  // walk the tree outputing data_t objects - again
  walk_tree(tree);

  // release memory held by all the data_t objects (if any), as well as, all
  // the memory held by the tree
  term_tree(tree);
  rb_tree_free(tree);

  return 0;
}
//
// callback to compare key with object
//
int find_cb (void const * vp1, void const * vp2) {
  data_t const *d = (data_t const *)vp1;
  double const k = *(double const *)vp2;

  printf("%s:  k: %8.6f (lt eq gt) d->d: %8.6f\n", __func__, k, d->d);

  // do comparsions
  if (k > d->d) return 1;
  else if (k < d->d) return -1;
  return 0;
}
//
// callback to compare objects
//
int nsrt_cb (void const *vp1, void const *vp2) {
  data_t const *d1 = vp1;
  data_t const *d2 = vp2;

  printf("%s:  d1: %8.6f s: %8s (lt eq gt) d2: %8.6f s: %8s\n",__func__,d1->d,
      d1->s, d2->d,d2->s);

  // do comparsions
  if (d1->d > d2->d) return 1;
  else if (d1->d < d2->d) return -1;
  return 0;
}
//
// callback to process object before deletion from tree
//
void term_cb (void *vp) {
  data_t *d = vp;

  printf("\t\t\t%6lu:  d: %8.6lf  s: %8s\n", ndx++, d->d, d->s);

  fflush(stdout);

  free(vp);

  if ((ndx % 8) == 0) {
    struct timespec req = { 0, 250000000 };
    nanosleep(&req, NULL);
  }
}
//
// output data object
//
void print_data (char const *s, data_t const *d) {
  printf("%s:  d: %8.6f s: %8s\n", s, d->d, d->s);
}
//
// callback for tree walking
//
void walk_cb (rb_node_t *node) {
  data_t const *d = node->data;

  printf("\t\t\t%6lu:  d: %8.6lf  s: %8s\n", ndx++, d->d, d->s);

  fflush(stdout);

  if ((ndx % 8) == 0) {
    struct timespec req = { 0, 250000000 };
    nanosleep(&req, NULL);
  }
}
//
// begin tree termination
//
void term_tree (rb_tree_t *tree) {
  puts("\n---| tree termination |---\n");

  struct timespec req = { 1, 0 };
  nanosleep(&req, NULL);

  // initialize index used by tree walking callback
  ndx = 0L;

  rb_tree_term(tree);
}
//
// begin tree walking
//
void walk_tree (rb_tree_t *tree) {
  puts("\n---| walk tree |---\n");

  struct timespec req = { 1, 0 };
  nanosleep(&req, NULL);

  // initialize index used by tree walking callback
  ndx = 0L;

  rb_walk(tree);

  puts("\n");
}

