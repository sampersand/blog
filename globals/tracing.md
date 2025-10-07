# `trace_var` and `untrace_var`
While underused, globals in Ruby have lots of interesting features dedicated exclusively to them. Here, we'll be talking about an oft-unused one: `trace_var` (and its friend `untrace_var`)

## Basic Usage
So, what exactly is `trace_var`? Well, it's a way to hook into global variables, and execute a piece of code whenever they change:
```ruby
# Run the block whenever `$foo` is changed:
trace_var(:$foo) do |new|
  puts "foo changed to: #{new}"
end
$foo = 34 #=> foo changed to: 34

# Disable the trace:
untrace_var(:$foo)
$foo = 45 # nothing printed
```

Ruby is the only language I know of to provide this feature, the ability track when global variables are changed. This can help mitigate one of the (many) drawbacks of global variables: It's difficult to debug what changes them and when:
```ruby
def trace_foo
  # Start tracing `$foo` changes
  trace_var :$foo do |var|
    puts "here is the stacktrace for setting $foo:", caller
  end

  # Run the code we're interested in debugging
  yield

  # Ok, we're done tracing, remove it now!
  untrace_var :$foo
end
```

That being said... Global variables are notorious for being evil, so I rarely ever use them outside of smallish single-file scripts (which are easy enough for me to debug without resorting to `trace_var`).

### Specifying a second argument
I slightly lied earlier with my `trace_foo` example; the `untrace_var(:$foo)` actually will remove _all_ traces for `$foo`, not just the one we added. To remove a specific trace, you have to provide it as the second argument:
```ruby
def trace_foo
  foo_trace = proc do |var|
    puts "here is the stacktrace for setting $foo:", caller
  end

  # `trace_var` accepts `Proc`s as a second argument
  trace_var :$foo, foo_trace

  yield

  # `untrace_var` lets you specify which trace to remove:
  untrace_var :$foo, foo_trace
end
```
We'll go more in depth on this later on in the article. Let's take a look now at the specifics of `trace_var` and its friend `untrace_var`.

## Parameters and Return Values
The RBS signature for the two are as follows. If you're not familiar with RBS, don't worry, I'll break it down.
```rbs
def trace_var: (interned name, String | ^(any) -> void cmd) -> nil
             | (interned name) { (any value) -> void } -> nil
             | (interned name, nil) -> Array[String | _Call]?
def untrace_var: (interned name, ?nil) -> Array[String | _Call]?
             | (interned name, Sting cmd) -> String?
             | [T < _Call] (interned name, T cmd) -> T?
```
Let's dive into it.

### The first argument: The name.
The first argument to both functions is an `interned`, which is RBS speak for either a `Symbol`, or a type that defines `.to_str`. This is the type that most of the standard library uses for functions which accept symbols (eg `instance_variable_get`, `define_singleton_method`, etc.).

Interestingly, `trace_var` will accept _any_ `interned` type as its first argument, even if it doesn't refer to a global variable (`trace_var("foo") { ... }` is totally valid!). (And, as an interesting sidenote, `trace_var` doesn't actually define the global, so `trace_var(:$a){}; p defined?($a)` will yield `nil`)

But `untrace_var` doesn't like this: It only accepts `interned`s which represent global variables that are either currently defined _or_ have been traced, and throws a `NameError` otherwise. It makes sense when you think about it: How do you untrace something which you haven't traced so far?[^1].

[^1]: I guess you could just return `nil` in this case, but I like the exception more as it makes more sense

### The second argument: The command for `trace_var`
This parameter is so much more interesting than the first, so we'll be breaking it into two sections (one for `trace_var` and one for `untrace_var`).

#### Passing `.call`ables directly
In addition to supporting normal blocks, `trace_var` _also_ supports passing in blocks directly as the second argument[^2]: You just need to supply a type which defines `.call`, and accepts a single argument (the type of the global variable which was just assigned). This means the following is valid:

```ruby
class Foo
  def call(value)
    puts "stacktrace (when assigned #{value}): #{caller}"
  end
end

trace_var(:$foo, Foo.new)
```

[^2]: Technically, you can pass _anything_ as the second argument (RBS type `any`), and `trace_var` will accept it. However, assigning to the global variable will then fail with a `NoMethodError`.

Kinda funky, but I haven't found much use for passing in arbitrary `.call`ers when a plain-old-`do ... end` does fine.

#### Passing `nil`
Presumably added before `untrace_var` existed[^3], `trace_var` also accepts `nil` as a second argument, simply as alias for `untrace_var`:

```ruby
# These are equivalent
trace_var(:$foo, nil)
untrace_var(:$foo)
```

[^3]: I haven't been able to verify, as this was before the git history started in 1998.

We'll discuss `untrace_var` later on, so no need to discuss it here.

