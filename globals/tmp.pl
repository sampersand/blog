while ($line = <DATA>) {
	chomp $line; # delete trailing newline off `$_`
	next unless $line =~ /hello world/; # Require that `$_` contains `hello world` in it
	$line =~ s/hello/hola/; # replace `hello` with `hola` in `$_`
	$line = uc $line;  # convert `$_` to uppercase
	print $line # print out `$_`
}

__DATA__
p
this is a hello world tesat
woah this is a hello world
jpl
