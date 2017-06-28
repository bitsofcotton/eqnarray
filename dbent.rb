# database entity

require 'mysql'

#$mysql = Mysql::connect(nil, "equation", "yukinagato", "equation")
$mysql = Mysql::connect(nil, "equation", "password", "user", nil, "/tmp/mysql.sock")
