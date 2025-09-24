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
