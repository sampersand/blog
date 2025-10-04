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