#### Passing `String`s
This one is the oddest of them all. Unlike virtually every other method in Ruby (with the exception of `trap`, `instance_exec`, and probably a few others I'm missing), `trace_var` actually lets you pass in a _string of code_ as the last argument:
```ruby
trace_var(:$foo, 'puts "changed foo!"')
$foo = 3 #=> changed foo!
```

I presume (again without being able to verify), that this is because `trace_var` was added _very_ early on, before even `Proc`s existed. There's also a lot of prior art of using `String`s for these types of things, e.g. most shells have `trap SIGNALS "shellcode"`, PHP originally did it for `array_map`, etc. It's kinda fun.

There's a few weird things you can do with this too. For example, by constructing `String`, you can get some very unreadable error locations[^4]:
```ruby
trace_var :$foo, "\n"*100 + "fail"
$foo = 3
# foo.rb:102:in '<main>': unhandled exception
# from foo.rb:2:in '<main>'
```

[^4]: This isn't actually unique to `trace_var`; you can do this via `eval("fail", nil, 'f', 999)` too

Weirder still is the fact that the string is actually compiled _each time the global variable is changed_, not upon calling `trace_var`. This means you can (if you wanted to, for whatever reason) dynamically change the trace:
```ruby
tracer = 'puts "changed foo!"'
trace_var(:$foo, tracer)

$foo = 3 #=> changed foo!

# Call `String#replace` to replace the contents
tracer.replace 'puts "lol hi!"'

$foo = 4 #=> lol hi!
```

But the thing that takes the cake (an oddity shared with `Kernel#trap`) is the fact that `trace_var` uses the top-level binding when evaluating the code, but _not_ when compiling it. This means that within the `String` command, `self`, instance variables, and any methods called are run at top level, **but** constants are determined based on where the global variable was assigned:

```ruby
class Foo
  Bar = :inside_foo
  def doit
    @instance = :hello
    trace_var :$foo, '@instance = Bar'
    $foo = 3
    @instance
  end
end

Bar = :toplevel
p Foo.new.doit #=> :hello
p @instance    #=> :inside_foo
```

This is extremely weird, and deviates from `eval` (and related functions), which use the current binding both when compiling the code, and when evaluating it. This has got to be one of my favourite pieces of Ruby trivia!

### `untrace_var`'s second argument
Now onto `untrace_var`!

First and foremost, `untrace_var` passed `nil` as the second argument (`untrace_var(:$foo, nil)`) is identical to calling it with simply one argument[^5], where it removes all traces on `$foo`, and returns an array of the traces.

[^5]: Ruby's a bit inconsistent about whether explicitly supplying `nil` as an argument is equivalent to not supplying it at all (i.e. whether `foo(1, 2)` and `foo(1, 2, nil)` are identical). But, a rough rule-of-thumb is that "earlier" methods (like `IO#read` and `Kernel#sleep`) treat `nil` the same as "nothing supplied". I suspect this is inspired from Perl's `undef` being equivalent to not passing anything.

Like `trace_var`, `untrace_var` also accepts a command as the second second argument, and will attempt to remove _exactly that trace_:
```ruby
# setup traces
trace = proc { puts 'yo' }
trace_var(:$foo, trace)
trace_var(:$foo) { puts 'hi' }

# remove just the first one`trace`
untrace_var :$foo, trace

$foo  = 3 #=> hi
```

There's a couple of in interesting things about this: Firstly, it requires the _exact same object_ (it actually compares pointers in the C code); overwriting `.equal?`, `__id__`, or anything else does nothing:
```ruby
trace_var(:$foo, 'puts "yo"')

# Even though the strings are the `==`,
# since they aren't the _exact same object_,
# this does nothing:
untrace_var(:$foo, 'puts "yo"')

$foo = 3 #=> yo
```

Moreover, it only removes the first instance of said trace:
```ruby
trace = proc { puts "YO!" }

# Register the exact same trace twice
trace_var(:$foo, trace)
trace_var(:$foo, trace)
$foo = 3 #=> YO!\nYO!

# Only undoes one of them!
untrace_var(:$foo, trace)
$foo = 4 #=> YO!

# Gotta call it twice to unregister it
untrace_var(:$foo, trace)
$foo = 4 # (nothing)
```

This makes sense if you think of the normal usage of `trace_var`, debugging:
```ruby
module TraceThing
  PRINT_THING = proc { |val| puts "thing set to #{val}" }

  module_function
  def trace_thing
    trace_var(:$thing, PRINT_THING)
    yield
    # Only remove the trace we did at the start of the
    # method, not _all_ `trace_thing`s there were called.
    untrace_var(:$thing, PRINT_THING)
  end
end
```



When `untrace_var` is called

## When is it called
## The fact that it's a linked list internally
## using a string as as second argument, esp the scoping and `.replace`
## `trace_var` can be `untrace_var` with `nil`
## specific values to the second one, including stacking
## How they interact with `alias`es
## Don't have any ability to get trace var name :-(

Unfortunately



Ruby lets you do a lot of stuff with `trace_var`
__END__
# class Lol
#   def doit
#     trace_var(:$var, '@x = 3')
#     $var = 3
#     untrace_var(:$var)
#   end
# end

# @x = 4
# Lol.new.doit
# p @x

trace_var :$a, 'puts "trace: 1"'
trace_var :$a, 'puts "trace: 2"'
trace_var :$a, 'puts "trace: 3"'

# later on:
trace_var :$a, q=proc{'puts "trace: 3"'}
trace_var :$a, q
$a = 4
p untrace_var :$a, q#'puts "trace: 3"'
p untrace_var :$a, q#'puts "trace: 3"'
$a = 5
exit


$a = 3
