#! /usr/bin/env ruby

=begin
= Search Equation
=end

require 'dbent.rb'
require 'equation.rb'

class CDeduction
  def initialize()
    @eqin      = []
    @eqout     = []
    @eqstate   = nil
    @tranpose  = []
    @direction = 1
    @depth     = -1
    @valid     = 0
  end

  def setrel( eqin, eqout, eqstate, tranpose, direction, valid )
    @eqin      = eqin
    @eqout     = eqout
    @eqstate   = eqstate
    @tranpose  = tranpose
    @direction = direction
    @valid     = valid
  end

  def setDepth( depth )
    @depth = depth
  end

  def getrel()
    # shallow 故, 意味ないかも...(dup)
    return [@eqin.dup, @eqout.dup, @eqstate, @tranpose.dup,
            @direction]
  end

=begin
= 読み書き
=end
  def read( serial )
    eqn = CEquation.new
    
    buf = $mysql.query("select * from relation_node where id = #{ serial };")
    hsh = buf.fetch_hash

    if( hsh == nil )
      @eqin      = nil
      @eqout     = nil
      @eqstate   = nil
      @tranpose  = nil
      @depth     = -1
      @direction = 1
      return false
    end

    @eqin      = eqn.readList($mysql.query("select eqnpart from equation_node where id = #{hsh['eqnin']};").fetch_hash['eqnpart'])[0][0]
    @eqout     = eqn.readList($mysql.query("select eqnpart from equation_node where id = #{hsh['eqnout']};").fetch_hash['eqnpart'])[0][0]
    if(hsh['eqnstate'] != nil)
      @eqstate   = $mysql.query("select id from relation_node where id = #{hsh['eqnstate']};").fetch_hash['id'].to_i
    else
      @eqstate   = nil
    end
    @tranpose  = eqn.readList(hsh['transpose'])[0][0]
    @direction = hsh['direction'].to_i
    return true
  end

  def write( depth, field, description, ad )
    # equation へのリンクの準備
    eq = CEquation.new
    eq.seteqn( @eqin )
    serial_in = eq.search()
    if( serial_in == nil )
      # 抑制
      return false if(@depth > 0 and eq.getHeight( @eqin ) > @depth)
      eq.write( nil, 3, nil )
      serial_in = eq.search()
    end
    serial_in = serial_in.to_s

    eq.seteqn( @eqout )
    serial_out = eq.search()
    if( serial_out == nil )
      # 抑制
      return false if(@depth > 0 and eq.getHeight( @eqout ) > @depth)
      eq.write( nil, 3, nil )
      serial_out = eq.search()
    end
    serial_out = serial_out.to_s

    if( @eqstate != nil )
      serial_state = @eqstate
      serial_squery = "= #{@eqstate}"
    else
      serial_state  = " null "
      serial_squery = "is null"
    end
    
    begin
      exists = $mysql.query("select id, description from relation_node where eqnin = #{ serial_in } and eqnout = #{ serial_out } and eqnstate #{ serial_squery };")
      line = exists.fetch_hash()
      if( line != nil )
        # refresh depth if needed.

        # refresh description
        if(line['description'] == nil && description != nil)
          $mysql.query("insert into description (dtext) values ('#{description}');")
          $mysql.query("update relation_node set description = (select id from description order by id desc limit 1) where id = #{line['serial']};")
        elsif(line['description'] != nil && description != nil)
          back = nil
          nxt = line['description']
          while( nxt != nil )
            back = nxt
            res = $mysql.query("select p_next from description where id = #{nxt};")
            nxt = res.fetch_hash['p_next']
          end
          $mysql.query("insert into description (p_next, p_prev, dtext) values (null, #{back}, '#{description}');")
        $mysql.query("update description set p_next = (select id from description order by id desc limit 1) where id = #{back};")
        end
        return true
      end
      return false if(field == nil)
      
      if( description != nil )
        $mysql.query("insert into description (dtext) values ('#{description}');")
        $mysql.query("insert into relation_node (eqnin, eqnout, eqnstate, transpose, direction, field, description) values (#{ serial_in }, #{ serial_out }, #{ serial_state }, '#{ eq.writeList( @tranpose ) }', #{ @direction }, #{ field }, (select id from description order by id desc limit 1));")
      else
        $mysql.query("insert into relation_node (eqnin, eqnout, eqnstate, transpose, direction, field) values (#{ serial_in }, #{ serial_out }, #{ serial_state }, '#{ eq.writeList( @tranpose ) }', #{ @direction }, #{ field });")
      end
    rescue
      nil
    end
    return true
  end

