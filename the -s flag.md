# The `-s` flag in Ruby
Ruby has lots of fun flags you can pass to the interpreter. They—especially short-form ones—have remained virtually unchanged since [Ruby 0.49](https://github.com/sampersand/ruby-0.49), which means there's lots of interesting stuff to be learned from them. This post is about one of my personal favourites, the underused `-s` flag.

# Overview
Copied directly from Perl, the `-s` flag causes Ruby to do _very_ rudimentary parsing of "flags" for your program, sticking any variables that are found in global variables. For example:
```shell
# Normally, `$x` is unset
ruby -s -e 'p $x'
#=> nil

# Supplying `-x` defaults it to `true`:
ruby -s -e 'p $x' -- -x
#=> true

# You can use `=` to assign a value:
ruby -s -e 'p $x' -- -x=hello
#=> "hello"

# You can supply longer flags too:
ruby -s -e 'p $foo' -- -foo=3
#=> "3"

# You can also use `-`, and they change to `_`:
ruby -s -e 'p $_hello_world' -- --hello-world=9
#=> "9"

# You can use `--` to stop parsing arguments:
ruby -s -e 'p [$y, $*]' -- -y -- -a -b
# =>[true, ["-a", "-b"]]
```

(Note that the first `--` is required when the program is supplied via `-e`, however when you're using a file, you omit it: `ruby -s foo.rb --hello-world=9`.)

Quite useful for short scripts, but there's quite a few problems with it:
1. It only parses `String`s out, and not numbers :-(
2. There's no error checking—if you typo a variable name, there's no way to detect it
3. It only supports ASCII variable names (`[a-zA-Z0-9_]`), even though Ruby supports non-ASCII globals. (i.e. `-s ... -π=3` fails, but `$π = 3` works.)
4. It doesn't support "combined short flags"; `-xyz` is `$xyz` not `$x`, `$y`, and `$z`.

Because of these problems, `-s` is languishes for anything other than throwaway scripts. ([Although I tried adding in a `-g` flag to change that](https://bugs.ruby-lang.org/issues/21015)).

# Oddities
With how it's meant to be used out of the way, let's try using it in ways that _weren't_ intended :-P.

## Weird global variables
By mucking around with `-s`, we can actually create a few different weird global variables:

Because Ruby translates all `-`s to `_` in these global variables, `--=...` is actually an alias for `-_=...`, which lets you assign to the global variable `$_`! However, you can't just use `--` on its own as a way to assign `$_` to `true`, because `--` stops parsing arguments!

Due to how the parsing works, `-=...` is a totally valid switch, and creates a global variable without a name! (try `ruby -se 'p global_variables.grep /^\$$/' -- -=3`). Sadly, unlike constants, instance variables, local variables[^1], and class variables, there's sadly no way to _access_ global variables without using `eval`. And, since `$` on its own is not a global variable name, there's literally no way to ever interact with it!

And, interestingly enough, you can _also_ use numbers for global variables (`-1` is totally valid). Unfortunately, Ruby doesn't let you access these at all, as `$1`, `$2`, ... _always_ refer to the regexp variables.

[^1]: Via `binding.local_variable_get`

## Futzing with Builtin Globals
But enough of global variables you can't ever access, what about futzing with the builtin global variables?

Well, unfortunately the `-s` flag _only_ accepts variables in the regex `/\A-[a-zA-Z0-9_-](=.*)?\z/`, i.e. they only allow ASCII alphanumerics, `_`, and `-`. That unfortunately means you can't write `-*=3` and expect to be able to modify the `$*` global variable.

"But wait! What about `English`[^2]" you might be thinking: That way, you can do `ruby -s -rEnglish -e 'p $*' -- -ARGV=3` as a way to muck with `$*` (as `English` provides `alias $ARGV $*`). Well, sadly that doens't work, because `-s` is handled _before_ all `-r`s. So, what ends up happening is a pain-old `$ARGV` variable is assigned by `-s`, and then `-rEnglish` just overwrites whatever was there. Alas.

[^2]: `English` is a [default gem](https://github.com/ruby/English/blob/master/lib/English.rb) that provides word aliases for lots of builtins, such as `$ERROR_INFO` as an alias for `$!`.

## Overwriting "word-y" globals
However, there's still plenty of "word-y" globals in Ruby that we can play with. Let's take a look at them, and see what supplying them as arguments does:
- `$LOAD_PATH`, `$LOADED_FEATURES`, and `$FILENAME` are all read-only.
- `$stdout` and `$stderr` need a type with `.write` (which `String` and `TrueClass` don't)[^3]
- `$stdin` needs a type with `.set_encoding` (which `String` and `TrueClass` don't)
- `$0` and `$PROGRAM_NAME` are set by Ruby a little later (after all `-s` processing is done), clobbering whatever was there before.
- `$VERBOSE` is always set to `true`
- `$_` can be set, but that's not super interesting because you can do that normally.

Things look dire. However, there is one variable that saves the day:
- `$DEBUG` can be set and seems to lead to a bunch of weird bugs!

[^3]: You can't use `BEGIN` to define the appropriate methods, or anything else to force `$std{in,out,err}` to work because the method needs to be defined beforehand.

`$DEBUG` is actually a perfect contender: Unlike most other builtin globals, it can be assigned _any value_, and retains it. Additionally, it's used occasionally internally within Ruby. This confluence gives u a perfect recipe for finding bugs in Ruby. And in fact, I found a segfault.

# The Segfault
After playing around with ruby, I've come up with this way to segfault it:
```sh
ruby --disable=gems -rfileutils -s -e 'p $DEBUG' -- -DEBUG=x
```
Try it out! It segfaults everything I've tried, from Ruby 2.7 all the way to Ruby 3.5.0-preview1. However, the segfault seems to be spurious—some versions require you to omit `--disable-gems`, some require you to omit `-rfileutils`, and others only do it every so often (and so you may need to repeat it.)

What causes the segfault? Well... I'm not actually sure. I've spent a _lot_ of time debugging it, recompiling ruby with my own debug tools, etc., and nothing seems to work. Best I can figure out is that it's something to do with some lower-level optimizations where `$DEBUG` isn't expected to be holding a `String` value early on, and gets a double-free error. If you manage to find out, please LMK!

# Conclusion
Yeah, sorry. The segfault was somewhat anticlimactic, but I really don't have a better deep-dive into what happened. Anyways, hopefully this was a fun exploration of how `-s` works and how to abuse it.
