#! /usr/local/bin/ruby

require 'equation.rb'
require 'deduction.rb'

eqn = CEquation.new()

while( 1 )
  7.times do |i|
    print "adding equation_root for #{i + 4}\n"
    eqn.storeall( i + 4 )
  end
end
