# What does enabling debug mode in ruby do?

Debug mode is enabled by `-d` on the command line, or setting `$-d`/`$DEBUG` to a truthy value.

Here's the complete list (as of Ruby 4.0.0, though it doesn't change much) of what enabling it does for you:

## Provides additional info on modified frozen strings:
```
% ruby --enable=frozen-string-literal -e '"A".concat("3")'
-e:1:in 'String#concat': can't modify frozen String: "A" (FrozenError)
	from -e:1:in '<main>'
% ruby -d --enable=frozen-string-literal -e '"A".concat("3")'
Exception 'FrozenError' at -e:1 - can't modify frozen String: "A", created at -e:1
-e:1:in 'String#concat': can't modify frozen String: "A", created at -e:1 (FrozenError)
	from -e:1:in '<main>'
```

## Prints an exception when it occurs
If debug mode is enabled, ruby _always_ prints out exceptions, regardless of whether they're captured:
```
% ruby -e 'begin; raise "oops"; rescue Exception; end'
% ruby --debug -e 'begin; raise "oops"; rescue Exception; end'
Exception 'RuntimeError' at -e:1 - oops
```

## Raises exceptions in `sprintf`
When you use `Kernel#sprintf`, `Kernel#format`, or `String#%`, and provide too many arguments, one of three things happens depending on how `$DEBUG` and `$VERBOSE` are set:
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
In debug mode, it actually raises an exception.

## Raise exceptions when `join`ing threads
If you're on the main thread, and you join a thread which had previously raised an exception, when debug mode is enabled, it'll raise an exception from your thread:

```ruby
x = Thread.new { 'do nothing' }
e = Thread.new { raise }

sleep 0.1 # make sure `e` also runs
x.join #=> no exception
```
vs
```ruby
x = Thread.new { 'do nothing' }
e = Thread.new { raise }

sleep 0.1 # make sure `e` also runs
$-d = true
x.join # => raises a runtime exception
```
