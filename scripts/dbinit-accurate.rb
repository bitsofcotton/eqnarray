#! /usr/local/bin/ruby

require 'equation.rb'
require 'deduction.rb'

eqn = CEquation.new()
ded = CDeduction.new()

ded.setDepth( 5 )
while(1)
  ded.addRelations( 1 )
end
