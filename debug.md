# Debug mode

Ruby has a "debug mode," which by passing `-d`/`--debug` on the command line, or by setting the `$DEBUG`/`$-d` global variables to a truthy value[^1].

[^1]: Unlike every other builtin global other than `$_`, `$DEBUG` can actually be assigned _any value_, and will retain it.

## What _exactly_ does debug mode do in Ruby?

Here's a complete list (as of Ruby 4.0.1[^2]) of what turning debug mode on changes.

[^2]: These don't change often.

### Prints an exception when it occurs
This is the most commonly encountered use of debug mode: Whenever an exception is raised, ruby will _always_ print it out, regardless of whether the exception is caught or not:
```
% ruby -e 'raise "oops" rescue nil'

% ruby -d -e 'raise "oops" rescue nil end'
Exception 'RuntimeError' at -e:1 - oops
```

#### Provides additional info on modified frozen strings:
A variant of the "printing exceptions", when a frozen string is modified, debug mode adds where the string was created:
```
% ruby --enable=frozen-string-literal \
	-e '"A".concat("3")'
-e:1:in 'String#concat': can't modify frozen String: "A" (FrozenError)
	from -e:1:in '<main>'

% ruby -d --enable=frozen-string-literal \
	-e '"A".concat("3")'
Exception 'FrozenError' at -e:1 - can't modify frozen String: "A", created at -e:1
-e:1:in 'String#concat': can't modify frozen String: "A", created at -e:1 (FrozenError)
	from -e:1:in '<main>'
```


### Raises exceptions in `printf`
When you use `Kernel#printf` and related methods (eg `Kernel#{sprintf,format}`, `String#%`, `IO#printf`), and provide too many arguments, one of three things happens depending on how `$DEBUG` and `$VERBOSE` are set:
```
% ruby -e 'puts format("%d", 1, 2)'
1

% ruby --verbose -e 'puts format("%d", 1, 2)'
-e:1: warning: too many arguments for format string
1

% ruby --debug -e 'puts format("%d", 1, 2)'
-e:1:in 'Kernel#format': too many arguments for format string (ArgumentError)
	from -e:1:in '<main>'
%
```
In debug mode, it actually raises an exception!

### Raise exceptions when `join`ing threads
If you're on the main thread, and you join a thread which had previously raised an exception, when debug mode is enabled, it'll raise an exception from your thread:

```ruby
Thread.new { raise } # Raise an exception in a thread
th = Thread.new { 'do nothing' }

sleep 0.1 # make sure the first thread runs
th.join #=> no exception
```
vs
```ruby
Thread.new { raise } # Raise an exception in a thread
th = Thread.new { 'do nothing' }

sleep 0.1 # make sure the first thread runs
$DEBUG = true
th.join #=> exception
```

And that's it. Not a whole lot.

## Fun facts from Ruby 0.49

Here's some fun facts about debug mode in Ruby 0.49:
- both `-d` _and_ `--debug` existed!
- Only `$DEBUG` existed, not `$-d`
- `$DEBUG` was never actually used in the code---only `$VERBOSE` was.
