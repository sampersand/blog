# `defined?` in Ruby
Ruby's littered with fun little things that you never knew existed, and if you did, didn't understand how weird they can be. One of these is `defined?`. Let's jump into it.

# Basic Usages
Fundamentally, the purpose of the `defined?` keyword (which happens to also be the only keyword with non-letters in it!) is to see whether or not a value is defined.

(I suspect `defined?` comes from Perl's `defined` method, and possibly from C's `#if defined`/`#ifdef` macros.)

Here's some examples of when I use it, and we'll break them down:

## `defined?(@instance)` vs `@instance ||=`
Sometimes it's useful to check for whether or not an instance variable is set within a class, and then perform an action (usually initializing it) if it isn't. This is a useful replacement for the traditional `@instance ||= ...` when `nil` is a valid value for the instance variable
```ruby
class User
  def posts
    # Returned the cached value if it exists
    return @cached_posts if defined?(@cached_posts)

    # Do the query, which can possibly return `nil`
    @cached_posts = expensive_database_query
  end
end
```
If we instead used `@cached_posts ||= expensive_database_query`, we would perform the expensive database query every time, as `@cached_posts` is already `nil`.

Note that you can replace `defined?` with `instance_variable_defined?`, although it's so much uglier. (However, for global variables, this is the _only_ way to test whether a variable is set, or is set to `nil`—there is no `global_variable_defined?`)

