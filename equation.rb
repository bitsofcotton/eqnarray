#! /usr/bin/env ruby

=begin
== to treat equations as calculatiable...
=end

require 'dbent.rb'

class CEquation
=begin
= データベースとの兼ね合い
=end
  # @normal_parse のソート
  def sortParse()
    changed = 1
    while( changed == 1 )
      buf = []
      @normal_parse.each do |np|
        buf << Regexp.compile(
          (Regexp.quote(np[0]).gsub(/\\v([^a-zA-Z]|$)/){ ".*" + $1}))
      end
      
      changed = 0
      @normal_parse.size.times do |i|
        # buf[j] で比較、マッチしたら先頭に
        @normal_parse.size.times do |j|
          next if ( j <= i )
          @normal_parse[i][0].scan(buf[j])
          if( Regexp.last_match    != nil &&
              Regexp.last_match[0] != "" )
            # j を終端へ
            tmp = @normal_parse[j]
            @normal_parse.delete_at(j)
            @normal_parse.compact!
            @normal_parse.insert(0, tmp)
            changed = 1
          end
        end
      end
    end
  end

  # 式パーズ時に使ういろいろ 今は概念体系共々ごちゃ混ぜ
  def initParse()
    # @normal_parse 取得
    @normal_parse = []
    n = $mysql.query("select eqnsymb, eqnpart from equation_node where eqnsymb != '';");
    n.each_hash do |res|
      res1 = [res['eqnsymb']]
      res1 << readList(res['eqnpart'])[0][0]
      @normal_parse << res1
    end
    
    # parse の不具合解消
    sortParse()
    @normal_parse.reverse!


    # @normal_parse => @rev_normal_parse
    hashseed  = []
    i = 0
    @normal_parse.each do |np|
      hashseed  << np[1][0]
      hashseed  << i
      i = i + 1
    end
    @rev_normal_parse = Hash[*hashseed]
  end

  # temporary
  def initialize()
    # 自分の持っている式
    @eqns    = []
    
    # 変数名の管理
    @valname = "@abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    hshc = []
    @valname.size.times do |i|
      hshc << @valname[i .. i]
      hshc << i
    end
    @revaln  = Hash[*hshc]
    
    # 式表現中のデリミタ
    @nondelimiter = "([^,]*)"

    initParse()
  end

  # "[1, [2, 3], 1, 2]" => [1, [2, 3], 1, 2]
  def readList( string )
    i        = 0
    flag     = 0
    mflag    = 0
    delim    = 0
    buf      = 0
    resarray = []
    while( i < string.size )
      case string[i .. i]
      when '-'
        mflag = 1
      when /[0-9]/
        flag  = 1
        buf   = buf * 10 + string[i .. i].to_i
      when '['
        res = readList(string[i + 1 .. -1])
        resarray << res[0]
        i += res[1] + 1
        delim = 1
      when ' '
      else
        resarray << (mflag == 0 ? buf : -buf) if delim != 1
        mflag = 0
        flag  = 0
        buf   = 0
        case string[i .. i]
        when ']'
          return [resarray, i]
        end
      end
      i += 1
    end
    return [resarray, i]
  end

  # [1, [2, 3], 1, 2] => "[1, [2, 3], 1, 2]"
  def writeList( array )
    return "#{array.inspect}"
  end

