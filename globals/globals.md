Globals in Ruby are some of the most fascinating things you can play around with, because they were enshrined very early on, and have a lot of oddities.

# `alias` globals
- including `alias $= $x`
- `English` ?

# The `-s` flag, and ways to define weird globals

# The `trace_var` (and `untrace_var`) methods

# Builtin globals

## Which globals are actually aliased
- Literally just `$:`/`$-I`/`$LOAD_PATH`

## The `$_` global
it's local
weird htings you can do with it, including `~/foo/`, `.. if /x/`, `print()`, etc

## Regex globals (`$~`, `$&`, ``$` ``, `$'` ,`$+`, `$<num>`)

## The `$=` global

## `$:`/`$-I`/`$LOAD_PATH` and `$"`/`$LOADED_FEATURES`
- `$:.resolve_feature_path`

## `$-x` globals in general

## Debugging globals: `$VERBOSE`/`$-v`/`$-w` (and `$-W`) and `$DEBUG`/`$-d`

## "`-e`" globals (`$/`/`$-0`, `$\`, `$,`, `$;`/`$-F`) ie things for switches

## I/O globals: `$stdin` (+ `$<`), `$stdout`/`$>`, and `$stderr`

## Exception Globals (`$!` and `$@`)

## Argument-fetching globals, `$.`, `$FILENAME`, (and `$_`?)

## read-only globals (`$-a`, `$-l`, `$-p`)

## Misc globals: `$$`, `$*`, `$-i` (which controls argf inplace mode), `$0`/`$PROGRAM_NAME`, `$?`

<!-- rb_(?!define_virtual_variable|gvar_ractor_local|define_hooked_variable|define_readonly_variable|aliased)\w*\("\$ -->

# Builtin List

Note we use "Identical" instead of "aliases" as technically only `$:` has aliases (`$-I` + `$LOAD_PATH`), whereas all other variables just refer to the same underlying structure.

| Name | Identical | Initial Value | Valid RBS types | Notes|
| `$_`
