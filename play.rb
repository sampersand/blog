trace_var(:$foo) { p 1 }
trace_var(:$foo) { p 2 }

trace_var(:$bar) { p 3 }
trace_var(:$bar) { p 4 }

p untrace_var(:$foo) #=> [#<Proc:0x0000000100d87290 ...>, #<Proc:0x0000000100d87330 ...>]
p untrace_var(:$bar) #=> [#<Proc:0x0000000100d87290 ...>, #<Proc:0x0000000100d87330 ...>]
__END__
trace_var :$foo, 'p 1'
trace_var :$foo, 'p 2'
trace_var :$foo, 'p 3'
trace_var :$foo, 'p 4'

begin
  old = untrace_var(:$foo)
  1
ensure
  old.reverse_each do |trace|
    trace_var(:$foo, trace)
  end
end




p untrace_var :$foo
__END__
trace_var :$LOAD_
trace_var :$bar do p [:bar, $bar] end

$bar = 3
alias $foo $bar
$foo = 9
$foo = 34
__END__
p $foo
$0 = "A"
fail rescue 3

$DEBUG = 1
ASSIGNED_VARS = Hash.new(0)
at_exit { pp ASSIGNED_VARS }

def trace_var_incr(name)
  trace_var(name) { ASSIGNED_VARS[name] += 1 }
end

trace_var_incr :$foo
trace_var_incr :$bar
trace_var_incr :$baz
$foo = 3
$bar = 3

__END__
trace_var :$bar, $baz = '$baz.replace $bar'
$bar = 'p :hello'
$bar = 'p :world'
$bar = 9
__END__
x = 3
class Foo
  Bar = :inside_foo
  def doit
    @instance = :hello
    trace_var :$foo, '@instance = Bar; p x'
    $foo = 3
    @instance
  end
end

Bar = :toplevel
p Foo.new.doit
p @instance

__END__
require 'blank'

class Baz
  Bar = :baz
  def bar; $a = 3 end
end
class Foo
  Bar = 3
  def bar
    trace_var :$a, "p Bar"
    Baz.new.bar
  end
end

    # trace_var :$a, "p Bar"
Bar = 9
p Foo.new.bar

__END__
trace_var :$a, 'p binding'
p binding
$a = 3
p 2

__END__
$a = 3
  untrace_var '$a', nil
  # $a = 3

trace_var to_str('a'), q=blank{def call(*) = ::Kernel.p("called!") ; def inspect = 'blank'} do end
# p defined? $a
p untrace_var :a, 'b'
__END__
$a = 3
$b = 3
p untrace_var to_str('$b'), q
  # trace_var :a
__END__
trace_var(:$my_variable) do |var|
  puts "here is where $my_variable was set: #{caller(1..1)}"
end

def foo
  $my_variable = 10
end

def bar
  foo
end

bar
__END__
trace_var :$BAR, q = 'puts "lol"'
$BAR = 9
q.replace 'puts "what"'
$BAR = 19
exit
trace_var(:$FOO) do |new|
  puts "Foo change: #$FOO #{new}"
end
$FOO = 34
__END__

$_ = :a # blank { def to_str = 'a' }
print 34 if /a/
__END__
trace_var(:$b){ p "yo!" }
alias $a $b
$a = 3


__END__
trace_var(:$foo, proc{puts "1"})
trace_var(:$foo, proc{puts "2"})

trace_var(:$foo, q = proc{puts "3"})
$foo = 34
untrace_var :$foo, q

trace_var(:$foo, q = proc{puts "3"})
untrace_var(:$foo).r.each do |val|
  trace_var(:$foo, val)
end

puts
$foo = 34

__END__
# class Lol
#   def doit
#     trace_var(:$var, '@x = 3')
#     $var = 3
#     untrace_var(:$var)
#   end
# end

# @x = 4
# Lol.new.doit
# p @x

trace_var :$a, 'puts "trace: 1"'
trace_var :$a, 'puts "trace: 2"'
trace_var :$a, 'puts "trace: 3"'

# later on:
trace_var :$a, q=proc{'puts "trace: 3"'}
trace_var :$a, q
$a = 4
p untrace_var :$a, q#'puts "trace: 3"'
p untrace_var :$a, q#'puts "trace: 3"'
$a = 5
exit