=begin
= 入出力?
=end
  # set equation in the CEquation
  def seteqn( eqn )
    @eqns = eqn.dup
  end

  # get equation from the CEquation
  def geteqn
    return @eqns
  end

  def read( serial )
    result = $mysql.query("select eqnpart from equation_node where id = #{serial} and eqnsymb is null;")
    buf = result.fetch_hash
    if(buf != nil && buf['eqnpart'] != nil)
      @eqns = readList(buf['eqnpart'])[0][0]
    else
      @eqns = nil
    end
    return @eqns
  end

  def write( symbol, field, description )
    begin
      exists = $mysql.query("select id, description from equation_node where eqnpart = '#{writeList( @eqns )}';")
      line = exists.fetch_hash()
      if(line != nil)
        if(line['description'] == nil && description != nil)
          $mysql.query("insert into description (dtext) values ('#{description}');")
          $mysql.query("update equation_node set description = (select id from description order by id desc limit 1) where id = #{line['serial']};")
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
      
      # okay?
      if( symbol == nil )
        symbol = "null"
      else
        symbol = "'#{$mysql.quote(symbol) }'"
      end
      if( description != nil )
        $mysql.query("insert into description (dtext) values ('#{description}');")
        $mysql.query("insert into equation_node (eqnpart, eqnsymb, field, description) values ('#{ writeList(@eqns) }', #{ symbol }, #{ field }, (select id from description order by id desc limit 1));")
      else
        $mysql.query("insert into equation_node (eqnpart, eqnsymb, field) values ('#{ writeList(@eqns) }', #{ symbol }, #{ field });")
      end
    rescue
      nil
    end
    return true
  end

  def search()
    res = $mysql.query("select id from equation_node where eqnpart = '#{ writeList( @eqns )}' and eqnsymb is null;")
    hsh = res.fetch_hash
    if( hsh == nil)
      return nil
    else
      return hsh['id'].to_i
    end
  end

=begin
= 演繹の順序を考える
  def getNext( root )
    root[1 .. -1].each do |r|
      if(r[0] < 0)
        return root
      else
        res = getNext( r )
        return res if res != nil
      end
    end
    return nil
  end
=end

  # 上限を押さえる
  def maxPatternSeed( n_func )
    npin = []
    @normal_parse.each do |npe|
      npin << npe[1].size - 1
    end
    npin.sort!.reverse!
    
    result = @normal_parse.size
    (n_func - 1).times do |i|
      result *= @normal_parse.size * npin[0]
    end
    
    return result
  end

  # ランダム、ブルートフォースの式ゲット
  # ゲーデル数に一対一でない ことは憂慮。
  def getFromSeed( n_func, n_val_max, seed )
    # number of function's variable
    nf = []
    @normal_parse.each do |np|
      nf << np[1].size - 1
    end
    
    # create leaf
    j = 0
    loutc = []
    n_func.times do |i|
      loutc <<
        @normal_parse[seed % @normal_parse.size][1]
      seed = seed / @normal_parse.size
    end
    
    # create complete leaf
    cleafc = []
    if(n_val_max < 0)
      k = 1
      loutc.each do |l|
        ll = [l[0]]
        if(l.size >= 2)
          l[1 .. -1].each do |item|
            ll << [-1, k]
            k = k + 1
          end
        end
        cleafc << ll
      end
    else
      loutc.each do |l|
        ll = [l[0]]
        if(l.size >= 2)
          l[1 .. -1].each do |item|
            ll << [-1, seed % n_val_max + 1 ]
            seed = seed / n_val_max
          end
        end
        cleafc << ll
      end
    end
    
    # create equation
    return rewriteUnique(cleafc[0]) if( n_func == 1 )
    return nil if( cleafc[0].size < 2 )
    stack = [cleafc[0]]
    m = 0
    cleafc[1 .. -1].each do |cl|
      lp = stack.last
      # 指定場所に挿入
      if(nf[@rev_normal_parse[lp[0]]] != 0)
        index = seed % nf[@rev_normal_parse[lp[0]]] + 1
        seed = seed / nf[@rev_normal_parse[lp[0]]]
        if(lp[index][0] < 0)
          # 書き換え
          lp.delete_at( index )
          lp.compact!
          lp.insert( index, cl )
          stack.push( cl )
          if( seed % 2 == 1 )
            seed = seed / 2
            if(lp != cleafc[0])
              stack.pop
            else
              return nil
            end
          end
          m = m + 1
          next
        end
      else
        if(lp != cleafc[0])
          stack.pop
        else
          return nil
        end
        redo
      end
      # 出来なければその下の階層を見つけて
      flag  = 1
      index = 1
      lp[1 .. -1].each do |lll|
        if(lll[0] < 0)
          lp.delete_at( index )
          lp.compact!
          lp.insert( index, cl )
          stack.push( cl )
          if( seed % 2 == 1 )
            seed = seed / 2
            if(lp != cleafc[0])
              stack.pop
            else
              return nil
            end
          end
          flag = 0
          break
        end
        index += 1
      end
      # なければ戻る
      if(flag == 1)
        if(lp != cleafc[0])
          stack.pop
        else
          return nil
        end
        redo
      end
    end
    
    cleafc[0] = rewriteUnique(cleafc[0]) if(n_val_max < 0)
    return cleafc[0]
  end

  # ランダムな式
  def random( n_leaf, n_val, rand_max )
    # 式のみ
    if(n_val >= 0)
      @eqns = getFromSeed( rand(n_leaf) + 1, rand(n_val) + 1, 
                           rand(rand_max) * rand(rand_max) )
    else
      @eqns = getFromSeed( rand(n_leaf) + 1, -1, 
                           rand(rand_max) * rand(rand_max) )
    end
    return @eqns
  end

  def registerAllValPattern( eqnseed )
    wrap = CEquation.new
    wrap.seteqn( eqnseed )
