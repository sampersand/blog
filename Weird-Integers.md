# Weird Integers in Ruby

When you learn a new programming language, you invariably end up needing to convert from strings to integers at one point. In Ruby, it's pretty simple: Just call `.to_i` on the String:
```ruby
string = "123"
puts 2 * "123".to_i #=> 246
```

If you're more mathematically inclined, or fiddle with raw bytes, you may eventually need to convert strings to integers in bases other than ten. Well, lucky for you: You're using Ruby, and it's easy!
```ruby
puts "FF".to_i(16) #=> 255
```

This is probably as far as most people will ever need to go. However, `String#to_i` in Ruby supports some weird edgecases.

## Prefixes and Base `0`
Like most languages that support converting strings to integers, Ruby support bases `2` through `36` (as `z` is the end of the alphabet). However, Ruby _also_ lets you pass in `0` as the base to `.to_i`, which actually chooses the base based on the format of the input string:

```ruby
puts "0x26".to_i(0)     #=> infers base 16, from `0x`
puts "046".to_i(0)      #=> infers base 8, from `0`; `0o` would work too
puts "0b100110".to_i(0) #=> infers base 2, from `0b`
puts "123".to_i(0) #=> everything else is base 10
```
Pretty nifty. While I've never needed this feature before, it's nice that it exists, as it wouldn't be trivial to implement.

## Prefixes and `Kernel#Integer()`
The prefixes aren't just limited to when you use base `0`. For some reason, these prefixes are _also_ supported when explicitly converting a base, but only for that base:
```ruby
puts "0x26".to_i(16) # works, as `0x` is base 16 prefix
puts "0o26".to_i(16) # returns `0`, as `0o` is for base 8
```

It's a bit bizarre to accept these, but they don't seem _that_ bad—after all, `String#to_i` is the "more permissible" one. Surely, the stricter `Kernel#Integer` doesn't fail here:
```ruby
puts Integer("0x20", 16) #=> 32
```
What? That surely seems like a possible bug waiting to happen.

## Base 10
Up to now I've been hiding a dastardly truth bomb from you: Ruby _also_ supports base 10 prefixes: `0d` (or `0D`).
```ruby
# It's actually valid syntax in ruby!
puts 0d12 #=> 12
puts 0D99 #=> 99

# Works with base `0`
puts '0d23'.to_i(0) #=> 23

# And works with base `10` like other prefixes
puts '0d23'.to_i(10) #=> 23
```
It works just like the other prefixes—no problem here. Right? Well... wrong. The _default argument_ for `String#to_i` is `10`. Which means that `"0d23".to_i` is actually `23`, _not_ `0` like you'd expect.

This problem _also_ extends to `Integer`:
```ruby
puts Integer('0d23', 10) #=> 23
```

## How To Convert a Plain String of Digits
"So what?" you might say. "It's a weird edge case that doesn't really matter" Well. The problem is that it _does_ matter: **There is no way in Ruby to convert a plain string of digits to a number, and fail on any other input**:

`String#to_i` is quite permissive. These are all valid, and are all equal to `123`:
```ruby
"  \n\t123".to_i  # Strips leading whitespace
"123garbage".to_i # ignores trailing garbage
"+123".to_i       # Leading `+` and `-` are allowed
"0d123".to_i      # `0d` prefix supported
```

`Kernel#Integer()` is a bit less permissive, but still has edgecases[^1]:

[^1]: Quick side note: `KernelInteger`'s base argument actually defaults to `0`, instead of `10` like `String#to_i`: `Integer("020")` is `32`, vs `"020".to_i` which is `20`.

```ruby
  Integer("  \n\t123") # Strips leading whitespace
# Integer("123garbage") # Integer raises an ArgumentError here!
  Integer("+123") # Leading `+` is allowed
  Integer("0x7B") # Surprisingly, `Integer` defaults to base `0`
# Integer("0x7B", 10) # This will correctly fail
  Integer("0d123", 10) # `0d` prefix is supported even in base 10
```

## Conclusion
Unfortunately, Ruby doesn't have a simple builtin way to simply convert a String of digits to an integer, and reject everything else: `String#to_i` is far too permissive in what it allows, and while `Kernel#Integer` is slightly better, it still permits leading whitespace and the `0d` prefix.

So to do strict conversions, you'll just need to do it yourself:
```ruby
class String
  def to_i_strict(base=10)
    # Don't allow base `0`, as it's for inferring
    base.zero? and raise ArgumentError, "invalid radix: #{base}"

    # Don't permit leading whitespace, as `Integer` does
    start_with? /\s/ and raise ArgumentError, 'leading whitespace'

    # Disallow prefixes
    if (base ==  2 && start_with?(/0[bB]/))
    || (base ==  8 && start_with?(/0[oO]/))
    || (base == 10 && start_with?(/0[dD]/))
    || (base == 16 && start_with?(/0[xX]/))
    then
      raise ArgumentError, "invalid value for integer: #{inspect}"
    end

    # Use `Integer` instead of `to_i` to catch trailing garbage
    Integer(self, base)
  end
end
```
