# Interesting flags in ruby
Ruby has a ton of different short flags. I'd group them into:

One-liners:
  - `-0[octal]`       Set input record separator ($/)
  - `-a`              Split each input line ($_) into fields ($F)
  - `-Fpattern`       Set input field separator ($;); used with -a
  - `-i[extension]`   Set ARGF in-place mode
  - `-l`              Set output record separator ($\) to $/
  - `-n`              Run program in gets loop
  - `-p`              Like -n, with printing added

Debugging:
  - `-y` (hidden)
  - `-c`              Check syntax (no execution)
  - `-d`              Set debugging flag ($DEBUG) to true
  - `-v`              Print version; set $VERBOSE to true
  - `-w`              Synonym for -W1
  - `-W[level=2|:category]`     Set warning flag ($-W)

Encodings:
  - `-U` (hidden)
  - `-K` (hidden)
  - `-Eex[:in]`       Set default external and internal encodings

Imports:
  - `-Idirpath`       Prepend specified directory to load paths ($LOAD_PATH)
  - `-rlibrary`       Require the given library

Misc:
  - `-Cdirpath`       Execute program in specified directory
  - `-Xdirpath` (hidden)
  - `-x[dirpath]`     Execute Ruby code starting from a #!ruby line
  - `-e 'code'`       Execute given Ruby code; multiple -e allowed
  - `-s`              Define global variables using switches following program path
  - `-S`              Search directories found in the PATH environment variable
  - `-h`              Print this help message; use --help for longer message
  - `-\r`


Only `-C`, , `-r`, and `-E` (along with the hidden `-y`, `-U`, `-K`, and `-X`) aren't inspired by perl.
