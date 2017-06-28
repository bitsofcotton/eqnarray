#! /usr/local/bin/ruby

require 'equation.rb'
require 'deduction.rb'

class CWrapper
  def initialize()
    @eqn      = CEquation.new()
    @eqnin    = CEquation.new()
    @eqnout   = CEquation.new()
    @eqnstate = CEquation.new()
    @ded      = CDeduction.new()
  end

  def addField( description )
    $mysql.query("insert into description (dtext) values ('#{description}');")
    $mysql.query("insert into field_node (description) values ((select id from description order by id desc limit 1));")
    return $mysql.query("select id from field_node order by id desc limit 1;").fetch_hash['id'].to_i
  end

  def addEqnDBSeed( instr, field, description )
    # inpart
    res = $mysql.query("select id from equation_node order by id desc limit 1;")
    if( res.num_rows == 0 )
      inpart = [1]
    else
      inpart = [res.fetch_hash['id'].to_i + 1]
    end
    instr.scan(/\\v|\\r/).size.times do |i|
      inpart << i + 1
    end
    p inpart
    @eqn.seteqn( inpart )
    @eqn.write( instr, field, description )
  end

  def addDedDBSeed( instr, outstr, direction, field, description )
    @eqnin.parse( instr )
    @eqnout.parse( outstr )
    print "adding " + @eqnin.printEqn( 3 ) + "=>" + @eqnout.printEqn( 3 ) + "\n"
    tranpose = @ded.makeTranpose( @eqn.listVariable( @eqnin.geteqn ),
                                  @eqn.listVariable( @eqnout.geteqn ),
                                  [-1])
    @ded.setrel( @eqn.rewriteUnique(@eqnin.geteqn),
                 @eqn.rewriteUnique(@eqnout.geteqn), nil,
                 @ded.reverseTranpose( tranpose,
                                       @eqn.listVariable( @eqnout.geteqn ).size
                                       ),
                 direction, 1 )
    @ded.write( 0, field, description, nil )

    @eqnin.parse( instr )
    @eqnout.parse( outstr )
    direction = 3 - direction
    direction = 3 if direction <= 0
    tranpose = @ded.makeTranpose( @eqn.listVariable( @eqnout.geteqn ),
                                  @eqn.listVariable( @eqnin.geteqn ),
                                  [-1])
    @ded.setrel( @eqn.rewriteUnique(@eqnout.geteqn),
                 @eqn.rewriteUnique(@eqnin.geteqn), nil,
                 @ded.reverseTranpose( tranpose,
                                       @eqn.listVariable( @eqnout.geteqn ).size
                                       ),
                 direction, 1 )
    print "failed.\n" if(@ded.write( 0, field, description, nil ) == false)
  end
end
