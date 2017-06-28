/* add privilege for me */
insert into user (Host,User,Password)
  values ('localhost', 'searcheqn', PASSWORD('yukinagato'));
insert into db
  (Host,Db,User,Select_priv,Insert_priv,Update_priv,Delete_priv,
   Create_priv,Drop_priv)
   values ('localhost', 'test_seqn1','searcheqn','Y','Y','Y','Y','Y','Y');
create database test_seqn1;
flush privileges;
