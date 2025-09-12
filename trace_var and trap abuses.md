Ok, i've been cooking something weird: `trace_var` (and `trap`) accept a string as the second argument. They'll execute the string *with the binding* of wherever the variable they've modified, *but with `self` set to `main`*. Wild. look at this:

```ruby

CONSTANT     = :ou_constant
def a_method = :ou_method
@instance    = :ou_instance
local        = :ou_local
# no class vars

class Foo
  @@class      = :in_class
  CONSTANT     = :in_constant
  def a_method = "in_method"

  def to_s = "<foo>"

  def setup
    @instance = :in_instance

    trace_var(:$var, <<~'RUBY')
      puts "trace[1]: #@@class #{CONSTANT} #@instance #{local} #{a_method} #{self}"
      local     = :MD_LOCAL
      @instance = :MD_INSTANCE
      @@class   = :MD_CLASS
      puts "trace[2]: #@@class #{CONSTANT} #@instance #{local} #{a_method} #{self}"
    RUBY

    other_method
  end


  def other_method
    local = :in_local
    puts "doit[1]:  #@@class #{CONSTANT} #@instance #{local} #{a_method} #{self}"
    $var = 'do it'
    puts "doit[2]:  #@@class #{CONSTANT} #@instance #{local} #{a_method} #{self}"
  end

end

puts "top[1]:   <nocvar> #{CONSTANT} #@instance #{local} #{a_method} #{self}"
Foo.new.setup
puts "top[2]:   <nocvar> #{CONSTANT} #@instance #{local} #{a_method} #{self}"
```

```
top[1]:   <nocvar> ou_constant ou_instance ou_local ou_method main
doit[1]:  in_class in_constant in_instance in_local in_method <foo>
trace[1]: in_class in_constant ou_instance in_local ou_method main
trace[2]: MD_CLASS in_constant MD_INSTANCE MD_LOCAL ou_method main
doit[2]:  MD_CLASS in_constant in_instance MD_LOCAL in_method <foo>
top[2]:   <nocvar> ou_constant MD_INSTANCE ou_local ou_method main
```


weird things to note:
1. look at how `trace` can actually modify the local variables in `doit[2]`
2. notice how even though `self` is `main` in `trace`, it still has access to class variables and constants defined in the `Foo`



Now, how can we use this to break things?

Well, obviously you can put this into some `required` file, but that's low stakes. (However, all of this works for `trap` too, so avoiding global variables won't solve your problems)

Here's a few ways I thought about that could break things, but couldn't quite get them to work:
1. Since inside `trace` constants are in the enclosing scope, but `self` is `main`, you could ry to make some fake constants and try to break things. (eg `class Foo; RuntimeError = 1; end` then within the `trace` try `raise "foo"` and have it try to create an exception out of an int.) The problem with this is that from a semi-cursory search, ruby doesn't do a lot of dynamic lookup from within the C code, only ruby code.
2. Try to somehow finagle with local variables. This only works if you know the name of the variables ahead-of-time, and while you could cause some serious damage (`trace(:USR1, "authenticated = true")` and then later do a `kill -USR1 <ruby proc pid>`), it's not really a bug in ruby.
    - Also, `$_` and `$~` (and other regex vars, which are derived from `$~`) are technically "locals", so you can muck with them, but not really to much success
    - Also, flipflops use anonymous local variables to track their state, but sadly there's no real way to break that
3. Investigate further to see if you can somehow get `trace_var`/`trap` to run on non`-main` things. This would be sort-of equivalent to `instance_exec`, however, and that's not that super exciting.

I think the likeliest way to cause a problem with `trace_var`/`trap` would be to somehow call a C method on a type which expects data of one type, but is given another. A lot of classes actually use instance variables internally, but don't start them with `@` so Ruby scripts can't ever access them. If there was a way to somehow set those, we'd be able to break _so_ much stuff. But, alas, I doubt you can go much further with this.
