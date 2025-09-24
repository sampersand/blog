#!~/.rbenv/shims/ruby
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
