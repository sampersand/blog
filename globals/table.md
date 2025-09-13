# Builtin List

Note we use "Identical" instead of "aliases" as technically only `$:` has aliases (`$-I` + `$LOAD_PATH`), whereas all other variables just refer to the same underlying structure.

| Name       | Readonly?    | Identical    | Valid RBS types | Initial Value | Notes |
|------------|--------------|--------------|-----------------|-------|
| `$VERBOSE` | no           | `$-v`, `$-w` | `bool?`         | false (unless `-v`/`-w`/`-W` arg supplied) | Can be assigned any value, but uses truthiness |
| `$-W`      | no           |              | `(0 | 1 | 2)`   | 1 (unless `-v`/`-w`/`-W` supplied)         | Returns `2`, `1`, `0` for `$-v` value of `true`/`false`/`nil`, respectively |
| `$=`       | no           |              | `false`         | `false` | used to be used for case-insensitive string + regex comparsions, now always `false`. |
| `$_`       | no           |              | `any`           | `nil` | "faux-global" (same scope as local variable) |
| `$~`       | no           |              | `MatchData?`    | `nil` | "faux-global" (same scope as local variable) |
| ``$` ``    | yes          |              | `String?`       | `nil` | "faux-global"; same as `$~.pre_match` |
| `$'`       | yes          |              | `String?`       | `nil` | "faux-global"; same as `$~.post_match` |
| `$+`       | yes          |              | `String?`       | `nil` | "faux-global"; same as `$~[-1]` |

    rb_define_virtual_variable("$&", last_match_getter, 0);
    rb_define_virtual_variable("$`", prematch_getter, 0);
    rb_define_virtual_variable("$'", postmatch_getter, 0);
    rb_define_virtual_variable("$+", last_paren_match_getter, 0);
Follow ups: can you change `$~` to subclasses?

## Regex globals (`$~`, `$&`, ``$` ``, `$'` ,`$+`)

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
