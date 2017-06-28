/* すべてのテーブルをクリアして */
drop table description;
drop table field_root;
drop table equation_root;
drop table relation_root;
drop table world_root;
drop table world;
/* drop table status; */

/* 初期化 */
source db.sql;

/* データ自体も初期化 */
/* insert into status values (0, 0, 0, 0, 0, 0); */
