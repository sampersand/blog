# Conversions

Conversions in Ruby are a mess.

Everyone who's used Ruby a little bit has run into the distinction of "explicit" conversions—for example, `to_i`, `to_s`, etc—and implicit conversions—`to_int`, `to_str`, etc. But what about those top-level `Kernel` functions like `Integer()`, `Array()`, etc? And how about the oft-unused `try_convert` methods like `Hash.try_convert`? They're actually quite inconsistent in how they do conversions. (And don't get me started on how the syntax doesn't even respect it. (Actually, we will get started and visit it later!))

So, let's dive in to the different ways to convert types in Ruby before converging on a definition for "implicit conversions"

As a quick plug, if you want to play around with types that _only_ define conversion methods, check out my [`blankity`](https://rubygems.org/gems/blankity) gem, which lets you do things like `Blankity::To.int(34)` to get a type which _only_ responds to `.to_int`. All of the conversions in this article are defined in `blankity`!


## Conversion Techniques

There's quite a few different ways to convert between types. Let's go over them, before we delve into some more odd conversion methods.

### `to_i` and `to_int`
If you're reading this, you're already familiar with explicit conversions: `String#to_i` converts to `Integer`s, `Array#to_h` converts to a `Hash`, etc.

You also probably already know about "implicit" conversions like `.to_int`. Implicit conversions, according to [the docs](https://docs.ruby-lang.org/en/master/implicit_conversion_rdoc.html), is: "Some Ruby methods accept one or more objects that can be either: (1) _`Of a given class`_, and so accepted as is. (2) _`Implicitly convertible`_ to that class, in which case the called method converts the object." The docs then go ahead and list out for examples:

- Array: `to_ary`
- Hash: `to_hash`[^10]
- Integer: `to_int`
- String: `to_str`

[^10]: This has _always_ bugged me—why is `Hash`'s implicit conversion spelled out? My guess is that because `.to_hsh` feels weird, but it's not _that_ weird.

The tradition idea is that these implicit conversions are for types that "act like" the type they're implicitly convertible to: You create your own custom `Array` type, and then whenever something expects an `Array`, it can just call `.to_ary` on yours to convert it:
```ruby
class MyArray
	def initialize(ary) @ary = ary end

	# Do some things to make your class work like people expect
	def [](...) = ...
	def length = ...
	...

	# Define a conversion to `Array` because we act like it
	def to_ary = @ary

	# Also define `to_a`, as we support explicit conversions
	alias to_a to_ary
end


# Now you can use it!
p [1, 2, 3] + MyArray.new(['a', 'b', 'c'])
#=> [1, 2, 3, "a", "b", "c"]
```

Pretty nifty concept. Anyways, this is probably just review, so let's look into some of the more interesting ways to convert.

### `Kernel` methods

Next up is the top-level `Kernel` methods: `Integer()`, `String()`, `Array()`, `Hash()`, `Float()`, `Rational()`, and `Complex()`. I won't be delving too deep into the uniques of each method (eg `Integer(string, base)`), as the point of this is to find a common definition for "implicit conversions"

The basic form of all these methods is when given a sole argument, to attempt to call the appropriate conversion method (and if the type has an implicit one, that's called first): `Complex` attempts `.to_c`, `Rational` attempts `to_r`, `String` attempts `to_str` followed by `to_s`, etc.

But _of course_, even this simple form has an oddity: `Kernel#Hash`. For some bizarre reason, it _never calls the explicit conversion method, `.to_h`_: It tried `.to_hash`, and if that doesn't exist raises a `TypeError`. My only guess as to why this oddity exists would be because for some reason Matz (or whomever wrote it) didn't want `Hash([['name', 'sam'], ['age', 27]])` to work. Yet, for some inexplicable reason, `Kernel#Hash` special cases an empty Array to return an empty Hash. This is so odd it bears repeating: `Hash([])` returns `{}`, but _every other array_ raises a `TypeError`. What??

Next up, the "`Numeric` methods"—`Integer`, `Float`, `Rational`, and `Complex`—also have a form where they accept `String`, and then convert that string to the corresponding type. You've probably used `Integer('string')` as a way to throw exceptions when the string isn't a valid `Integer`; the same concept applies to the other types: `Float('1e3')`, `Rational('3/4')`, and `Complex('1+2i')`[^20].

[^20]: Actually, `Rational` and `Complex` can take two arguments. While they normally and are numer+denom and real+imag, you can actually pass in any valid strings, and they'll be handled properly; `Rational('1/2', '2/3')` is the same as `(1/2r) / (2/3r)`, and `Complex('1+2i', '3+4i')` is `(1+2i) + (3+4i)*1i`.

But these are _also_ odd. For example, every one of these parsing methods only works if the argument that's supplied is a direct `String`, _except_ for `Integer`, which accepts either `String` or types that define `.to_str`. How's that for inconsistent?.[^21]

[^21]: They also all have their own ways of parsing, so eg `Integer('0d10')` (which is `10`) works, but `Rational('0d10')` doesn't.

Lastly, they handle `nil` differently: While `nil` defines all of the explicit conversion methods that're used by the methods, the `Numeric` conversions explicitly check fro `nil` and raise `TypeError`, whereas `Array`/`Hash`[^22]/`String` return an "empty" version of their classes.

[^22]: Which is all the odder given that `nil` doesn't define `.to_h`

Here's a handy dandy table:

| Method   | Conversions            | Parses Strings | Exceptions | Accepts `nil` |
|:---------|------------------------|----------------|------------|---------------|
| Array    | `to_ary`, `to_a`       | ❌ | ❌ | ✅ |
| Hash     | **`to_hash`**          | ❌ | ❌ | ✅† |
| String   | `to_str`, `to_s`       | ❌ | ❌ | ✅ |
| Complex  | `to_c`                 | ✅ | ✅ | ❌ |
| Float    | `to_f`                 | ✅ | ✅ | ❌ |
| Integer  | `to_int`, `to_i`       | ✅‡ | ✅ | ❌ |
| Rational | `to_r`, **`to_int`**\* | ✅ | ✅ | ❌ |

- †: Accepts `[]` too
- ‡: Accepts `.to_str`  in addition to `Strings`
- \*: Accepts `to_int` too, but that's a part of its `Rational(to_int, to_int)` signature, and not a part of its "conversions" signature


So what's an implicit conversion? As you can already see with the `Kernel` methods, they're a bit inconsistent about how they treat different conversion methods!

### `<Class>.try_convert`
Let's next take a look at the `try_convert` methods:
```ruby
class MyI
	def to_i = 1
end

class MyInt
	def to_int = 2
end

p Integer.try_convert('12')      #=> nil
p Integer.try_convert(MyI.new)   #=> nil
p Integer.try_convert(MyInt.new) #=> 2
```

In modern Ruby, these are rarely used, and you'd be excused for never remembering they existed. Unlike their `Kernel` brethren, these methods have consistent signatures (they all accept a single argument, and return `nil` if the argument doesn't define their conversion methods).

| Class     | `try_convert` method |
|:----------|----------------------|
| `Integer` | `to_int`             |
| `String`  | `to_str`             |
| `Array`   | `to_ary`             |
| `Hash`    | `to_hash`            |
| `Regexp`  | `to_regexp`          |
| `IO`      | `to_io`              |

Most of these make sense—you got the traditional "quadfecta" of `Integer`, `String`, `Array`, and `Hash`—but there's two addition ones you've probably never used: `Regexp`'s `to_regexp` and `IO`'s `to_io`[^30].

[^30]: You'll notice too that most of the `Numeric`-`Kernel`-method types—i.e. `Float`, `Rational`, and `Complex`—don't exist here. I think this makes sense for the latter two, but as we'll discuss later, I think `to_f` is actually an _implicit conversion_.

While mostly underused by end-users, `IO`'s conversion is actually used quite heavily in the source code (beating out `to_hash` and `to_ary` by a long shot):
```ruby
class MyIO
	def to_io = $stdout
end

# File.exist? can take a `.to_io`:
p File.exist? MyIO.new #=> true

# `Kernel#printf` can take an `to_io` as the first argument
printf MyIO.new, 'hello %s', 'world' #=> hello world
```
The bizarre thing is that most of the other types with "implicit conversions" that are used by Ruby, `IO` doesn't have its own `Kernel` method. How inconsistent!

However, the oddball of the lot is definitely `Regexp`: The `Regexp.try_convert` method, as well as `to_regexp`, is _only ever used_ in `Regexp.union`[^31]. That's it. But even more odd is that **Regexp does not define `to_regexp`**. What?? Every other an "implicit conversion" in the standard library—and even default gems like `JSON`—all define their conversion method. But `Regexp` doesn't. I think that alone is enough to disqualify "is converted in `try_convert`" as a valid contender.

[^31]: I also think that this is another reason that `to_regexp` can't really be counted as an implicit conversion method: It's only ever used in one spot, even though there's a few places it could be used, like `String#=~`.

So how about `try_convert` as a benchmark for what indicates "implicit conversion"? Well, those fall short too with `Regexp`'s `to_regexp` On top of that, as we'll get into in a few sections, there's actually a few other "implicit conversions" that also very much break the mold.

### Other Conversion Techniques
There's a handful of other "conversion" methods that exist in the stdlib. Because they aren't universally-adopted, I don't consider them "true" conversion methods, but for completeness let's talk about them.

First off, a couple of builtin types define a `[]` method (`Hash`, `Array`, `Fiber`, `Ractor`, `Thread`, and `Dir`), of which only `Array` and `Hash` are used to actually construct new instances. If you've never seen it before, `Array.[]` is essentially just a method form of the array literal: `[1, 2, 3]` is identical to `Array[1, 2, 3]` (albeit the literal is much more heavily optimized)[^32]. I suspect it was added to provide a "functional-programming-friendly" way to make arrays. But I've never needed it.

Contrast this to `Hash.[]`, which is an absolute mess. It supports three separate forms of "conversion":
1. If given one argument, which defines `.to_hash`, it returns that[^32].
2. If given one argument, which defines `.to_ary`, it calls that. The returned value should be an array of `[key, value]` pairs array (in the same format that `Hash#to_a` returns)[^33].
3. If given more than one argument, an even number needs to be present. It acts like the second form: `Hash[:a, 1, :b, 2]` is the same as `{a: 1, b: 2}`.

[^32]: I actually use this occasionally, when I need to pass a `Hash` as the first argument to a method; `assert_equal { 'a' => 'b' }, thing` fails because Ruby attempts to parse the hash as a block. Instead, `assert_equal Hash['a' => 'b'], thing` works.

[^33]: I think this is probably related to the `Kernel#Hash` accepting just an empty array and nothing else. The designer probably had something like this, or bullet point 3, in mind.
```ruby
class MyHash def to_hash = {a: 1, b: 2} end
class MyArray def to_ary = [[:c, 3], [:d, 4]] end

p Hash[MyHash.new]   #=> {a: 1, b: 2}
p Hash[MyArray.new]  #=> {c: 3, d: 4}
p Hash[:e, 5, :f, 6] #=> {e: 5, f: 6}
```

If you're used to `Hash.[]` attempting to convert its argument via `.to_hash`, you'd be surprised to try `Array.[]`, which doesn't. Somewhat inconsistent, but not the end of the world.

Also somewhat odd is how `Array.new` and `String.new` will call their respective implicit-conversion function methods when given a single argument, but `Hash.new` doesn't:
```ruby
class MyString def to_str = "hello" end
class MyArray def to_ary = [1, 2, 3] end
class MyHash def to_hash = {a: 1, b: 2} end

p String.new(MyString.new) #=> "hello"
p Array.new(MyArray.new)   #=> [1, 2, 3]
p Hash.new(MyHash.new)     #=> {}
```
Instead of using its constructor as _yet another conversion_, `Hash` uses the value it is given as the default. Sensible, but awkward that it doesn't line up.

Lastly, worth noting is `Numeric#coerce`, which is used when you want to convert arguments to a common type. It has pretty well-defined semantics, and doesn't make any use of the conversion methods, so we won't be talking about it any more.

Well. That about sums up the builtin ways to convert things. Let's look at how they're used in the syntax

## Syntactic Usages of Conversions
So far, we've explored `Kernel` methods, `<Class>.try_convert`s, and some other miscellaneous ways to convert things. Now let's see how they're used in different syntactic constructs.

Here's a table we'll go through:

| Method    | When |
|:----------|:-----|
| `#to_s`    | `"#{value}"` |
| `#to_proc` | `method(&value)` |
| `#to_hash` | `method(**value)` |
| `#to_a`    | `method(*value)` |
| `#to_ary`  | `a, b = value` |
| `Array.try_convert` | `for a, b in [value]` |

Let's go through these in order. The `to_s` for string interpolation is the easiest one, which everyone's used.[^100] Likewise, the `to_proc` one isn't terribly difficult to understand. Its most famous implementer is `Symbol#to_proc` (which lets you do fun things like `.map(&:empty?)`) but also supported is `Hash#to_proc` (which is equivalent to `hash.method(:[])`) and is quite handy in `gsub`: `"string".gsub(/[tr]/, &{'t' => 'T', 'r' => 'R'})`.

[^100]: Interestingly, only `.to_s` is attempted; It won't try a `.to_str` if no `.to_s` is found.

Next up, multiple-argument-assignments—`a, b = value`—calls `.to_ary` on the return value of `value`:
```ruby
class MyA def to_a = [1, 2] end
class MyAry def to_ary = [3, 4] end

a, b = MyA.new
p [a, b] #=> [#<MyA:0x0000000123957be8>, nil]

a, b = MyAry.new
p [a, b] #=> [3, 4]
```
This makes sense to me. After all, syntactic constructs (other than string interpolation as it's used so often) should all use their _implicit conversion_ operators.

Now, most of the oddities we've seen so far have come from `Hash`: `Kernel#Hash` doesn't accept `.to_h`, `Hash.[]` has some weird edgecases, heck even `Hash#to_proc` is defined. But this time, it's `Array` that's the problem. **Incredibly inconsistently**, `*value` calls `.to_a`, but `**value` calls `.to_hash`. This is just plain weird: why on earth would both keyword arguments and block parameters use an implicit conversion operator, but positional arguments use an explicit one? Utterly awkward.

### `Array.try_convert` and `for`
To round off the syntactic usages, we take a gander at `for` loops[^101].

[^101]: I'll be writing an article about `for` loops at some point. Stay tuned!

You might assume that, just like the multiple-argument-assignment we saw above, doing `for a, b in [value]; ... end` would end up calling `value.to_ary`. Well, you'd be sort-of right. What it actually does is _first_ calls `Array.try_convert(value)` (which eventually calls `.to_ary`). What's interesting though is, unlike every other syntactic conversion, you can actually _change_ the conversion method:

```ruby
# Just return two things!
def Array.try_convert(thing) = [thing, thing]

for a, b in [1]
	p [a, b]
end

#=> [1, 1]
```

In fact, you can actually return _anything you want_, at which point the return value is coerced to an array via a `.to_ary`:
```ruby
# Just return two things!
class MyAry def to_ary = [:hello, :world] end
def Array.try_convert(thing) = MyAry.new

for a, b in [1]
	p [a, b]
end
#=> [:hello, :world]
```

Which begs the question: Why exactly is `Array.try_convert` being called on `value` anyways if we're eventually going to call `.to_ary` on it anyways? Bizarre.

But, enough of that fun syntactic digression. Let's go onto conversions which don't fit the mold

## Conversions Which Don't Fit Into The Mold

So far, we've explored `Kernel` methods, `<Class>.try_convert`s, as well as some syntactic constructs. Let's summarize what we've seen so far before continuing on:


| Class      | Explicit    | Implicit    | Has `try_convert`? | Kernel method? |
|------------|-------------|-------------|--------------------|----------------|
| `Integer`  | `to_i`      | `to_int`    | ✅                 | ✅ |
| `String`   | `to_s`      | `to_str`    | ✅                 | ✅ |
| `Array`    | `to_a`      | `to_ary`    | ✅                 | ✅ |
| `Hash`     | `to_h`      | `to_hash`   | ✅                 | ✅† |
| `Regexp`   |             | `to_regexp` | ✅‡                | ❌ |
| `IO`       |             | `to_io`     | ✅                 | ❌ |
| `Float`    | `to_f`      |             | ❌                 | ✅ |
| `Rational` | `to_r`      |             | ❌                 | ✅ |
| `Complex`  | `to_c`      |             | ❌                 | ✅ |
| `Proc`     |             | `to_proc`   | ❌                 | ❌ |

- †: Doesn't accept `.to_h`
- ‡: `Regexp#to_regexp` doesn't actually exist


## `Float` and `.to_f`?
The first to break our mold is `Float`. Unlike the more useful `Integer`, `Float` doesn't have two conversions methods—a trait shared with its much less used brethren `Rational` and `Complex`; all it has is `to_f`.

However, unlike the other conversions, most usages[^40] of `to_f` in the standard library expect the class that `.to_f` is called on also to subclass Numeric. That means the following won't work:

[^40]: Of notable exception is when it's used as a "timeout," eg in `Regexp.new`. Awkwardly, most of the time that timeouts are used (eg `Kernel#sleep`, `Thread::Mutex.wait`, and `IO#wait_readable` to name a few) they actually use something entirely separate: A [`Time::_Timeout`](https://github.com/ruby/rbs/blob/4482ed2c4a3faca78b3c332480b956e99ab9788c/core/time.rbs#L438-L456) which just expects a type to respond to a `.divmod(1)`. Inconsistent!

```ruby
class MyFloat
	def to_f = 3.4
end

p Math.cos MyFloat.new
#: in 'Math.cos': can't convert MyFloat into Float (TypeError)
```

Instead you have to inherit from `Numeric`:
```ruby
class MyFloat2 < Numeric
	def to_f = 3.4
end

p Math.cos MyFloat2.new #=> -0.9667981925794611
```

Weird. I suspect this is because `Numeric` + `.to_f` is used as a proxy for "is a number-like type."[^41] So is `.to_f` explicit or implicit? I'd argue that it's probably close to an implicit one, as it's used implicitly all over the `Math` module (and in a few other places).

[^41]: There's a whole blog post to be written about how `Numeric` interacts with its subclasses, and how to write custom subclasses of it that play nicely!


### `to_path`
This is a fun one. Did you know in nearly[^50] every single method in Ruby that takes a file path _also_ takes a type that defines `to_path`?

[^50]: I hedge my bets because there's probably _one_ spot that doesn't, but I haven't been able to find it.

```ruby
class MyPath
	def to_path = '/tmp/foobar'
end

open(MyPath.new) # Yup, works!
File.delete MyPath.new # yup also works!
require MyPath.new # You betchya
test 'e', MyPath.new # even `Kernel#test`!
```

(If you've ever used the `Pathname` gem, this is actually how you can pass it to all the builtin methods: It defines `to_path`!)

What's so interesting about `to_path` is that it's so clearly a conversion method: It has the `to_` prefix, it's used _all over_ Ruby, and it implicitly converts types into a `String` that represents the filepath. But what's so odd is there _is no "Path" class_. There's no `Kernel#Path(...)`, no `Path.try_convert(...)`, or anything else. It's just something that Ruby does when it wants a filepath[^51].

[^51]: To be precise, Ruby uses [`FilePathValue`](https://github.com/ruby/ruby/blob/5e817f98af9024f34a3491c0aa6526d1191f8c11/include/ruby/ruby.h#L90), which first checks to see if its argument is a `String`; if it's not, it attempts `.to_path`, and if that fails `.to_str`, raises a `TypeError`.

## Custom `Range`s

Next up in the "what constitutes a conversion method" we have custom `Range`s. In most[^60] places that a `Range` is accepted you can also supply a custom `Range`:

[^60]: Flipflops don't work with custom ranges (as they're syntactic constructs). There's probably a few methods, but I haven't explored _all_ of Ruby's codebase to find out.

```ruby
class MyRange
	def initialize(b, e, ee) @b, @e, @ee = b, e, ee end
	def begin = @b
	def end = @e
	def exclude_end? = @ee
end

p [1, 2, 3, 4, 5][MyRange.new(1, 2, false)] #=> [2, 3]
p "abcdef".slice(MyRange.new(nil, 3, true)) #=> "abcd"
p rand(MyRange.new(10.0, 20.0, true)) #=> 17.12357937565296
```

You have to be very precise when setting up these custom ranges: If you don't define all the methods correctly, you'll usually be met with a completely unrelated conversion error[^61]:
```ruby
class MyRange2
	def initialize(b, e, ee) @b, @e, @ee = b, e, ee end
	def begin = @b
	def end = @e
	def exclude_end = @ee # oops, didn't use a `?`
end
p [1, 2, 3, 4, 5][MyRange2.new(1, 2, false)]
#=> :in '<main>': no implicit conversion of MyRange2 into Integer (TypeError)
```

[^61]: This is because in most methods where you'd use custom ranges (`[]` methods, `Kernel#caller`, etc.) you usually can _also_ supply a type that responds to `to_int` as the starting point. So when Ruby doesn't receive a custom range, it assumes you meant to pass in a custom integer, and attempts the `.to_int` conversion.

You may have noticed that, unlike other conversions, there's no `to_range` method; instead, the custom type is expected to define `begin`, `end`, and `exclude_end?` methods. This is a subtle but key difference: Instead of converting from your `MyRange` type into a `Range`, Ruby instead calls all the relevant methods _directly_ on your type. So the question is: Do `Range`s have an implicit conversion?

I'm torn on this.

On one hand, it doesn't feel like an implicit conversion: There's no `to_` prefix method, no `Kernel#Range`, and no `Range.try_convert`, which is the hallmark of most other implicit conversions. Instead, Ruby just calls `.begin`, `.end`, and `.exclude_end?` methods on the custom range. This is exactly what you'd expect from a "duck-typed" language to do.

But on the other hand, the only thing ruby actually _does_ with these methods on the custom range is to exact the bounds in much the same way it does with `Range`s, and then acts like the user passed in a normal `Range`. Additionally, these "custom ranges" are used in exactly the same way that the implicit conversions are: Just like how `String#[]` can be passed a type that's implicitly convertible to an `Integer` as the start and length, you can pass in a type that acts like a `Range` as the set of values to get.

Because they act so similarly to how the implicit conversions work[^62], my gut instinct is to call custom `Range`s another form of "implicit conversion". But I could be swayed.

[^62]: If the methods were `to_begin`, `to_end`, and `to_exclude_end?`, it'd feel more comfortable calling it an implicit conversion. But the usability of that would be terrible!

### Other Conversions
In addition to the above, there's a handful of other conversions that are used in the std library:

Most interesting is `Symbol`'s `.to_sym`. You might assume that it's used all over Ruby, after all lots of metaprogramming methods (like `instance_variable_get`, `define_singleton_method`, `const_defined?`, etc) all accept `String`s and `Symbol`s. However, those methods _actually_ accept a `Symbol`, a `String`, or a `.to_str`. Usages of `.to_sym` itself is actually limited to two places:
- `Kernel#warn`'s `category:` argument (but interestingly enough, not `Warning.warn`'s `category:`)
- `TracePoint#trace`'s `event` parameter.

`Set`, like the other collections, also has its own `.to_set` (but unlike `Array`, has no `try_convert`). What's curious is that `Set` never actually uses `to_set` at all, instead requiring other `Set`-like objects to define `each_entry` / `each`.

`Time` has a `to_time` method, which `DateTime` also defines. I haven't dealt enough with either to delve further in to it, but it looks like they're somewhat unused.

There's also a couple of honorable mentions:
- `ARGF.to_write_io`, which only works when the `-i` flag is passed / `$-i` is set.
- `Object#to_enum` (an alias of `enum_for`) which creates `Enumerator`s for methods
- `to_open`, which is used in `Kernel#open` to define "custom open methods"

## Table
Here's a table for conversion methods:

| Class      | Explicit    | Implicit    | Has `try_convert`? | Kernel method? |
|------------|-------------|-------------|--------------------|----------------|
| `Integer`  | `to_i`      | `to_int`    | ✅                 | ✅ |
| `String`   | `to_s`      | `to_str`    | ✅                 | ✅ |
| `Array`    | `to_a`      | `to_ary`    | ✅                 | ✅ |
| `Hash`     | `to_h`      | `to_hash`   | ✅                 | ✅, but doesn't accept `.to_h` |
| `Regexp`   |             | `to_regexp` | ✅, but isnt defined on regexp | ❌ |
| `IO`       |             | `to_io`     | ✅                 | ❌ |
| `Float`    |             | `to_f`      | ❌                 | ✅ |
| `Rational` | `to_r`      |             | ❌                 | ✅ |
| `Complex`  | `to_c`      |             | ❌                 | ✅ |
| `Symbol`   | `to_sym`    |             | ❌                 | ❌ |
|            |             | `to_path`   | ❌                 | ❌ |
| `Range`    |             | (yes)       | ❌                 | ❌ |
| `Set`      | `to_set`    |             | ❌                 | ❌ |
| `Proc`     |             | `to_proc`   | ❌                 | ❌ |
| `Time`     | `to_time`   |             | ❌                 | ❌ |

Note: There's a handful of "default gems" like `Pathname` and `URI` that I've excluded, because I only wanted to do builtin types.

## So, what is an implicit conversion?

This is hard.

All of the `try_convert` methods use what're traditionally considered "implicit conversions": `to_{int,str,ary,hash,regexp,io}`. However, I'd argue that `to_path` is _very much_ an implicit conversion, even if it doesn't have a backing type. Likewise, I'd say that `to_proc` and `to_f` are _probably_ implicit conversions.

So my current definition for an "implicit conversion" is "there is none." It's too vague to nail down a concrete definition, even if there are some things that are obviously implicit.
