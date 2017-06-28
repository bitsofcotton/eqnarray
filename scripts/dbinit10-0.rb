#! /usr/local/bin/ruby

require 'equation.rb'
require 'deduction.rb'

eqn = CEquation.new()

10.times do |i|
  print "adding equation_node for #{i + 1}\n"
  eqn.storeall( i + 1 )
end
