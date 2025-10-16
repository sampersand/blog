# Ranking Kernel Methods

Let's tier-rank all the kernel methods for fun!

Little preface on things I dont use:
Personally, I've never used these Kernelmethods:
- `{Complex,Float,Hash,Rational,String}` - just use `.to_x` conversions
- `autoload{,?}` - never used autoload
- `caller_locations` - only ever really used `caller` for `raise`, which works just fine
- `sprintf` - `"string" % [...]` is my normal way, but occasionally i'll do `format`; never used `sprintf` alias
- `iterator?`, `set_trace_func` - used the non-deprecated variants
- `open` i almost never use anymore, methods defined on `File` are usually good
-  `putc` lol no need for that
- `readline{,s}` - no need for EOF raises, `gets` with `nil` is just nicer
- `select` - one of those "old C things that's not super useful unless you're writing ruby C"
- `spawn` - never needed to run other procs in ruby, but if I did i'd probably use it?
- `syscall` - never been compiled in
- `test` - just use `Dir` and `File` methods lol
- `yield_self` - just use

Ok, here's the tier list:

S: gets, abort, require, require_relative, puts, raise, exit, p, pp
A: `` ` ``, block_given?, caller, exit!, at_exit, warn, sleep, loop
B: Array, Integer, `__dir__`, eval, fork, fail, rand/srand, exec, system, catch/throw, binding, printf, print, open, load
C: Float, Hash, `__callee__`, `__method__`, autoload, autoload?, caller_locations, readline, global_variables, spawn, trap
D: Complex, Rational, String, test, select, format, readlines, trace_var/untrace_var
F: iterator?, set_trace_func, syscall, putc, sprintf, local_variables, lambda, proc
