# Conversions

Conversions in Ruby are a mess.

Everyone who's used Ruby a little bit has run into the distinction of "explicit" conversions—for example, `to_i`, `to_s`, etc—and implicit conversions—`to_int`, `to_str`, etc. But what about those top-level `Kernel` functions like `Integer()`, `Array()`, etc? And how about the oft-unused `try_convert` methods like `Hash.try_convert`? They're actually quite inconsistent in how they do conversions. (And don't get me started on how the syntax doesn't even respect it. (Actually, we will get started and visit it later!))

So, let's dive in to the different ways to convert types in Ruby before converging on a definition for "implicit conversions"

## `Kernel` methods

Let's start off with the top-level `Kernel` methods: `Integer()`, `String()`, `Array()`, `Hash()`, `Float()`, `Rational()`, and `Complex()`. I won't be delving too deep into the uniques of each method (eg `Integer(string, base)`), as the point of this is to find a common definition for "implicit conversions"

The basic form of all these methods is when given a sole argument, to attempt to call the appropriate conversion method (and if the type has an implicit one, that's called first): `Complex` attempts `.to_c`, `Rational` attempts `to_r`, `String` attempts `to_str` followed by `to_s`, etc.

But _of course_, even this simple form has an oddity: `Kernel#Hash`. For some bizarre reason, it _never calls the explicit conversion method, `.to_h`_: It tried `.to_hash`, and if that doesn't exist raises a `TypeError`. My only guess as to why this oddity exists would be because for some reason Matz (or whomever wrote it) didn't want `Hash([['name', 'sam'], ['age', 27]])` to work. Yet, for some inexplicable reason, `Kernel#Hash` special cases an empty Array to return an empty Hash. This is so odd it bears repeating: `Hash([])` returns `{}`, but _every other array_ raises a `TypeError`. What??

Next up, the "`Numeric` methods"—`Integer`, `Float`, `Rational`, and `Complex`—also have a form where they accept `String`, and then convert that string to the corresponding type. You've probably used `Integer('string')` as a way to throw exceptions when the string isn't a valid `Integer`; the same concept applies to the other types: `Float('1e3')`, `Rational('3/4')`, and `Complex('1+2i')`[^1].

[^1]: Actually, `Rational` and `Complex` can take two arguments. While they normally and are numer+denom and real+imag, you can actually pass in any valid strings, and they'll be handled properly; `Rational('1/2', '2/3')` is the same as `(1/2r) / (2/3r)`, and `Complex('1+2i', '3+4i')` is `(1+2i) + (3+4i)*1i`.

But these are _also_ odd. For example, every one of these parsing methods only works if the argument that's supplied is a direct `String`, _except_ for `Integer`, which accepts either `String` or types that define `.to_str`. How's that for inconsistent?.[^2]

[^2]: They also all have their own ways of parsing, so eg `Integer('0d10')` (which is `10`) works, but `Rational('0d10')` doesn't.

Lastly, they handle `nil` differently: While `nil` defines all of the explicit conversion methods that're used by the methods, the `Numeric` conversions explicitly check fro `nil` and raise `TypeError`, whereas `Array`/`Hash`[^3]/`String` return an "empty" version of their classes.

[^3]: Which is all the odder given that `nil` doesn't define `.to_h`

Here's a handy dandy table:

| Method   | Conversions          | Parses Strings | Exceptions | Accepts `nil` |
|:---------|----------------------|----------------|------------|---------------|
| Array    | `to_ary`, `to_a`     | ❌ | ❌ | ✅ |
| Hash     | **`to_hash`**        | ❌ | ❌ | ✅† |
| String   | `to_str`, `to_s`     | ❌ | ❌ | ✅ |
| Complex  | `to_c`               | ✅ | ✅ | ❌ |
| Float    | `to_f`               | ✅ | ✅ | ❌ |
| Integer  | `to_int`, `to_i`     | ✅‡ | ✅ | ❌ |
| Rational | `to_r`, **`to_int`** | ✅ | ✅ | ❌ |

†: Accepts `[]` too
‡: Accepts `.to_str`  in addition to `Strings`

So what's an implicit conversion? As you can already see with the `Kernel` methods, they're a bit inconsistent about how they treat different conversion methods!

## `try_convert`
<!--

The tradition idea is that implicit conversions are for types that "act like" the type they're implicitly convertible to: You create your own custom `Array` type, and then whenever something expects an `Array`, it can just call `.to_ary` on yours to convert it!

<! -- Well, that's dandy, but why not call `.to_a`? Well, we'll talk about it. -- a

But, as we'll see, what exactly constitutes an "implicit conversion" is actually _quite vague_.



## Attempt 1: The "Official" Implicit Conversions

The [docs](https://docs.ruby-lang.org/en/master/implicit_conversion_rdoc.html) states "Some Ruby methods accept one or more objects that can be either: (1) _`Of a given class_`, and so accepted as is. (2) _`Implicitly convertible`_ to that class, in which case the called method converts the object." and then goes on to list out four examples:

- Array: `to_ary`
- Hash: `to_hash`[^1]
- Integer: `to_int`
- String: `to_str`

[^1]: This has _always_ bugged me—why is `Hash`'s implicit conversion spelled out? My guess is that because `.to_hsh` feels weird, but it's not _that_ weird.

So there's our answer! Implicit conversions are exactly those four things! Done!

... Ha, no. There's actually quite a few more types that have "implicit conversion methods" defined on them. Take for instance `IO`'s `.to_io`:
```ruby
class MyIO
	def to_io = $stdout
end

p File.exist? MyIO.new #=> true
```

The `.to_io` conversion us actually used in _quite a few places_ in the standard library—far more than the `.to_hash` conversion. So that list of four conversions isn't quite enough.

## Attempt 2: Explicit conversions use one letter

Well, another attempt to define explicit conversions could be that they use a single letter: `to_i`, `to_s`, `to_a`, etc, and implicit conversions are everything else.

Well, this doesn't quite hold either. Take for example `JSON`'s `.to_json`. This very clearly is not an implicit conversion—you have to always call it, it's never implicitly done. Or how about `Set`'s `.to_set`, which is never actually used in the standard library.

More damning, however, is `Float` Unlike it's more useful brother, `Integer`, `Float` doesn't have two conversions methods—a trait shared with its much less used brethren `Rational` and `Complex`; all it has is `to_f`.

However, unlike the other conversions, most usages[^2] of `to_f` in the standard library expect the class that `.to_f` is called expect the type it's called on to _also_ subclass `Numeric`. That means the following won't work:

[^2]: Of notable exception is when it's used as a "timeout," eg in `Regexp.new`. Awkwardly, most of the time that timeouts are used (eg `Kernel#sleep`, `Thread::Mutex.wait`, and `IO#wait_readable` to name a few) they actually use something entirely separate: A [`Time::_Timeout`](https://github.com/ruby/rbs/blob/4482ed2c4a3faca78b3c332480b956e99ab9788c/core/time.rbs#L438-L456) which just expects a type to respond to a `.divmod(1)`. Inconsistent!

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

Weird. So is `.to_f` an explicit conversion, or implicit? I'd argue it's probably closer to an implicit once (as for more reasons we'll see below), but it's an oddball because most of its usages also expect the calling class to inherit from `Numeric`[^3]

[^3]: I suspect this is because `Numeric` + `.to_f` is used as a proxy for "is a number-like type." There's a whole blog post to be written about how `Numeric` interacts with its subclasses, and how to write custom subclasses of it that play nicely!

## Attempt 3: `try_convert`
```ruby
p String.try_convert 'hello'
```




Or `Symbol`'s `.to_sym`:
```ruby
class MySymbol
	def to_sym = :deprecated
end

Warning[:deprecated] = true
warn "oops", category: MySymbol.new #=> oops

Warning[:deprecated] = false
warn "oops", category: MySymbol.new # (nothing)
```



## `.try_convert`
## Kernel methods
## Usage in syntactic constructs
## Honorable mentions

## Table

| Class      | Explicit    | Implicit    | Has `try_convert`? | Kernel method? |
|------------|-------------|-------------|--------------------|----------------|
| `Integer`  | `to_i`      | `to_int`    | ✅                 | ✅ |
| `String`   | `to_s`      | `to_str`    | ✅                 | ✅ |
| `Array`    | `to_a`      | `to_ary`    | ✅                 | ✅ |
| `Hash`     | `to_h`      | `to_hash`   | ✅                 | ✅, but only accepts `.to_h` |
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
Honorable mention: `to_open`, `to_enum`, `to_write_io`

## `coerce`
Kinda jank lol

## Syntactic uses

| Method    | When |
|:---------|:-----|
| `Array.try_convert` | `for a, b in [value]` |
| `#to_a` | `*value` |
| `#to_ary` | `a, b = value` |
| `#to_hash` | `**value` |
| `#to_proc` | `&value` |
| `#to_s` | `"#{value}"` |

## Other things to note
- `Hash.[]` calls `.to_hash`; only hash does this, other types (like `Array` and `Set`) don't.
- `Array.new` and `String.new` call their implicit functions, but `Hash.new` doesn't.
 -->
