#! /usr/local/bin/ruby

require 'deduction.rb'

ded  = CDeduction.new
ebuf = CEquation.new

buf = $mysql.query("select id from relation_node order by id desc limit 1;")

max = 0
(buf.fetch_hash['id'].to_i - 1).times do |i|
  path = 1
  id   = i + 1

  eq = []

  while(1)
    ded.read(id)
    eqb = []
    ebuf.seteqn( ebuf.readList( "#{ded.getrel[0].inspect}" )[0][0] )
    eqb << ebuf.printEqn(3)
    ebuf.seteqn( ebuf.readList( "#{ded.getrel[1].inspect}" )[0][0] )
    eqb << ebuf.printEqn(3)
    eqb << id
    eq << eqb
    eqs = ded.getrel[2]
    break if(eqs == nil)
    path = path + 1
    id = eqs
  end

  print " "
  if( max <= path )
    max = path
    print "max: " + max.to_s + ": " + eq.inspect + "\n"
  end
end

$mysql.close