#    return false if( wrap.search() != nil )
    wrap.write( nil, 3, nil )
    
    nvals = wrap.listVariable( wrap.geteqn ).size
    return true if( nvals < 2 )
    # 2 -> n(n+1)/2
    # 3 -> ~n^3
    # 4 -> ~n^4
    # k times -> n+n^2+n^3+...+n^k = (n^(k+1)-n)/(n-1) ??
    nvals.times do |i|
      i = i + 1
      # i 個の変数を重複させる
      (2 ** (nvals * 2)).times do |j|
        cache = []
        i.times do |ste|
          buf = []
          nvals.times do |k|
            if( cache.flatten.include?( k + 1 ) != true )
              buf << k + 1 if ( j % 2 == 1 )
              j = j / 2
            end
          end
          cache << buf
        end
        flag = 0
        cache.each do |b|
          flag = 1 if b.size >= 2
        end
        next if flag == 0
        
        pato = []
        k    = 1
        cache.each do |c|
          c.each do |b|
            pato << b
            pato << k
          end
          k = k + 1
        end
        pat = Hash[*pato]
        l = 0
        nvals.times do |k|
          pat[ k + 1 ] = nvals + k if pat[ k + 1 ] == nil
        end
        
        wrap.seteqn( wrap.readList( wrap.writeList( eqnseed) )[0][0] )
        wrap.replaceVariable( wrap.geteqn, pat )
        wrap.seteqn( wrap.rewriteUnique( wrap.geteqn ) )
        wrap.write( nil, 3, nil )
      end
    end
    # 遅すぎて使い物にならない...重複が大多数
=begin
    ((nvals - 1) ** (nvals - 1)).times do |i|
      j = nvals + 1
      ib = i
      pat = [0]
      nvals.times do |b|
        buf = ib % (nvals - 1)
        ib  /= (nvals - 1)
        if( buf != 0  )
          pat << buf
        else
          pat << j
          j += 1
        end
      end
      wrap.seteqn( wrap.readList( wrap.writeList(eqnseed) )[0][0] )
      wrap.replaceVariable( wrap.geteqn, pat )
      wrap.seteqn( wrap.rewriteUnique( wrap.geteqn ) )
      next if wrap.search() != nil
      wrap.write( nil, 3, nil )
    end
=end
  end

  # 全リスト(指定以下の複雑さ)
  def storeall( n_func, index = 0 )
    max = maxPatternSeed( n_func )
    if( index > 0)
      i = index
    else
      i = 0
    end
    while ( i < max )
      @eqns = getFromSeed( n_func, -1, i )
      next if(getHeight( @eqns ) > n_func)
      if( @eqns )
        print "adding new equation pattern:"
        printEqn( 2 )
        registerAllValPattern( @eqns )
      end
      i += 1
    end
    return max
  end

