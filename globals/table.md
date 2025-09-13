# Builtin List

Note we use "Identical" instead of "aliases" as technically only `$:` has aliases (`$-I` + `$LOAD_PATH`), whereas all other variables just refer to the same underlying structure.

"SCOPE"
| Name               | Readonly? | Identical    | Valid RBS types | Initial Value | Notes | TODO? |
|--------------------|-----------|--------------|-----------------|-------|---|
| `$VERBOSE`         | no        | `$-v`, `$-w` | `bool?`         | false (unless `-v`/`-w`/`-W` arg supplied) | Can be assigned any value, but uses truthiness | |
| `$-W`              | no        |              | `(0 \| 1 \| 2)`   | 1 (unless `-v`/`-w`/`-W` supplied)         | Returns `2`, `1`, `0` for `$-v` value of `true`/`false`/`nil`, respectively | |
| `$DEBUG`           | no        | `$-d`        | `any`           | false (unless `-d` supplied) | Can be assigned any value | |
| `$=`               | no        |              | `false`         | `false` | used to be used for case-insensitive string + regex comparsions, now always `false`. | |
| `$_`               | no        |              | `any`           | `nil` | "faux-global" (same scope as local variable) | |
| `$~`               | no        |              | `MatchData?`    | `nil` | "faux-global"; same as `Regexp.last_match` | |
| ``$` ``            | yes       |              | `String?`       | `nil` | "faux-global"; same as `$~.pre_match` | |
| `$'`               | yes       |              | `String?`       | `nil` | "faux-global"; same as `$~.post_match` | |
| `$+`               | yes       |              | `String?`       | `nil` | "faux-global"; same as `$~[-1]` | |
| `$&`               | yes       |              | `String?`       | `nil` | "faux-global"; same as `$~[0]` | |
| `$<digit>`         | yes       |              | `String?`       | `nil` | "faux-global"; same as `$[<digit>]` | |
| `$LOAD_PATH`       | yes       | `$:`, `$-I`  |                 |       |  | `$LOAD_PATH` amd `$-I` are actual aliases of `$:` |
| `$LOADED_FEATURES` | yes       | `$"`         |                 |       |  | + |
| `$stdin`           | no        |              |                 |       |  | + |
| `$stdout`          | no        | `$>`         |                 |       |  | + |
| `$stderr`          | no        |              |                 |       |  | + |
| `$<`               | no        |              |                 |       |  | + |
| `$!`               | yes       |              |                 |       |  | + |
| `$@`               | no        |              |                 |       |  | + |
| `$.`               | no        |              |                 |       |  | + |
| `$FILENAME`        | yes       |              |                 |       |  | + |
| `$*`               | yes       |              |                 |       |  | + |
| `$-a`              | yes       |              |                 |       |  | + |
| `$-l`              | yes       |              |                 |       |  | + |
| `$-p`              | yes       |              |                 |       |  | + |
| `$$`               | yes       |              |                 |       |  | + |
| `$-i`              | yes       |              |                 |       |  | + |
| `$PROGRAM_NAME`    | no        | `$0`         |                 |       |  | + |
| `$?`               | ?         |              |                 |       |  | + |

