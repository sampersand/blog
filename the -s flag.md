# The `-s` flag in Ruby
The `-s` flag is a useful, but underused and archaic part of ruby.


## Segfault
This segfaults, and I haven't nailed down why:
```sh
ruby --disable=gems -rfileutils -s <(echo 'p $DEBUG') -DEBUG=x
```

Here's some notes about it (i need to cleanup, just a post I sent):

`-s` is handled before _anything else_, including `-r`, but sadly the only acceptable options are in the form `-[a-zA-Z0-9_-]*` where `-` is translated to `_`. What this means it that you can possibly overwrite only "word-y" global variables:
- `$LOAD_PATH`, `$LOADED_FEATURES`, and `$FILENAME` are all read-only
- `$stdout` and `$stderr` need a type with `.write` (which `String` and `TrueClass` don't)
- `$stdin` needs a type with `.set_encoding` (which `String` and `TrueClass` don't)
- `$0` and `$PROGRAM_NAME` are set by Ruby explicitly later on, overwriting whatever's there.
-  `$VERBOSE` is always set to `true`
- `$_` can be set, but that's not super interesting because you can do that normally
- `$DEBUG` can be set and seems to lead to a bunch of bugs (like the above segfault)

Since the options are handled before anything else, you can't use `-rEnglish` to write to non-word globals. Also, you can't use `BEGIN` to define the appropriate methods, or anything else to force `$std{in,out,err}` to work because the method needs to be defined beforehand.

However, you can do a few funky things with other values:
- You can use `--=...` as an alias for `-_=...` because of the translation; but `--` on its own doesn't replace `-_` (as `--` marks end of arguments)
- `-=...` is totally valid, and creates a global variable with an empty value. However, since there's no `global_variable_get` there's literally no way to access it
- `-1` and other variables are also valid, but like `-=...` there's no way to access them (as `$1`, `$2`, ... *always* refer to the regex variables)