=begin
= 言い換え、置き換え (指定)
=end
  # 二つの部分式が一致するか (変数除く)
  # matches eqn1 > eqn2
  # eg. eqn1 = [1, [-1, 1], [-1, 2]]
  #     eqn2 = [1, [-1, 1], [1, [-1, 2], [-1, 3]]]
  #  matches
  #
  # returns [ matched?, array_of_variable_matched_left_to_right,
  #                     array_of_variable_number_before_matched ]
  def matchListore( eqn1, eqn2 )
    result = [true, [], []]
#    p eqn1, eqn2
    if( eqn1[0] < 0 )
      result[1] << eqn2
      result[2] << eqn1[1]
      return result
    end
    result[0] &= eqn1[0] == eqn2[0]
    if( result[0] == true and
        eqn1.size >= 2 )
      (eqn1.size - 1).times do |i|
        buf = matchops?( eqn1[ i + 1 ], eqn2[ i + 1 ] )
        result[0] &= buf[0]
        buf[1].each do |b|
          result[1] << b
        end
        buf[2].each do |b|
          result[2] << b
        end
        break if( result[0] == false )
      end
    end
    return result
  end

  def matchops?( eqn1, eqn2 )
    result = matchListore( eqn1, eqn2 )
    return result if result[0] == false
    buf = []
    result[2].size.times do |v|
      buf << result[2][v]
      buf << result[1][v]
    end
    hash = Hash[*buf]
#    p hash, result
    result[2].size.times do |v|
      return [false, [], []] if( result[1][v] != hash[result[2][v]] )
    end
    return result
  end

  # 出力ひな形と置き換えパターンから置き換える
  def makeReplaced( eqout, variables, tranpose, last )
    result = [ eqout[0] ]
    if( eqout[0] < 0 )
      if( tranpose[ eqout[1] - 1 ] != nil and
          variables[ tranpose[ eqout[1] - 1 ] - 1 ] )
        result = variables[ tranpose[ eqout[1] - 1 ] - 1 ]
      else
        result << last[0]
        tranpose[ eqout[1] - 1 ] = last[0]
        variables[ tranpose[ eqout[1] - 1] - 1] = [ -1, last[0] ]
        last[0] += 1
      end
      return result
    elsif( eqout[1] == nil )
      return eqout.dup
    end
    eqout[1 .. -1].each do |eo|
      result << makeReplaced( eo, variables, tranpose, last )
    end
    return result
  end

  # tranpose => tranpose 作成
  def makeTranpose( intr, outr, newval )
    hash = []
    outr.size.times do |i|
      hash << outr[i]
      hash << i + 1
    end
    hash = Hash[*hash]

    result = []
    if( newval[0] < 0 )
      j      = -1
    else
      j      = newval[0]
    end
    intr.size.times do |i|
      if( hash[intr[i]] != nil )
        result << hash[intr[i]]
      else
        result << j
        hash.store( intr[i], j ) if intr[i] != nil
        if( newval[0] < 0 )
          j -= 1
        else
          j += 1
        end
      end
    end
    
    newval[0] = j if( newval[0] >= 0 )
    
    return result
  end

  # result = tr2[tr1[]]
  def compileTranpose( tr1, tr2, newval )
    if( tr1.size != tr2.size )
      print "not implemented"
    end
    result = []
    tr1.size.times do |i|
      if( tr2[tr1[i] - 1] != nil )
        result << tr2[tr1[i] - 1]
      else
        result << newval[0]
        newval[0] = newval[0] + 1
      end
    end
    return result
  end

  # reverses tranpose
  def reverseTranpose( tranpose, size )
    # 使われていない変数の列挙
    compl = []
    tranpose.size.times do |i|
      compl << i + 1
    end
    tranpose.each do |tr|
      compl.delete( tr )
    end
    compl.compact!

    # ハッシュ
    hash = []
    j = 0
    tranpose.size.times do |i|
      if( tranpose[i] >= 0 )
        hash << tranpose[i]
      else
        hash << compl[ - tranpose[j] - 1 ]
        j += 1
      end
      hash << i + 1
    end
    hash = Hash[*hash]

    # 置き換え
    result = []
    val    = -1
    size.times do |i|
      if( hash[i + 1] != nil )
        result << hash[i + 1]
      else
        result << val
        val -= 1
      end
    end
    
    return result
  end

  # 演繹(この場合は単なる置き換え)
  # relation = [ eqnin, eqnout, transpose, depth, direction ]
  def _replaceFromSeed( eqn, relation, seed, newval )
    i = 1
    eqn[1 .. -1].each do |e|
      res = matchops?( relation[0], e )
