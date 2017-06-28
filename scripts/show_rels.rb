#! /usr/local/bin/ruby

require 'deduction.rb'

ded = CDeduction.new

buf = $mysql.query("select id from relation_node order by id desc limit 1;")

id = -1
id = ARGV[0].to_i if( ARGV[0] != nil )

if( id > 0 )
  ded.read(id)
  ded.printRel( 2 )
else
  (buf.fetch_hash['id'].to_i - 1).times do |i|
    ded.read(i + 1)
    ded.printRel( 2 )
    print "\n"
  end
end

$mysql.close
