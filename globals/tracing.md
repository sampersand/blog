# `trace_var` and `untrace_var`
While underused, globals in Ruby have lots of interesting features dedicated exclusively to them. Here, we'll be talking about an oft-unused one: `trace_var` (and its friend `untrace_var`)

## Basic Usage
So, what exactly is `trace_var`? Well, it's a way to hook into global variables, and execute a piece of code whenever they change:
```ruby
# Run the block whenever `$foo` is changed:
trace_var :$foo do |new|
  puts "foo changed to: #{new}"
end

$foo = 34 #=> foo changed to: 34

# Disable the trace:
untrace_var(:$foo)
$foo = 45 # (nothing printed)
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

<!-- While global variables are notorious for being difficult to use, (and I rarely ever use them outside of smallish single-file scripts, which are easy enough for me to debug without resorting to `trace_var`) -->

There are some other uses however, such as responding to end-users changing `$DEBUG`:
```ruby
module MyLogger
  @log_level = :info

  # Change `@log_level` whenever `$DEBUG` changes
  trace_var :$DEBUG do |enabled|
    @log_level = enabled ? :trace : :info
  end

  # ...
end
```

### Specifying a second argument
I lied slightly earlier with in `trace_foo` example; the `untrace_var(:$foo)` actually will remove _all_ traces for `$foo`, not just the one we added. To remove a specific trace, you have to provide it as the second argument:
```ruby
def trace_foo
  # extract the proc to its own variable
  foo_trace = proc do |var|
    puts "here is the stacktrace for setting $foo:", caller
  end

  # `trace_var` accepts `Proc`s as a second argument
  trace_var :$foo, foo_trace

  # Run the code we're interested in debugging
  yield

  # `untrace_var` lets you specify which trace to remove:
  untrace_var :$foo, foo_trace
end
```
We'll go more in depth on this later on in the article. Let's take a look now at the specifics of `trace_var` and its friend `untrace_var`.

## Parameters and Return Values
The RBS signature[^9] for the two are as follows. If you're not familiar with RBS, don't worry, I'll break it down.
```rbs
# Any type which defines a `.call` method which takes
# one argument satisfies this.
interface _Tracer
  def call: (any argument) -> void
end

def trace_var: (interned name, String | _Tracer cmd) -> nil
             | (interned name) { (any value) -> void } -> nil
             | (interned name, nil) -> Array[String | _Tracer]?

def untrace_var: (interned name, ?nil) -> Array[String | _Tracer]?
               | (interned name, Sting cmd) -> String?
               | [T < _Tracer] (interned name, T cmd) -> T?
```
Let's dive into it.

[^9]: As of this writing, I haven't actually merged this into RBS master, so the signature might change slightly.

### The first argument: The name.
The first argument to both functions is an `interned`, which is RBS speak for either a `Symbol`, or a type that defines `.to_str`. This is the type that most of the standard library uses for functions which accept symbols (eg `instance_variable_get`, `define_singleton_method`, etc.).

Interestingly, `trace_var` will accept _any_ `interned` type as its first argument, even if it doesn't refer to a global variable (`trace_var("foo") { ... }` is totally valid!). (And, as a fun sidenote, `trace_var` doesn't actually define the global, so `trace_var(:$a){}; p defined?($a)` will yield `nil`)

But `untrace_var` doesn't like this: It only accepts `interned`s which represent global variables that are either currently defined _or_ have been traced, and throws a `NameError` otherwise. It makes sense when you think about it: How do you untrace something which you haven't traced so far?[^1].

[^1]: I guess you could just return `nil` in this case, but I like the exception more as it makes more sense

### The second argument: The command for `trace_var`
This parameter is so much more interesting than the first, so we'll be breaking it into two sections (one for `trace_var` and one for `untrace_var`).

#### Passing `_Tracer`ables directly
In addition to supporting normal blocks, `trace_var` _also_ supports passing in blocks directly as the second argument[^2]: You just need to supply a type which defines `.call`, and accepts a single argument (the type of the global variable which was just assigned). This means the following is valid:

```ruby
class Foo
  def call(value)
    puts "stacktrace (when assigned #{value}): #{caller}"
  end
end

trace_var(:$foo, Foo.new)
```

[^2]: Technically, you can pass _anything_ as the second argument (RBS type `any`), and `trace_var` will accept it. However, assigning to the global variable will then fail with a `NoMethodError` when it tried to run `.call`.

Kinda funky, and I haven't found much use for passing in arbitrary `_Tracer`ers when a plain-old-`do ... end` does fine.

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

I bet that is because `trace_var` was added _very_ early on, maybe before even `Proc`s existed. There also was quite a lot of prior art at the time of using `String`s for these types of things, e.g. most shells have `trap SIGNALS "shellcode"`, PHP originally did it for `array_map`, etc. It's kinda fun.

There's a few weird things you can do with this too. For example, by constructing `String`s with many newlines, you can get some very unreadable error locations[^4]:
```ruby
trace_var :$foo, "\n"*100 + 'fail'
$foo = 3
# test.rb:102:in '<main>': unhandled exception
# from test.rb:2:in '<main>'
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