=begin
= 上記で一意性を保つ
=end
  # list up variable list
  def listVariable( eqn )
    return [eqn[1]] if eqn[0] < 0
    result = []
    return [] if(eqn.size < 2)
    eqn[1 .. -1].each do |e|
      if(e[0] < 0)
        # infact each e
        result << e[1]
      else
        result << listVariable( e )
        result.flatten!
      end
    end
    # delete duplicates
    result.uniq!

    # result.
    return result
  end

  # replace variable number
  def replaceVariable( eqn, repl_pat )
    return if(eqn.size < 2)
    if( eqn[0] < 0 )
      val = repl_pat[ eqn[1] ]
      eqn.insert( 1, val )
      eqn.delete_at( 2 )
      eqn.compact!
      return
    end
    eqn[1 .. -1].each do |e|
      if( e[0] < 0 )
        i = 1
        while( i < e.size )
          val = repl_pat[ e[i] ]
          e.insert( i, val )
          e.delete_at( i + 1 )
          e.compact!
          i = i + 1
        end
      else
        replaceVariable(e, repl_pat)
      end
    end
  end

  # make hash
  def makeHash( list )
    result = []
    i = 1
    list.each do |l|
      result << l
      result << i
      i = i + 1
    end
    return Hash[*result]
  end

  # rewrite unique
  def rewriteUnique( eqn )
    replaceVariable( eqn, makeHash( listVariable( eqn ) ) )
    return eqn
  end

=begin
= 以下は TeX 書式との兼ね合い
=end
=begin
= 出力
=end
  # next @normal_parse syntax
  def scanNext( str, i )
    result = ""
    flag   = 0
    while( i < str.size )
      npc = str[i .. i]
      case npc
      when "\\"
        result += "\\"
        if(flag != 1)
          flag = 1
          i   += 1
          next
        end
      when "v"
        result.chop!
        if(flag == 1)
          return [result, i + 1, 'v']
        end
      when "u"
        result.chop!
        if(flag == 1)
          return [result, i + 1, 'u']
        end
      end
      result += npc
      i = i + 1
      flag = 0
    end
    return [result, i, '']
  end

  def _printHuman( root )
    return " " + @valname[ root[1], 1] + " " if( root[0] < 0 )
    if( "#{root.inspect}"[0, 1] != "[" )
      return "(" + @normal_parse[@rev_normal_parse[root]][0] + ")"
    elsif( root[1] == nil )
      return @normal_parse[@rev_normal_parse[root[0]]][0]
    end

    np = @normal_parse[@rev_normal_parse[root[0]]]
    resvals = []
    root[1 .. -1].each do |ph|
      if( ph[0] < 0 )
        resvals << " " + @valname[ph[1], 1] + " "
      elsif( @normal_parse[@rev_normal_parse[ph[0]]] != nil )
        resvals << "(" + _printHuman( ph ) + ")"
      else
        p "bug?? in printHuman"
      end
    end
    res    = scanNext( np[0], 0 )
    result = res[0]
    i      = res[1]
    j      = 1
    root[1 .. -1].each do |ph|
      res     = scanNext( np[0], i )
      result += resvals[np[1][j].to_i - 1] + res[0]
      i       = res[1]
      j      += 1
    end
    return " " + result + " "
  end

  # 出力
  def printEqn( mode )
    case mode
    when 1
      # left symb right
      @eqns[1 .. -1].each do |eqs|
        print _printHuman( eqs ) + "\n"
      end
    when 2
      print _printHuman( @eqns ) + "\n"
    when 3
      return _printHuman( @eqns )
    end
  end

