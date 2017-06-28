/*
 cf.
  create table products (product_no integer primary key, name text);
  create table orders ( order_id integer primary key, 
  	 product_no integer references products (product_no) );
*/

/*
 * I'm sure that many description can for one expression.
 */
create table description (
  serial     integer primary key auto_increment,
  
  p_next     integer default 0 references description (serial),
  p_prev     integer default 0 references description (serial),
  
  dtext	     text
);

/*
 * for now, test-seqn1 is database name
 */
/* 世界設定の定義 */
create table field_root (
  serial      integer primary key auto_increment,
  
  eqnserial   integer not null,
  
  description integer default 0 references description (serial)
);

/* 式(式自体が関係)の定義 */
create table equation_root (
  serial      integer primary key auto_increment,
  /* unique が使えない... */
  eqnpart     text not null,
  eqnsymb     text,
  /* 世界設定(どの世界で考える?) */
  field       integer default 0 references field_root (serial),
  
  description integer references description (serial)
);

/* 式と式の関係演繹の定義 - 本当の定義はもっと上の階層も? */
create table relation_root (
  serial      integer primary key auto_increment,
  eqnin       integer not null default 0 references equation_root (serial),
  eqnout      integer not null default 0 references equation_root (serial),
  eqnstate    integer default 0 references relation_root (serial),
  /* -1, -2, ...: new variable, 0: destroy,  in -> out*/
  tranpose    text not null,
  direction   integer not null,
  /* is this valid ? */
  valid	      integer,
  ndepth      integer,
  
  field       integer default 0 references field_root (serial),
  
  description integer default 0 references description (serial)
);

/* 関係リストとその他(物理探索...?) */
create table world_root (
  serial      integer primary key auto_increment,
  w_next      integer default 0 references world_root (serial),
  w_prev      integer default 0 references world_root (serial),
  
  eqnpart     text not null,
  tranpose    text not null
);

create table world (
  id   	      integer primary key auto_increment,
  
  contain     integer default 0 unique references world_root (serial),
  description integer default 0 references description (serial)
);

/* ステータステーブル */
/*
create table status (
  equation_root  integer,
  relation_root  integer,
  relation_eqn   integer,
  eqndepth_root  integer,
  eqndepth_depth integer,
  world_root     integer
);
*/