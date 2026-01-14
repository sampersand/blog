# Global variables tier list

Here's my tier list of global variables in Ruby, based on how useful they are IMO. It's ordered per tier.

S: `$*`, `$1`/`$2`..., `$?`, `$0`, `$stdout`, `$stderr`
A: `$!`, `$&`, `$'`, ``$` ``, `$.`, `$VERBOSE`, `$FILENAME`
B: `$+`, `$LOAD_PATH`, `$_`, `$F`, `$stdin`
C: `$$`, `$~`, `$<`, `$-I`, `$-v`, `$DEBUG`, `$PROGRAM_NAME`, `$LOADED_FEATURES`
D: `$,`, `$@`, `$>`, `$-F`, `$:`, `$-0`, `$/`, `$\`, `$-i`, `$-d`
F: `$"`, `$=`, `$;`, `$-W`, `$-w`, `$-a`, `$-l`, `$-p`


Reasoning:
- `$stdout`: I reassign this quite often, either in tests, or in one-line scripts.
- `$stderr`: I reassign this occasionally; less often than `$stdout` though.
- `$stdin`: I don't really use it directly all that often—I'm eeither using `$<`/`ARGF`, or `STDIN`.
- `$!`: Useful in `blah rescue abort "oops: #$!"`
- `$"`: Just use `$LOADED_FEATURES`. no need for shorthand really
- `$$`: Rarely useful
- `$&`, `$'`, ``$` ``: I use these all quite frequently
- `$*`: I use this instead of `ARGV`, as it's easy to get mixed up with `ARGF`
- `$+`: Used less than the other dollar globals, vars, but when I want it it's nice
- `$1`/`$2`...: I _love_ these, I use them all the time
- `$,`: Only ever used ever so rarely when `Kernel#print`ing things. usually a hack.
- `$.`: Useful when I need it, which is more often than you'd expect
- `$=`: Literally does nothing
- `$?`: I use `%x(...)` semi-frequently, and so `abort "oops" unless $?.success?` is nice.
- `$@`: I've never needed to see the backtrace of an exception. Fun fact, if you assign to it, it's the same as `$!.set_backtrace`
- `$0`: I use this all the time in scripts, especially for `usage`s
- `$PROGRAM_NAME`: When I'm writing actual code others will see, I use `$PROGRAM_NAME`. But more often than not, my code's just for me, so I use `$0`
- `$~`: In cases where I'd need to access the matchdata, i'd opt for `String#match` over `=~`. Only really useful in `case` expressions, but most of the other regex globals are better
- `$>`: Identical to `$stdout`; just used for code golf
- `$<`: Rarely used, instead I just call methods on `Kernel` directly. You can also just use `ARGF` itself.
- `$;`: Only used for `String#split`'s default value. On the off chance that I need to reference what `-F` has set, I just refer to `$-F`
- `$-F`: I rarely ever need to directly reference this
- `$:`: I don't fiddle with load path a lot, but when I do it's usually `$LOAD_PATH`
- `$LOAD_PATH`: I don't need to fiddle with load path a whole lot, but when I do i use this
- `$-I`: I use `$-I` instead of `$:` because it's easier for me to remember: c compilers use `-I` as the flag for include paths
- `$/`: I dislike how this and `$\` are so similar, they're the only two I get mixed up. If writing scripts, I prefer to use `$-0`
- `$-0`: I use this instead of `$/` when i'm doing one-liners, as i can remember what `-0` is (perl uses `-0`)
- `$\`: like `$,`, I use this when mucking around with `print`. But that's not terribly often.
- `$_`: Love-hate relationship with it. I use it when doing one-liners, but virtually never in actual code (unless i'm intentionally being hacky)
- `$-v` and `$-d`: If i'm feeling hacky or fancy, I'll use one of these. But in code I'm keeping around, I use their long-form versions. I use `$-d` even less than `$-v` as I don't use `$DEBUG` often
- `$VERBOSE`: I use this in smaller scripts to `warn` only in verbose mode
- `$-W`: While a cool concept (returns `0`/`1`/`2` for `$-v` of `nil`/`false`/true), I've never needed to do `foo if $-W > 1` or something
- `$-w`: Actually an alias of `$-v`. I have never needed to use it.
- `$-a`/`$-l`/`$-p`: I've literally not once needed to check to see if any of these flags were provided. It'd be nice if they were accessible from within a `require`, but they're set to `nil` until after all `-r` are resolved...
- `$-i`: I've manually set this exactly once. When I did, it was nice that it existed, but for the most part it's too weird to be used
- `$DEBUG`: I don't actually know what `$DEBUG` does for you, other than printing out _every_ exception. I don't use it often.
- `$FILENAME`: I use this occasionally, even in scripts. It's odd that it doesn't have a short-form version like `$.` / `$_`.
- `$LOADED_FEATURES`: I never really need to access this.
- `$F`: Bet you didn't know this one: It's what's populated when you use `-l -a` on the command line.