But the thing that takes the cake is the fact that `trace_var` uses the top-level binding when evaluating the code, but _not_ when compiling it (an oddity shared with `Kernel#trap`). This means that within the `String` command, `self`, instance variables, and any methods called are run at top level, **but** constants are determined based on where the global variable's assignment:

```ruby
class Foo
  Bar = :inside_foo

  def doit
    @instance = :hello

    trace_var :$foo, '@instance = Bar'

    # Sets top-level `@instance` to `Foo::Bar`!
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

First and foremost, `untrace_var` passed `nil` as the second argument (`untrace_var(:$foo, nil)`) is identical to calling it with simply one argument[^5], where it removes all traces on `$foo`, and returns an array of the traces:
```ruby
trace_var(:$foo) { p 1 }
trace_var(:$foo) { p 2 }

trace_var(:$bar) { p 3 }
trace_var(:$bar) { p 4 }

p untrace_var(:$foo)      #=> [#<Proc:...>, #<Proc:...>]
p untrace_var(:$bar, nil) #=> [#<Proc:...>, #<Proc:...>]
```

[^5]: Ruby's a bit inconsistent about whether explicitly supplying `nil` as an argument is equivalent to not supplying it at all (i.e. whether `foo(1, 2)` and `foo(1, 2, nil)` are identical). But, a rough rule-of-thumb is that "earlier" methods (like `IO#read` and `Kernel#sleep`) treat `nil` the same as "nothing supplied". I suspect this is inspired from Perl's `undef` being equivalent to not passing anything.

Like `trace_var`, `untrace_var` also accepts a command as the second second argument, and will attempt to remove that exact trace:
```ruby
# setup traces
trace = proc { puts 'yo' }
trace_var(:$foo, trace)
trace_var(:$foo) { puts 'hi' }

# remove just the first one`trace`
untrace_var :$foo, trace

$foo  = 3 #=> hi
```

There's a couple of in interesting things about this: Firstly, it requires the _exact same object_ (it actually compares pointers in the C code); overwriting `==`, `.equal?`, `__id__`, or anything else does nothing:
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

# Gotta call it twice to unregister all of them.
untrace_var(:$foo, trace)
$foo = 4 # (nothing)
```

This makes some sense if you think of a normal usage of `trace_var`, debugging:
```ruby
module TraceFoo
  PRINT_FOO = proc { |val| puts "$foo set to #{val}" }

  module_function

  def trace_foo
    # Setup tracing for `$foo`
    trace_var(:$foo, PRINT_FOO)

    # Call the block we want to trace assignments to `$foo`
    yield

    # Only remove the trace we did at the start of the
    # method, not all `trace_foo`s there were called.
    # This way, we can guarantee that we won't change other people's code.
    untrace_var(:$FOO, PRINT_FOO)
  end
end
```

## Working with `alias`
`trace_var` actually works just like you'd expect with `alias`ed variables: When making `alias`es, the traced functions are also aliased:
```ruby
trace_var :$bar do |val|
  puts "hey, look: #{val}"
end

alias $foo $bar
$foo = 3 #=> hey, look: 3
```

Unfortunately, because a lot of the builtin globals in Ruby aren't "real" global variable aliases[^6], you have to register `trace_var`s for each one:
```ruby
# Gotta repeat them since they're not true `alias`es :-(
trace_var :$VERBOSE do |v| puts "Changed: #{v}" end
trace_var :$-v do |v| puts "Changed: #{v}" end
trace_var :$-w do |v| puts "Changed: #{v}" end
```

[^6]: Nearly all builtin global "alias"es are actually entirely separate globals which just happen to have identical getters and setters to one another. The _only_ builtin globals which are truely "aliased" are `$:`, with aliases of `$LOAD_PATH` and `$-I`. Sadly, since `$:` is read-only anyways, it's useless with `trace_var`.

## Downsides
As with everything, there's some downsides with `trace_var`/`untrace_var`.

### It's niche
Most obviously is the fact that it's niche: Global variables are often unused, and `trace_var`'s most common use case (debugging global variable assignments) is rarely needed. Luckily, this "average" use case of `trace_var` doesn't have a whole lot of gotchas, so it's not too bad.

### Doesn't work with builtin globals
Unfortunately, `trace_var` doesn't work with Ruby's C-level assignments of any[^7] of the builtin globals: This is because all builtin globals are "hooked," which means they use completely separate mechanisms for assignment that bypass the `trace_var`s. This is actually deeply unfortunate, because I'd love to do the following:
```ruby
# Doesn't work. (But `TracePoint` can be used instead)
trace_var :$! do |exception|
  puts "[LOG] oops: #{exception} at: #{caller}"