#      p res
      if( res[0] == true )
        if( seed[0] % 2 == 1 )
          rpld = makeReplaced( relation[1], res[1], relation[2], newval )
#          p e, relation[1], res[1], relation[2], rpld

          eqn.delete_at( i )
          eqn.compact!
          eqn.insert( i, rpld )
          seed[0] = seed[0] / 2 
        else
          seed[0] = seed[0] / 2
          _replaceFromSeed( e, relation, seed, newval ) if( e[0] >= 0 )
        end
      elsif( e[0] >= 0 )
        _replaceFromSeed( e, relation, seed, newval )
      end
      i += 1
    end
    return eqn
  end

  def replaceFromSeed( eqn, relation, seed, newval)
    tranpose = []
    relation[2].size.times do |tri|
      tranpose << tri
      tranpose << relation[2][tri]
    end
    return _replaceFromSeed( [0, eqn],
                             [relation[0], relation[1],
                              Hash[*tranpose], relation[3],
                              relation[4]],
                             [seed], newval )[1]
  end

=begin
= 言い換え、置き換え (自動自走)
=end
  # eqnseed を使った総当たり書き換え
  def _addRelation1( eqnseed, num, rdepth )
    eqnin = CEquation.new
    eqnin.read( num )
    if( eqnin.geteqn == nil )
      return []
    end
    
    result = []
    
    first = eqnin.geteqn
    eqnin.read( num )
    i = 1
    while( true )
      buf = replaceFromSeed( eqnin.geteqn, eqnseed, i,
                             [eqnin.listVariable(eqnin.geteqn).size + 1] )
      break if( first == buf )
      eqnin.read( num )
      
#      p buf
      
      wrap = CEquation.new
      temp = CDeduction.new
      wrap.seteqn( buf )
      print "found new relation #{eqnin.printEqn(3)} =>" +
        "#{wrap.printEqn(3)} !! adding...\n"
      tranpose = makeTranpose( wrap.listVariable( buf ),
                               wrap.listVariable( eqnin.geteqn ),
                               [-1] )
      tranpose = reverseTranpose( tranpose,
                                  wrap.listVariable( buf ).size )
      wrap.seteqn( wrap.rewriteUnique(buf) )
      temp.setrel( eqnin.geteqn, wrap.geteqn, eqnseed[3],
                   tranpose, 1, 1)
      temp.write( rdepth, 3, nil, nil )
      
      result << wrap.search()
      
      i = i + 1
    end
    
    return result.compact
  end

  def addRelation1( continue, eqnseed, rdepth )
    return if eqnseed[0] == nil
    
    eqn = CEquation.new
    
    regex = "^.*"
    flag = 0
    buf = eqn.writeList( eqnseed[0] )
    buf.size.times do |chi|
      ch = buf[chi .. chi]
      case ch
      when '['
