#! /usr/bin/env mysql
/*
 * This is the equation database's initialize table file.
 */

/*
 * I'm sure that many description can for one expression.
 * Bidirectional tree.
 */
create table description (
  id         integer primary key auto_increment,

  p_next     integer default 0 references description (id),
  p_prev     integer default 0 references description (id),

  dtext	     text not null
);

/* classified fields. */
create table field_node (
  id          integer primary key auto_increment,
  description integer default 0 references description (id)
);

/*
 * Definition of the equation formed like we know.
 */
create table equation_node (
  id          integer primary key auto_increment,

  /* this must be unique. */
  eqnpart     text not null,
  /* symbol to writedown. */
  eqnsymb     text,
  /* algorithm to calculate (get numbered). */
  algorithm   text,

  /* many can be, so we classify with this. */
  field       integer default 0 references field_node  (id),
  description integer default 0 references description (id)
);

/*
 * Super class of equations.
 */
create table equation (
  id   	      integer primary key auto_increment,
  
  p_next      integer default 0 references equation (id),
  p_prev      integer default 0 references equation (id),
  
  contain     integer default 0 references equation_node (id),
  description integer default 0 references description   (id)
);

/*
 * Definition of relation between equations and ones.
 */
create table relation_node (
  id          integer primary key auto_increment,

  /* we think (in -> out) is natural. */
  eqnin       integer not null default 0 references equation_node (id),
  eqnout      integer not null default 0 references equation_node (id),

  /* which equation is used to deducted to. */
  eqnstate    integer default 0 references relation_node (id),

  /* -1, -2, ...: new variable, 0: destroy, 1, 2, 3, ...: (in->out) */
  transpose   text not null,

  /* which directions are valid? 0: both, 1: toward, 2: backward */
  direction   integer default 0 not null,

  /* classify this */
  field       integer default 0 references field_node  (id),
  description integer default 0 references description (id)

  /* in fact, we must redefine set calculation. */
);

/*
 * Super class of the relation.
 */
create table relation (
  id   	      integer primary key auto_increment,

  p_next      integer default 0 references relation (id),
  p_prev      integer default 0 references relation (id),
  
  contain     integer default 0 references relation_node (id),
  description integer default 0 references description   (id)
);

/* Definition of world we think about. */
create table world_node (
  id          integer primary key auto_increment,
  p_next      integer default 0 references world_node (id),
  p_prev      integer default 0 references world_node (id),
  
  equation    integer default 0 references equation (id),
  transpose   text not null
);

/*
 * Super class of world we think about.
 */
create table world (
  id   	      integer primary key auto_increment,
  
  contain     integer default 0 references world_node  (id),
  description integer default 0 references description (id)
);
