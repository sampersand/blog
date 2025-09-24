In Ruby, the `alias` keyword is known for creating aliases between functions, eg `alias length size`. However, `alias` also has another use: Aliasing global variables:
```ruby
alias $foo $bar
$bar = 34
puts $foo #=> 34
```

If you're just using normal, user-defined global variables it works mostly as expected. However, things get weird when you interact with special builtin globals
However, this has _so_ many weird edge-cases.

## Different types of globals
Internally, Ruby has three different types of global variables:
- `tNTH_REF`, which is used for `$1`, `$2`, etc.
- `tBACK_REF`, which is used for other regex vars (`$&`, ``$` ``, `$'`, and `$+`, but notably _not_ `$+`)
- `tGVAR`, which is every other variable

# Wjhat cam y0o8u assign on either side?
Well, you can _assign_ anything on the left-hand-side of a `alias`, but that doesn't mean it'll work:
```ruby
$thing = 10

alias $1 $thing
p $1 #=> nil

alias $` $thing
p $` #=> nil

alias $stdout $thing
p $stdout #=> nil
```


eg is `alias $1 $x` ok but what about vice versa





# `English`
# `alias` and `trace_var`
