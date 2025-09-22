Ruby has quite a few DSL in it, which require you to learn context-specific grammar.

Here's a few I can think of:
- Regexps
	- `{g,}sub`'s backreferences (eg `` \`[\&]\' ``)
- `Array#pack`/`String#unpack`
- `Dir.glob`, `File.fnmatch`
- `sprintf`
- `{Date,Time,DateTime}#strftime`
- `String#{tr,tr_s,delete}`