## `defined?` for optional features
Another use for `defined?` is checking for whether features exist, and then performing actions based on it. One example I use quite frequently is checking for optimizations, and then enabling them if they're present:
```ruby
# Enable YJIT, but also support older rubies where it doesn't exist
RubyVM::YJIT.enable if defined?(RubyVM::YJIT.enable)
```
(That's probably pretty niche, as I do a lot of backwards-compatible things because of some older laptops I play with.)

Another situation I've found myself in is checking for existence of constants, and then doing things based on that, such as:
```ruby
# Only require a gem if a constant's not already set.
load 'bitint' unless defined?(BitInt)
```
However, this one is not terribly useful most of the time, as `require` does most of the heavy lifting. (There are some situations where I've intentionally done circular imports when debugging things, but it's not that common.) As an aside, `Object.const_defined?` can usually replace this usage.

## `defined?(...) or def ...`
Another good way to use `defined?` is to optionally create methods when they don't exist. I've used this for "backports" of some methods that older Rubies don't have:
```ruby
class String
  defined?("".delete_prefix!) or def delete_prefix!(prefix)
    slice! /\A#{Regexp.escape(prefix)}/ and self
  end
end

class Hash
  defined?({}.to_proc) or def to_proc
    method(:[]).to_proc
  end
end
```

## `defined?` at the end of a long method chain
Interestingly, `defined?` can actually be given a long method/constant-access chain, and will return whether the _entire_ chain is defined. To do this, Ruby actually executes every method, and looks up every constant in the chain until it gets to the _very last one_, which is not executed. Let's start with a small example, where we're actually passing in the wrong number of arguments
```ruby
class Example
  def hello; :works end
end

puts "yes!" if defined?(Example.new.hello 3, 4, 5)
#=> yes!
```
This actually works because while Ruby executes intermediary methods, it only checks to see if the final method is defined, not which arguments it accepts.

Let's look at a longer one, this time with print statements in methods:

```ruby
class Example
  def initialize; puts "initialized!" end
  def hello; puts "hello"; Other end
end

class Other
  SINGLETON = Other.new
  def doit(rhs) = true
end

puts defined?(Example.new.hello::SINGLETON.doit 3)
#=> initialized!
#=> initialized!
#=> hello
#=> initialized!
#=> hello
#=> method
```
Why the repeat `initialized!`? Well, Ruby's actually re-executing everything every step of the way. (Once for checking `Example`, another for `Example.new`, another for `Example.new.hello`, etc.) Inefficient IMO, it's a bit weird that it doesn't actually store intermediate results, but whatever!

# Syntax — to use parens or not
Like most of the rest of ruby, the `defined?` keyword doesn't actually need parens: `defined? foo` works just as well as `defined?(foo)`. However, you have to be careful: `defined?` actually has quite a low precedence (only `not`, `or`, `and`, and "modifier" keywords like `... if` and `... until` have a lower precedence). This can lead to some surprising results:
```ruby
# (assume @num is not set)
puts "@num is zero" if defined? @num && @num.zero?
# @num is zero
```
This is because `defined?` sees `@not_set && @not_set.zero?`, which it then interprets as an expression, and assumes is set. To solve this, you can do:
```ruby
# use `and`, which has higher precedence:
puts "@num is zero" if defined? @num and @num.zero?
# use parens, which always work:
puts "@num is zero" if defined?(@num) && @num.zero?
```

The parser actually explicitly has a separate case for when `defined?` is immediately followed by a parenthesis, so there's no need to worry about `defined? (@num) && @num.zero?` being interpreted as `defined?( (@num) && @num.zero?)`.

# Return value
Up to now, all the examples I've used with `defined?` have simply been checking the truthiness of its return value. However, `defined?` actually returns a string describing its argument (or `nil` if the argument is not defined). Here's a short table describing some common return values. (A complete table is at the end of the article.)

| `argument`       | `defined?(argument)`  |
|------------------|-----------------------|
| `variable`       | `"local-variable"`    |
| `@instance`      | `"instance-variable"` |
| `$global`        | `"global-variable"`   |
| `@@class`        | `"class variable"`    |
| `CONSTANT`       | `"constant"`          |
| `a = hello`      | `"assignment"`        |
| `some(method)`   | `"expression"`        |
| `1 + 2`          | `"expression"`        |
| `foo && bar`     | `"expression"`        |

# Abnormal Usecases
You've seen some common uses of `defined?` above, but there's also quite a few unknown and underused variants, some of which aren't easily replaced with normal methods. Let's take a look at few

## `defined?(yield)`
This one is actually an alternative to `block_given?`, interestingly enough:
```ruby
def do_it
  return to_enum unless defined? yield
  10.times { |x| yield x }
end
```
Not a whole lot more to say here, let's keep going

## `defined?(super)`
This actually lets you check if a `super`-method is defined:
```ruby
module GiveADefaultGreeting
  def greeting = defined?(super) ? super : '👋, 🌎'
end

class English
  def greeting = 'Hello, World'
  prepend GiveADefaultGreeting
end

class Normal
  include GiveADefaultGreeting
end

English.new.greeting #=> Hello, world
Normal.new.greeting #=> 👋, 🌎
```
I've never actually found a compelling use for this, but I'm sure there is one. Also note that while `super` and `super(with, arguments)` are normally distinct in Ruby, `defined?` doesn't care and treats them both the same---it just checks to see if a super method exists.

## `defined?($1)` and and other regex variables
Interestingly enough, there's actually a special-case for the "regexp globals" (`$&`, `$+`, ``$` ``, `$'`, and the numbered `$1`, `$2`, ..., but notably **not** for `$~`), where `defined?($1)` will actually return `nil` if no regex has been matched. For example:
```ruby
p [defined?($&), defined?($1), defined?($2)]
# => [nil, nil, nil]

"regex" =~ /(e)/

p [defined?($&), defined?($1), defined?($2)]
# => ["global-variable", "global-variable", nil]
```
Fascinating that it exists, however I personally have never needed them: I'll usually just do `$1 && ...` if I need them.

## `defined?( [an, array] )` and `defined?( {a => hash} )`
Additionally, `defined?` can actually be used on Array literals, and Ruby will `defined?` on each element (or for each key and value pair in the Hash literal case), and return `"expression"` if everything matches, or `nil` if even one element doesn't match.

So, instead of doing `if defined?(a) && defined?(b) && defined?(c)` you can do `defined?([a, b, c])`. Pretty nifty, but I've never had a need for checking multiple `defined?`s at once.

There's also `defined?({ a => hash })` which works the same way as the Array literal, but instead of checking elements, it checks keys _and_ values. I have no idea when it'd be useful, but it exists.

## Generic `defined?`
The `defined?` method can actually be used on _any_ expression whatsoever, however most of them are pretty pointless. For example:
```ruby
p defined?(true)     #=> "true"
p defined?(self)     #=> "self"
p defined?(__LINE__) #=> "expression"
p defined?(1 + 2)    #=> expression
```

# Alternatives to `defined?`
Most of the `defined?`s have alternatives, but some aren't all that pretty. Here's a table:

| `defined?(what)` | Replacement |
|------------------|-------------|
| `variable`       | `binding.local_variable_defined?` [^1] |
| `@instance`      | `instance_variable_defined?` |
| `@@class`        | `self.class.class_variable_defined?` |
| `$global`        | **none** |
| `::CONSTANT`     | `self.class.const_defined?` |
| `meth(...)`      | `respond_to?` |
| `foo.meth(...)`  | `foo.respond_to?` |

[^1]: Almost the same—`Binding#local_variable_set` can be used to assign to local variables which are only accessible via `local_variable_{get,defined?}`.


# Table
Here's a complete table of all the possible `defined?` values: (incomplete, WIP)


| `defined?(what)` | Output                 | Alternatives | Notes |
|:-----------------|:-----------------------|-------|----|
| `nil`            | `"nil"`                |       |
| `true`           | `"true"`               |       |
| `false`          | `"false"`              |       |
| `self`           | `"self"`               |       |
| `[a,b,c]`        | `"expression"?`        |       | Doesn't actually make an array; goes thru elements and sees if theyre all defined |
| `{ a => b, ...}` | `"expression"?`        |       | Doesn't actually make a hash; goes thru elements and sees if theyre all defined |
| `"string"`       | `"expression"`         |       | |
| `:symbol`        | `"expression"`         |       | |
| `/regex/`        | `"expression"`         |       | |
| `__LINE__`       | `"expression"`         |       | |
| `__FILE__`       | `"expression"`         |       | |
| `__ENCODING__`   | `"expression"`         |       | |
| `123` (integer)  | `"expression"`         |       | |
| `12.3` (float)   | `"expression"`         |       | |
| `12r` (rational) | `"expression"`         |       | |
| `12i` (float)    | `"expression"`         |       | |
| `[]`             | `"expression"`         |       | Special-cased |
| `... && ...`     | `"expression"`         |       | Doesn't actually evaluate either side |
| `... \|\| ...`   | `"expression"`         |       | Doesn't actually evaluate either side |
| `variable`       | `"local-variable"`     | none  | (includes both local variables, and "dynamic variables," ie vars assigned in blocks)|
| `@ivar`          | `"instance-variable"?` | `instance_variable_defined?`      | |
| `$gvar`          | `"global-variable"?`   | **none**      | |
| `@@cvar`         | `"class variable"?`    | `class_variable_defined?`      | Interestingly, doesn't use a hyphen in its name, unlike other `"variable"`s. |
| `CONSTANT`       | `"constant"?`          | `const_defined?` | |
| `meth(...)`      | `"expression"?`        | `respond_to?`      | |
| `a.meth(...)`    | `"expression"?`        |       | |
| `a + b`          | `"expression"?`        |       | |
| `a.b = ...`      | `"expression"?`        |       | Checks for `b=` being defined |
| `yield`          | `"yield"?`             |       | Another way of doing `block_given?` |
| `$&` and `$1`    | `"global-variable"`?   |       | the only builtin globals that can be nil |
| `super`          | `"super"?`             |       | Depends on whether a `super` call actually exists |
| `a = b`          | `"assignment"`         |       | ? |
| `@a = b`         | `"assignment"`         |       | ? |
| `$a = b`         | `"assignment"`         |       | ? |
| `@@a = b`        | `"assignment"`         |       | ? |
| `a,b = c`        | `"assignment"`         |       | ? |

# Fun fact
Fun fact: using `x ||= y` actually uses `defined?` under the hood, unless `x` is an instance variable.
vm_defined
compile_op_log

