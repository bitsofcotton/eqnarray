#! /usr/bin/env ruby

require 'equation.rb'
require 'deduction.rb'
require 'wrapper.rb'

eqn  = CEquation.new()
ded  = CDeduction.new()
wrap = CWrapper.new()

eqin  = CEquation.new()
eqout = CEquation.new()

eqin.parse("a+0")
p eqin.geteqn
p eqin.maxPatternSeed( 2 )

p ded.addEqnRelations( 10 )

$mysql.close()
