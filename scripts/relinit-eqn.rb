#! /usr/local/bin/ruby

require 'wrapper.rb'

wrap = CWrapper.new

field = wrap.addField( "初等的な関係と言い換え" )

# 四則演算冪乗様々な律
wrap.addDedDBSeed( "a + 0", "a", 3, field, "加法単位元" )
wrap.addDedDBSeed( "a - a", "0", 3, field, "加法逆元" )
wrap.addDedDBSeed( "a\\cdot 0", "0", 3, field, "乗法と加法" )
wrap.addDedDBSeed( "a\\cdot 1", "a", 3, field, "乗法単位元" )
wrap.addDedDBSeed( "a\\cdot(1/a)", "1", 3, field, "乗法逆元" )
wrap.addDedDBSeed( "(a\\cdot b)+b", "(a+1)\\cdot b", 3, field, "乗法仮定義" )
wrap.addDedDBSeed( "a/a", "1", 3, field, "除法単位元" )
wrap.addDedDBSeed( "a^0", "1", 3, field, "冪算単位元" )
wrap.addDedDBSeed( "a^1", "a", 3, field, "冪算単位元2" )
wrap.addDedDBSeed( "\\exp(\\log(a))", "a", 3, field, "冪算逆元" )
wrap.addDedDBSeed( "(a^b)\\cdot a", "a^(b+1)", 3, field, "冪算定義" )

wrap.addDedDBSeed( "a+b", "b+a", 3, field, "加法交換律" )
wrap.addDedDBSeed( "(a+b)+c", "a+(b+c)", 3, field, "加法結合律" )
wrap.addDedDBSeed( "a-(b+c)", "(a-b)-c", 3, field, "減算分配律" )
wrap.addDedDBSeed( "a\\cdot b", "b\\cdot a", 3, field, "乗法交換律" )
wrap.addDedDBSeed( "(a\\cdot b)\\cdot c", "a\\cdot (b\\cdot c)",
                   3, field, "乗法結合律" )
wrap.addDedDBSeed( "a / b", "1 / (b / a)", 3, field, "除法交換律??" )
wrap.addDedDBSeed( "(a / b) / c", "a/(b\\cdot c)", 3, field, "除法結合律??" )
wrap.addDedDBSeed( "a^b", "\\exp(b\\cdot(\\log(a)))", 3, field, "冪乗交換律??" )
wrap.addDedDBSeed( "(a^b)^c", "a^(b\\cdot c)", 3, field, "冪乗結合率??" )
wrap.addDedDBSeed( "\\log_a (M\\cdot N)", "(\\log_a M)+(\\log_a N)",
                   3, field, "対数分配律" )
wrap.addDedDBSeed( "\\log_a (M/N)", "(\\log_a M)-(\\log_a N)",
                   3, field, "対数逆数" )
wrap.addDedDBSeed( "\\log_a (M^p)", "p\\cdot(\\log_a M)",
                   3, field, "対数分配" )
wrap.addDedDBSeed( "\\log_a N", "(\\log_b N)/(\\log_b a)",
                   3, field, "対数分配2")

wrap.addDedDBSeed( "a - b", "a + (0 - b)", 3, field, "加法と減法" )
wrap.addDedDBSeed( "a / b", "a\\cdot(1/b)", 3, field, "除法と乗法" )

wrap.addDedDBSeed( "\\exp(\\I\\cdot a)", "\\cos(a)+(\\I\\cdot(\\sin(a)))",
                   3, field, "最も美しい式...!(Euler)" )
wrap.addDedDBSeed( "\\sin(a)",
                   "(\\exp(\\I\\cdot a)-\\exp(0-(\\I\\cdot a)))/((1 + 1)\\cdot \\I)",
                   3, field, "少しの変形" )
wrap.addDedDBSeed( "\\cos(a)",
                   "(\\exp(\\I\\cdot a)+\\exp(0-(\\I\\cdot a)))/(1 + 1)",
                   3, field, "少しの変形(2)")

# 三角関数言い換え
wrap.addDedDBSeed( "\\tan a", "(\\sin(a))/(\\cos(a))", 3, field, "正接定義")
wrap.addDedDBSeed( "\\csc a", "1/(\\sin(a))", 3, field, "余割定義")
wrap.addDedDBSeed( "\\sec a", "1/(\\cos(a))", 3, field, "正割定義")
wrap.addDedDBSeed( "\\cot a", "1/(\\tan(a))", 3, field, "cot 定義")
wrap.addDedDBSeed( "((\\sin a)\\cdot(\\sin a))",
                   "1-((\\cos(a))\\cdot(\\cos(a)))",
                   3, field, "円と三角関数" )
wrap.addDedDBSeed( "\\sin(0-a)", "0-(\\sin(a))", 3, field, "正弦波は奇関数" )
wrap.addDedDBSeed( "\\cos(0-a)", "\\cos(a)", 3, field, "余弦波は偶関数" )

# 加法定理
wrap.addDedDBSeed( "\\sin(a+b)",
                   "((\\sin a)\\cdot\\cos(b))+((\\cos(a))\\cdot\\sin(b))",
                   3, field, "加法定理")
wrap.addDedDBSeed( "\\cos(a+b)",
                   "((\\cos a)\\cdot\\cos(b))-((\\sin(a))\\cdot\\sin(b))",
                   3, field, "加法定理")

# 順列組み合わせ
wrap.addDedDBSeed( "\\P[a,b]", "(a!)/((a-b)!)", 3, field, "順列定義")
wrap.addDedDBSeed( "\\C[a,b]", "(a!)/((b!)\\cdot((a-b)!))", 3, field,
                   "組み合わせ定義")

# 冪乗展開用途
wrap.addDedDBSeed( "(x+y)^n",
                   "\\Sigma_{r=(1)}^n ((\\C[n,r])\\cdot((x^r)\\cdot(y^(n-r))))",
                   3, field, "二項定理")
wrap.addDedDBSeed( "(\\Sigma_{a=(1)}^b (c_a))\\cdot(\\Sigma_{d=(1)}^e (f_d))",
                   "\\Sigma_{a+d=b+e} ((c_a)\\cdot(f_d))",
                   3, field, "総和の積算(絶対収束)")

wrap.addDedDBSeed( "(\\I)\\cdot(\\I)", "0-1", 3, field, "複素数言い換え")

$mysql.close