=begin
= 入力
=end
  # マッチする為の正規表現
  def retAlphaChar( )
    pat = "([a-zA-Z][a-zA-Z0-9]*)"
    return [1, "(" + @nondelimiter + "|" + pat + ")",
            "(^" + pat + "$)?"]
  end

  def retAlphaNumChar( )
    pat = "(\^[0-9]+)?(_[0-9]+)?([a-zA-Z][a-zA-Z0-9]*)(\^[0-9]+)?(_[0-9]+)?"
    return [5, "(" + @nondelimiter + "|" + pat + ")",
            "(^" + pat + "$)?"]
  end

  def retNumChar( )
    pat = "([0-9]+)"
    return [1, "(" + @nondelimiter + "|" + pat + ")",
            "(^" + pat + "$)?"]
  end

  # 以下、パースへの関数群
  # マッチしたデータを吟味する
  def isAlpha( latex_eqn )
    return latex_eqn =~ Regexp.compile(retAlphaChar()[1])
  end

  def isAlphaNum( latex_eqn )
    return latex_eqn =~ Regexp.compile(retAlphaNumChar()[1])
  end

  def isNum( latex_eqn )
    return latex_eqn =~ Regexp.compile(retNumChar()[1])
  end

  # \v, \vn の置き換えと 正規表現の生成
  def parseParser( parser_input )
    v  = retAlphaChar()
    vn = retAlphaNumChar()
    
    result = []
    
    i = 0
    parser_input.each do |pin|
      temp = pin.dup
      temp[0] = "^(" + Regexp.quote( temp[0] )
      temp[0].gsub!("\\\\v\\\\v", "\\\\\\\\v +\\\\\\\\v")
#      temp[0].gsub!(/\\\\v([^a-zA-Z]|$)/) { v[1] + $1 }
#      temp[0].gsub!(/\\\\vn([^a-zA-Z]|$)/) { vn[1] + $1 }
      temp[0].gsub!(/\\\\v([^a-zA-Z]|$)/) {
        @nondelimiter + $1 }
      temp[0].gsub!(/\\\\vn([^a-zA-Z]|$)/) {
        @nondelimiter + $1 }
      temp[0] += ")$"
      
      temp[0] = Regexp.compile( temp[0] )
      temp << i
      result << temp
      i = i + 1
    end
    
#    result.each do |r| p r end
    return result
  end

  # 文字列から一意の変数名決定
  def parseValName( str )
    result = 0
    str.size.times do |i|
      result *~ @revaln.size
      result += @revaln[ str[i .. i] ] if @revaln[ str[i .. i] ]
    end
    return result
  end

  def parseVariable( str )
    # 変数only? ... 強く依存
    str   =~ Regexp.compile( retAlphaChar()[2] +
                                 retAlphaNumChar()[2] + retNumChar()[2] )
    match = Regexp.last_match.dup if Regexp.last_match
    if( match && match.size > 1 )
      if( match.to_a[1] != nil )
        return [-1, parseValName( match.to_a[1] ) ]
      elsif( match.to_a[2] != nil ||
          match.to_a[3] != nil ||
          match.to_a[4] != nil ||
          match.to_a[5] != nil ||
          match.to_a[6] != nil)
        vn   = 1
        retAlphaNumChar()[0].times do |i|
          if match[i + 2] != nil
            vn += parseValName(match[i + 2])
          end
        end
        return [ -1, vn ]
      elsif( match.to_a[7] != nil )
        return [0, parseValName( match.to_a[7] ) ]
      end
    end
    return nil
  end

  def simplifyPart( str )
    while( 1 )
      # 前後スペースを取り除く
      str.gsub!(/^[ ^t]+/) { }
      str.gsub!(/[ ^t]+$/) { }

      # () を取り除く
      if( str[0 .. 0] == "(" )
        # () の数え上げ
        if( str.count('(') == str.count(')'))
          # 最後の括弧と対応するか
          stack = ["("]
          lel   = 0
          str[1 .. -1].size.times do |le|
            ch = str[le + 1 .. le + 1]
            case ch
            when "("
              stack << ch
            when ")"
              stack.pop
            end
            lel = le
            break if stack == []
          end
          if( lel + 1 == str.size - 1 && str[-1 .. -1] == ')')
            str.reverse!.chop!
            str.reverse!.chop!
            next
          end
        else
          print "parse: parenthesis number not match.\n"
          return nil
        end
      end
      break
    end
    return str
  end

  # 肝心の式のパーズ
  def parsePart( latex_eqn, parser )
    return nil if( latex_eqn == nil )

    latex_eqn = simplifyPart( latex_eqn )
    
    result = parseVariable( latex_eqn )
    return result if result != nil

    # (), [], <> 内部のエスケープと構築
    buf  = ""
    tmp  = []
    tmp2 = ""
    vals = []
    flag = 0
    hashl = Hash[*[["[", 0], ["(", 1], ["<", 2], ["{", 3]]]
    hashr = Hash[*[["]", 0], [")", 1], [">", 2], ["}", 3]]]
