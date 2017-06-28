#! /usr/local/bin/ruby

require 'wrapper.rb'

wrap = CWrapper.new

# フィールド定義(未完)
field = wrap.addField( "初等的な定義" )

# 加算とその拡張
wrap.addEqnDBSeed( "\\v+\\v", field, "加算" )
wrap.addEqnDBSeed( "\\v-\\v", field, "減算" )
wrap.addEqnDBSeed( "\\v\\cdot\\v", field, "積算" )
wrap.addEqnDBSeed( "\\v/\\v", field, "除算" )
wrap.addEqnDBSeed( "\\v^\\v", field, "冪算" )
wrap.addEqnDBSeed( "\\log_\\v\\v", field, "対数算" )
wrap.addEqnDBSeed( "\\exp\\v", field, "冪算の微分に対する自然な形" )
wrap.addEqnDBSeed( "\\log\\v", field, "対数算の微分に対する自然な形" )

# 三角関数とその拡張
wrap.addEqnDBSeed( "\\sin\\v", field, "正弦" )
wrap.addEqnDBSeed( "\\cos\\v", field, "余弦" )
wrap.addEqnDBSeed( "\\tan\\v", field, "正接" )
wrap.addEqnDBSeed( "\\csc\\v", field, "余割(正弦の逆数)" )
wrap.addEqnDBSeed( "\\sec\\v", field, "正割(余弦の逆数)" )
wrap.addEqnDBSeed( "\\cot\\v", field, "余接(正接の逆数)" )
wrap.addEqnDBSeed( "\\asin\\v", field, "正弦の逆" )
wrap.addEqnDBSeed( "\\acos\\v", field, "余弦の逆" )
wrap.addEqnDBSeed( "\\atan\\v", field, "正接の逆" )
wrap.addEqnDBSeed( "\\acsc\\v", field, "余割(正弦の逆数)の逆" )
wrap.addEqnDBSeed( "\\asec\\v", field, "正割(余弦の逆数)の逆" )
wrap.addEqnDBSeed( "\\acot\\v", field, "余接(正接の逆数)の逆" )

# 微積分
wrap.addEqnDBSeed( "\\int_\\v^\\v\\v d\\v", field, "積分" )

wrap.addEqnDBSeed( "\\frac{d}{d\\v}\\v", field, "これから微分" )

wrap.addEqnDBSeed( "\\frac{d\\v}{d\\v}", field, "微分後" )


# 繰り返し算
wrap.addEqnDBSeed( "\\Sigma_{\\v=\\v}^\\v\\v", field, 
                   "加算の繰り返し" )

wrap.addEqnDBSeed( "\\Sigma_{\\v=\\v}\\v", field, "総和")

wrap.addEqnDBSeed( "\\Gamma_{\\v=\\v}^\\v\\v", field,
                   "積算の繰り返し" )

# 順列組み合わせ(繰り返し算の特殊な場合)
wrap.addEqnDBSeed( "\\P[\\v,\\v]", field, "順列" )
wrap.addEqnDBSeed( "\\C[\\v,\\v]", field, "組み合わせ" )
wrap.addEqnDBSeed( "\\H[\\v,\\v]", field, "円順列" )
wrap.addEqnDBSeed( "\\v!", field, "階乗" )

# 単位元
wrap.addEqnDBSeed( "0", field, "加法単位元" )
wrap.addEqnDBSeed( "1", field, "乗法単位元" )
wrap.addEqnDBSeed( "\\infty", field, "無限大(不思議な単位元)" )

# 関数一般系
wrap.addEqnDBSeed( "f[\\v]", field, "関数(1変数)" )

wrap.addEqnDBSeed( "\\v_\\v", field, "数列" )

# 複素数(experimental)
wrap.addEqnDBSeed( "\\I", field, "復素単位元" )

$mysql.close
