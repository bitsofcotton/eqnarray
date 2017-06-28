#! /usr/local/bin/ruby

require 'equation.rb'
require 'deduction.rb'

eqn = CEquation.new()

while( 1 )
  3.times do |i|
    print "adding equation_root for #{i + 1}\n"
    eqn.storeall( i + 1 )
  end
end