#    p latex_eqn
    latex_eqn.size.times do |k|
      ch = latex_eqn[k .. k]
      case ch
      when "[", "(", "<", "{"
        tmp << ch
        if( tmp.size == 2 )
          flag = 1
        end
      when "]", ")", ">", "}"
        if(hashr[ch] != hashl[tmp.last])
          print "parse: parenthesis error (stack="#{tmp}", ch=#{ch})\n"
          return nil
        end
        
        tmp.pop
        if( tmp.size == 1 )
          vals << tmp2
          flag = 0
        end
      end
      if( flag == 1 )
        buf += ch + "."
        tmp2 = ""
        flag = 2
      elsif( flag == 2 )
        tmp2 += ch
      else
        buf += ch
      end
    end
    if( tmp != [] )
      print "parse: parenthesis error (stack=#{tmp}).\n"
      return nil
    end
    latex_eqn = buf
#    p latex_eqn, vals

    # パーズ
    parser.each do |ps|
      latex_eqn =~ ps[0]
      match = Regexp.last_match.dup if Regexp.last_match
      
#      p latex_eqn, ps[0]

      if( match &&  match.size > 1 && match.to_a[0] != "" &&
          match.to_a[1] != nil )
        valsm = @normal_parse[ps[2]][0].scan(/\\vn?/)

#        p match.to_a, vals

        # make tree
        result = [@normal_parse[ps[2]][1][0]]
        j = 2
        k = 0
        valsm.to_a.each do |vm|
#          p match.to_a[j]
          case vm
          when "\\v", "\\vn"
            if( match.to_a[j].include?("[") == true or
                match.to_a[j].include?("(") == true or
                match.to_a[j].include?("<") == true or
                match.to_a[j].include?("{") == true )
              path = ""
              match.to_a[j].size.times do |l|
                ch = match.to_a[j][l .. l]
                case ch
                when "."
                  path += vals[k]
                  k    += 1
                else
                  path += ch
                end
              end
#              p path, match.to_a, vals
              result << parsePart( path, parser)
            else
              result << parsePart( match.to_a[j], parser )
            end
            j += 1
          end
        end
        
        # tranpose
        buf = [ @normal_parse[ps[2]][1][0] ]
        @normal_parse[ps[2]][1][1 .. -1].each do |ptr|
          buf << result[ ptr ]
        end
        
        # return
        return buf
      end
    end
    
    print "parse error: not match\n"
    return nil
  end

  def getHeight( root )
    i = 1
    root[1 .. -1].each do |ph|
      if( ph[0] > 0 )
        i += getHeight( ph )
      else
        i += 1
      end
    end
    return i
  end

  def parse( latex_eqn )
    # parse parse expression
    parser = parseParser(@normal_parse)
#    latex_eqn = Regexp.quote( latex_eqn.dup )
#    latex_eqn.gsub!( "\\", "\\\\" )
    
    @eqns = parsePart( latex_eqn.gsub("(", "((").gsub(")", "))"), parser )
#    p @eqns
  end
end