$a = 3
p untrace_var :$a, 'q'
p untrace_var :$a, /p 1/
exit
trace_var :$~ do
  p $~
end
$stdin = DATA

p gets =~ /./

__END__
#!ruby -W0
class Regexp
  # def =~(x)
  #   x < 3
  # end
end


$_ = Class.new(BasicObject){def to_str = "lol"}.new
if /(?<a>lol)/
  puts 'hi', a
end
__END__
alias $1 $a
p RUBY_VERSION
p $'
__END__
$> = Class.new{ def write(*) = nil; def inspect = "A" }.new
STDOUT.puts $stdout.inspect
__END__
p global_variables - [:$VERBOSE, :$-v, :$-w, :$-W, :$DEBUG, :$-d, :$=, :$_, :$~, :$&, :$`, :$', :$+, :$1, :$LOAD_PATH, :$:, :$-I, :$LOADED_FEATURES, :$", :$stdin, :$stdout, :$>, :$stderr, :$<, :$!, :$@, :$., :$FILENAME, :$*, :$-a, :$-l, :$-p, :$$, :$-i, :$PROGRAM_NAME, :$0, :$?, :$/, :$-0, :$\, :$,, :$;, :$-F,]
__END__
$0 = Class.new{def to_str = "hi"}.new
$0 = nil
p $0
__END__

$q = 'hi'.freeze
Ractor.new(name: 'one') {
  p $q
  $-i = "yas"
  100.times do
    $-i +=  '1'
    p [1, $-i]
    sleep 0.1
  end

  # p $-i
}
Ractor.new(name: "two") {
  $-i += "here"
  100.times do
    $-i +=  '2'
    p [2, $-i]
    sleep 0.1
  end
}
p ["start", $-i]
sleep 10
p ["after", $-i]

__END__
class Foo < RuntimeError
  # def set_backtrace(bt)
  #   @bt = bt
  #   # p "called: #{bt}"
  #   # @q = caller
  #   # super @q
  # end
  # $x=0
  # def backtrace
  #   @bt
  #   # p :s
  #   # # if ($x+=1) <= 1
  #   #   # @q
  #   # # else
  #   #   p 34
  #   # # end
  # end
end

begin
  raise Foo, "oops", ['oh']
rescue
  # $!.set_backtrace [1, 2, 3]
  $@ = Class.new(Array) {

    Array.instance_methods.each do |iv|
      eval "def #{iv}(...); p __method__; exit! 3; end"
    end
    (self.class.instance_methods - %i[new]).each do |iv|
      eval "def self.#{iv}(...); p __method__; exit! 3; end"
    end
  }.new ['9', '3'] # [Class.new{def to_str = "!"}.new]

  # p $@.class
  # p $@
  # p $@
  # $@ = 123
  # raise
  raise
end #rescue p ["backtrace:", $!, $@]
__END__
# $-I.replace [__dir__]

# p load 'tmp.ignore', Object.new
# p $-I
# $-I.replace [].freeze
$"[0].freeze
# $".replace Array.new { Class.new {
  # def to_str = "tmp.rb"
# }.new]
class << $:
  (Array.instance_methods - [:inspect]).each do
    eval "undef #{_1}"
  rescue
    p $!
  end
end
p require __dir__ + '/tmp.rb'
p require __dir__ + '/tmp.rb'
p $"
__END__
#!ruby -W0

class M < MatchData
end
"a" =~ /./
def $~.last_match; :yo end
p $`
p $+
# p $~.class.instance_methods false
# p $~.last_match
__END__
$_ = Class.new {
  def to_str = "woah"
    def =~ = :q
}.new

$_ = 'lola'
p :match if /(?<a>.)/
p a
p $&
__END__
# global_variables.each do |gv|
#   system "ruby", '-e', "#{gv} = q = Object.new; p [:#{gv}, #{gv}, q.equal?(#{gv})]", err: :close and p gv
# end

# ['$-w = true', '$-w = false', '$-w = nil'].each do |x|
#   eval x
#   p [x, $-w, $-W, $-v, $VERBOSE]
# end
# # $-w = true; p [$VERB]

# ["$-w = true",   true, 2, true, true]
# ["$-w = false", false, 1, false, false]
# ["$-w = nil",     nil, 0, nil, nil]

# p /./ =~ Class.new { def to_s = "b" }.new
$_ = :A
p ~/./
