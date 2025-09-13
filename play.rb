#!/Users/sampersand/.rbenv/shims/ruby

Ractor.new {
  # $. = 3
  # $= = 9
  # $LOAD_PATH = 9
  # $LOADED_FEATURES = 9
  # $< = 9
  # $. = 9
  # $FILENAME = 9
  # $* = 9
  p $0
  p $-i
  $-i = 'eys'
}
p ["start", $-i]
sleep 0.4
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