end

# Doesn't work, and has no real way to do it
trace_var :$~ do |rxp|
  puts "[LOG] matched a regex: #{rxp}"
end
```

[^7]: I actually haven't exhaustively checked the source code to ensure that _no_ global variables work with `trace_var`—there may be some really weird bizarre edge cases where they do—but the standard "hooked globals" (which are all the builtin ones) use different assignment functions which don't trigger it.

That being said, you _can_ register `trace_var`s which work when Ruby-level code assigns to the globals, and it can work quite nicely for some of them:
```ruby
module MyLogger
  @log_level = :info

  # If an end-user sets `$DEBUG` or `$-d`, also update `MyLogger`'s
  # logging level. As explained in "Working with `alias`", we have to
  # register separate `trace_var`s for both `$-d` and `$DEBUG` as they
  # aren't "true" global variable aliases.
  trace_dbg = proc do |enabled|
    if enabled
      @log_level = :trace
    else
      @log_level = :info
    end
  end

  trace_var :$DEBUG, trace_dbg
  trace_var :$-d, trace_dbg

  # ...
end

# Update the program name dynamically
class MyOptionParser
  @default_program_name = $0

  # Likewise, `$0` and `$PROGRAM_NAME` aren't true aliases
  trace_var :$0            do |name| @default_program_name = name end
  trace_var :$PROGRAM_NAME do |name| @default_program_name = name end

  # ...
end
```

### There's no way to get the name of the traced variable
Unfortunately, the the block/"`_Tracer`able" that's called is only ever provided a single argument; the value that the global variable is assigned. (The `String` version is even worse—you get passed nothing, since it's essentially `eval`'d!)

Normally, this doesn't matter a ton. After all, you pass the name into `trace_var`, so you know what you're tracing! Unfortunately, this doesn't let you do a whole lot of metaprogramming, and limits the utility of passing a second argument directly to essentially just `untrace_var`ing (and reusing the same block multiple times to deal with Ruby's "aliased-but-not-actually" global variables like `$DEBUG` and `$-d`):
```ruby
ASSIGNED_VARS = Hash.new(0)
at_exit { pp ASSIGNED_VARS }

# Imagine this:
trace_var(:$foo) { ASSIGNED_VARS[:$foo] += 1 }
trace_var(:$bar) { ASSIGNED_VARS[:$bar] += 1 }
trace_var(:$baz) { ASSIGNED_VARS[:$baz] += 1 }

# This doesn't work; the lambda only takes one argument,
# the new value for the global:
ASSIGN_GVAR = lambda do |name, value|
  ASSIGNED_VARS[name] += 1
end
trace_var :$foo, ASSIGN_GVAR
trace_var :$bar, ASSIGN_GVAR
```
It's not too bad though, as there are simple workarounds, such as:s
```ruby
def trace_var_incr(name)
  trace_var(name) { ASSIGNED_VARS[name] += 1 }
end
trace_var_incr :$foo
trace_var_incr :$bar
trace_var_incr :$baz
```

### It doesn't accept an array of traces
This one's a bit annoying: If you want to completely stop tracing a variable, it's easy. You just do `untrace_var(:$foo)`. The problem is re-adding all the traces back[^8]:
```ruby
# Stop tracing `$foo` for one method:
begin
  old = untrace_var(:$foo)
  do_some_method
ensure
  # Won't work because `old` (an `Array`) doesn't define `.call`
  trace_var(:$foo, old)
end
```
[^8]: Technically, the `trace_var` line will work because it accepts `any` as its second argument. However, attempting to assign to `$foo` later will fail with a `NoMethodError`.

The solution is to just use a `.reverse_each`:
```ruby
begin
  old = untrace_var(:$foo)
  do_some_method
ensure
  old.reverse_each do |trace|
    trace_var(:$foo, trace)
  end
end
```

Why the `.reverse_each`? Well, `trace_var`s are actually stored internally using a linked list to keep track of the different traced functions[^10]. The upshot of this is that the return value of `untrace_var(:$global)` is actually in reverse order of how you declared them:
```ruby
trace_var(:$foo, 'p 1')
trace_var(:$foo, 'p 2')
trace_var(:$foo, 'p 3')

p untrace_var(:$foo) #=> ["p 3", "p 2", "p 1"]
```

[^10]: I actually think this is smart: How often are you going to be assigning more than one trace to a variable? Probably not often. And, if you do, you're probably going to be removing them pretty quickly anyways.

So, to insert them in the same order you extracted them, `.reverse_each` is needed.

## Conclusion
Whelp, that's about all I discovered when working with `trace_var` and `untrace_var`. I personally don't use them all too often, but I do love exploring odd edge cases in Ruby, and I hope you had fun (and learned something!)
