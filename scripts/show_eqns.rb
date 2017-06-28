#! /usr/local/bin/ruby

require 'deduction.rb'

eqn = CEquation.new

buf = $mysql.query("select id from equation_node order by id desc limit 1;")

id = -1
id = ARGV[0].to_i if( ARGV[0] != nil )

if(id > 0)
  eqn.read(id)
  eqn.printEqn( 2 ) if eqn.geteqn != nil
else
  (buf.fetch_hash['id'].to_i - 1).times do |i|
    eqn.read(i + 1)
    eqn.printEqn( 2 ) if eqn.geteqn != nil
  end
end

$mysql.close
