#!ruby -W0
class M < MatchData
end
"a" =~ /./
p $~.class.instance_methods false
p $~.last_match
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