#        regex += "\\["
        flag = 1
      when /[0-9]/
        regex += ch if( flag == 1 )
      when '-'
        flag = 0
      else
        regex +=  ch + ".*" if( flag == 1 )
        flag = 0
      end
    end
    
    res = $mysql.query("select id, eqnpart from equation_node where eqnpart regexp '#{regex}' and eqnsymb is null;")
    
    print "#{res.num_rows} equations found.\n"
    i = 0
    res.data_seek(i)
    while( i < res.num_rows )
      resfh = res.fetch_hash
      if( resfh != nil)
        eqnseed << resfh['eqnpart']
        _addRelation1( eqnseed, resfh['id'], rdepth )
        eqnseed.pop
      end
      i += 1
    end
  end

  def addRelations1()
    res  = $mysql.query("select id from relation_node order by id desc limit 1;")
    ends = res.fetch_hash['id'].to_i
    
    print "#{ends} relations found.\n"
    i = 1
    while( i < ends )
      print "now searching relation #{i}...\n"
      read( i )
      addRelation1( false, [@eqin, @eqout, @tranpose, i ], @depth + 1 )
      i += 1
    end
  end

  def addRelations( depth )
    depth.times do |i|
      print "now searching relation (#{i + 1} / #{depth} depth)\n"
      addRelations1()
    end
  end
  
  def _addEqnRelations( serial, depth, continue )
    res  = $mysql.query("select id from relation_node order by id desc limit 1;")
    ends = res.fetch_hash['id'].to_i
    
    print "#{ends} relation found.\n"
    n = [serial]
    depth.times do |none|
      print "   now #{none + 1} depth.\n"
      r = n
      n = []
      r.each do |ser|
        i = 1
        while( i < ends )
          read( i )
          n << _addRelation1([@eqin, @eqout, @tranpose, i ] , ser, @depth + 1 )
          i = i + 1
        end
      end
      n.flatten!
      n.uniq!
   end
  end
  
  def addEqnRelations( depth, continue )
    res = $mysql.query("select id from equation_node order by id desc limit 1;")
    ends = res.fetch_hash['id'].to_i
    
    print "#{ends} equation found, now we do #{depth} depth deduction.\n"
    i = 1
    eqn = CEquation.new
    while( i < ends )
      if(eqn.read( i ) != nil)
        _addEqnRelations( i, depth, continue )
      end
      i = i + 1
    end
  end

 def rewriteOutputFromTranpose()
    res = [0]
    @tranpose.each do |tr|
      res << tr
    end
    wrap = CEquation.new
    wrap.seteqn( @eqout )
    wrap.replaceVariable( @eqout, res )
    @eqout = wrap.geteqn()
  end

=begin
= 書き出し
=end
  def printRel( mode )
    case( mode )
    when 2
      wrap = CEquation.new
      wrap.seteqn( @eqin )
      wrap.printEqn( 2 )
      rewriteOutputFromTranpose()
      wrap.seteqn( @eqout )
      wrap.printEqn( 2 )
      if( @eqstate == nil )
        print " (definition) \n"
      else
        print "   from #{@eqstate}\n"
      end
    when 3
      result = ""
      result += printRel( -3 )
      if( @eqstate == nil )
        result += "  ($definition$)\n"
      else
        wrap = CDeduction.new
        wrap.read( @eqstate )
        result += " $from$  ( " + wrap.printRel( -3 ) + " )\n"
      end
    when -3
      result = ""
      
      wrap = CEquation.new
      wrap.seteqn( @eqin )
      result = wrap.printEqn( 3 )
      rewriteOutputFromTranpose()
      wrap.seteqn( @eqout )
      result += "   =>   " + wrap.printEqn( 3 )
      return result
    end
  end
end
