#!~/.rbenv/shims/ruby --disable=gems

ObjectSpace.each_object do |o|
  case o
  when String, Class, Encoding, Module, Symbol then next
  else p o
  end
end
__END__
CONST_O__ = :OUT
CONST_O_S = :OUT
CONST_OC_ = :OUT
CONST_OCS = :OUT

class CLASS
  CONST_OC_ = :CLASS
  CONST_OCS = :CLASS
  CONST__C_ = :CLASS
  CONST__CS = :CLASS

  def meth
    singleton_class.instance_eval <<~RUBY
      const_set :CONST_OCS, :SING
      const_set :CONST_O_S, :SING
      const_set :CONST__CS, :SING
      const_set :CONST___S, :SING
    RUBY

    %i[CONST_O__ CONST_O_S CONST_OC_ CONST_OCS CONST_OC_ CONST_OCS CONST__C_ CONST__CS CONST_OCS CONST_O_S CONST__CS CONST___S
    ].each do |c|
      p [c, eval("defined?(#{c})"), self.class.const_defined?(c), singleton_class.const_defined?(c), ]
    end
    # p eval "CONST___S"
  end
end

c = CLASS.new

p binding.local_variable_defined? :a
p defined? a
binding.local_variable_set :a, 34
p binding.local_variable_defined? :a
__END__
CONST_A = :OUT
CONST_B = :OUT
CONST_C = :OUT
class Foo
  CONST_B = :FOO
  CONST_C = :FOO

  def bar
    singleton_class.instance_eval <<~RUBY
      CONST_A = :IN
      CONST_B = :LOL
    RUBY

    p defined? @@cls
    p singleton_class.class_variable_defined? :@@cls
    p self.class#.class_variable_defined? :@@cls
    p self.class.class_variables
  end
  def baz
    self.class.class_variables
    eval "p @@cls"
  end
end

p TOPLEVEL_BINDING.class.instance_methods false #
# const_set :Foo
exit
Foo.new.bar
p Foo.new.baz
__END__

class Foo
  # def b = defined?(FOO)
  def f = 34
  def b
    def self.q = 34
      class << self
        private :q
      end
    # p self.class.method_defined? :q #.methods.grep /method/
    p respond_to? :q #.methods.grep /method/
  end
end
# p defined? (a,*b = F)
# eval "
# FOO = 3"
x=Foo.new;
p x.respond_to? :q
p x.singleton_class.method_defined? :q
p defined? x.q
__END__
$num = 0
class Example
  def initialize; puts "initialized!" end
  def hello; puts "hello"; Other end
end

class Other
  SINGLETON = Other.new
  def +(rhs) = true
end


p defined?(Example.new.hello::SINGLETON + 3)

__END__
class Example
  def initialize; puts "initialized!" end
  def hello; puts "hello"; SomeMod end
end

module SomeMod
  WORLD =
  module_function
  def const_missing(c)
    # "yay!".to_i
    3
    # p c; exit! 2
  end
  # def const_get(c) p c; exit! 2 end
  # def const_set(c) p c; exit! 2 end
end


p defined?(Example.new.hello::WORLD + 3)

__END__
'a' =~ /./
if /(?<greeting>\w+), (?<name>\w+)?/ =~ "hello, "
  p name
  p defined? name
end

__END__
module GiveADefaultGreeting
  def greeting
    p [self.class.method_defined?(__method__), __method__]
    defined?(super) ? super : '👋, 🌎'
  end
  alias yo greeting
end

class English
  def greeting = 'Hello, World'
  def yo = "lol"
  prepend GiveADefaultGreeting
end

class Normal
  include GiveADefaultGreeting
end

# p English.new.greeting #=> Hello, world
p English.new.yo
p English.new.greeting
# Normal.new.greeting #=> 👋, 🌎


__END__
[*global_variables, :$1, :$2].each do |gv|
  p [gv, eval("defined? #{gv}")]
end


[:$&, nil]
[:$`, nil]
[:$', nil]
[:$+, nil]
[:$=, "global-variable"]
[:$>, "global-variable"]
[:$stdout, "global-variable"]
[:$stderr, "global-variable"]
[:$stdin, "global-variable"]
[:$VERBOSE, "global-variable"]
[:$,, "global-variable"]
[:$<, "global-variable"]
[:$-0, "global-variable"]
[:$\, "global-variable"]
[:$., "global-variable"]
[:$FILENAME, "global-variable"]
[:$-i, "global-variable"]
[:$/, "global-variable"]
[:$-I, "global-variable"]
[:$*, "global-variable"]
[:$", "global-variable"]
[:$LOAD_PATH, "global-variable"]
[:$:, "global-variable"]
[:$DEBUG, "global-variable"]
[:$LOADED_FEATURES, "global-variable"]
[:$-v, "global-variable"]
[:$-w, "global-variable"]
[:$-W, "global-variable"]
[:$_, "global-variable"]
[:$~, "global-variable"]
[:$!, "global-variable"]
[:$PROGRAM_NAME, "global-variable"]
[:$-p, "global-variable"]
[:$-l, "global-variable"]
[:$-a, "global-variable"]
[:$-d, "global-variable"]
[:$0, "global-variable"]
[:$?, "global-variable"]
[:$$, "global-variable"]
[:$@, "global-variable"]
[:$;, "global-variable"]
[:$-F, "global-variable"]
[:$1, nil]
[:$2, nil]
[Finished in 146ms]
