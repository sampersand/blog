# Builtin List

Note we use "Identical" instead of "aliases" as technically only `$:` has aliases (`$-I` + `$LOAD_PATH`), whereas all other variables just refer to the same underlying structure.
<!--
| Name               |  Identical    | Valid RBS types | Initial Value | Notes | TODO? |
|--------------------|---------------|-----------------|-------|---|
| `$VERBOSE`         |  `$-v`, `$-w` | `bool?`         | false (unless `-v`/`-w`/`-W` arg supplied) | Can be assigned any value, but uses truthiness | |
| `$-W`              |               | `(0 \| 1 \| 2)`   | 1 (unless `-v`/`-w`/`-W` supplied)         | Returns `2`, `1`, `0` for `$-v` value of `true`/`false`/`nil`, respectively | |
| `$DEBUG`           |  `$-d`        | `any`           | false (unless `-d` supplied) | Can be assigned any value | |
| `$=`               |               | `false`         | `false` | used to be used for case-insensitive string + regex comparsions, now always `false`. | |
| `$_`               |               | `any`           | `nil` | "faux-global" (same scope as local variable) | |
| `$~`               |               | `MatchData?`    | `nil` | "faux-global"; same as `Regexp.last_match` | |
| ``$` ``            |               | `String?`       | `nil` | "faux-global"; same as `$~.pre_match` | |
| `$'`               |               | `String?`       | `nil` | "faux-global"; same as `$~.post_match` | |
| `$+`               |               | `String?`       | `nil` | "faux-global"; same as `$~[-1]` | |
| `$&`               |               | `String?`       | `nil` | "faux-global"; same as `$~[0]` | |
| `$<digit>`         |               | `String?`       | `nil` | "faux-global"; same as `$[<digit>]` | |
| `$LOAD_PATH`       |  `$:`, `$-I`  |                 |       |  | `$LOAD_PATH` amd `$-I` are actual aliases of `$:` |
| `$LOADED_FEATURES` |  `$"`         |                 |       |  | + |
| `$stdin`           |               |                 |       |  | + |
| `$stdout`          |  `$>`         |                 |       |  | + |
| `$stderr`          |               |                 |       |  | + |
| `$<`               |               |                 |       |  | + |
| `$!`               |               |                 |       |  | + |
| `$@`               |               |                 |       |  | + |
| `$.`               |               |                 |       |  | + |
| `$FILENAME`        |               |                 |       |  | + |
| `$*`               |               |                 |       |  | + |
| `$-a`              |               |                 |       |  | + |
| `$-l`              |               |                 |       |  | + |
| `$-p`              |               |                 |       |  | + |
| `$$`               |               |                 |       |  | + |
| `$-i`              |               |                 |       |  | + |
| `$PROGRAM_NAME`    |  `$0`         |                 |       |  | + |
| `$?`               |               |                 |       |  | + |

 -->


| Name               | Identical    | Scope  | Read Type          | Write Type      | Initial Value                                | Notes |
|--------------------|--------------|--------|--------------------|-----------------|-----------------------------------------------|-------|
| `$VERBOSE`         | `$-v`, `$-w` | ractor | `bool?`            | `any`           |  `false` (unless `-v`/`-w`/`-W` arg supplied) | Can be assigned any value, but uses truthiness |
| `$-W`              |              | ractor | `(0 \| 1 \| 2)`    | read-only       |  `1` (unless `-v`/`-w`/`-W` supplied)         | Returns `2`, `1`, `0` for `$-v` value of `true`/`false`/`nil`, respectively |
| `$DEBUG`           | `$-d`        | ractor | `any`              | `any`           |  `false` (unless `-d`)                        | |
| `$=`               |              | global | `false`            | `any` (W)       |  `false`                                      | used to be used for case-insensitive string + regex comparsions, now always `false`. |
| `$_`               |              | local  |                    |                 |                                               |       | <!--  `any`           | `nil` | "faux-global" (same scope as local variable) | | -->
| `$~`               |              | local  | `MatchData?`       | `MatchData?`    |  `nil`                                        | Same as `Regexp.last_match` |
| `$&`               |              | local  | `String?`          | read-only       |  `nil`                                        | Same as `$~[0]` |
| ``$` ``            |              | local  | `String?`          | read-only       |  `nil`                                        | Same as `$~.pre_match` |
| `$'`               |              | local  | `String?`          | read-only       |  `nil`                                        | Same as `$~.post_match` |
| `$+`               |              | local  | `String?`          | read-only       |  `nil`                                        | Same as `$~[-1]` |
| `$1`-`$<max>`      |              | local  | `String?`          | read-only       |  `nil`                                        | Same as `$~[N]` |
| `$<max+1>`-..      |              | local  | `nil` (W)          | read-only       |  `nil`                                        | (max size is arch-dependent, usually `1073741823` though) |
| `$LOAD_PATH`       | `$:`, `$-I`  | global |                    | read-only       |                                               | `$LOAD_PATH` amd `$-I` are actual aliases of `$:` |
| `$LOADED_FEATURES` | `$"`         | global |                    | read-only       |                                               |       |
| `$stdin`           |              | ractor |                    |                 |                                               |       |
| `$stdout`          | `$>`         | ractor |                    |                 |                                               |       |
| `$stderr`          |              | ractor |                    |                 |                                               |       |
| `$<`               |              | global |                    |                 |                                               | Only usage of C `rb_define_readonly_variable` lol |
| `$!`               |              | ractor |                    | read-only       |                                               |       |
| `$@`               |              | ractor | `String \| Array[String] \| Array[Thread::Backtrace::Location]` | `any`[^1]       |                                             |       |
| `$.`               |              | global |                    |                 |                                               |       |
| `$FILENAME`        |              | global |                    | read-only       |                                               |       |
| `$*`               |              | global |                    | read-only       |                                               |       |
| `$-a`              |              | ractor | `bool`             | read-only       |  `false` (unless `-a`)                        |       |
| `$-l`              |              | ractor | `bool`             | read-only       |  `false` (unless `-l`)                        |       |
| `$-p`              |              | ractor | `bool`             | read-only       |  `false` (unless `-p`)                        |       |
| `$$`               |              | ractor | `Integer`          | read-only       |  varies                                       |       |
| `$-i`              |              | ractor | `String?` (frozen) | `str \| false?` |  `nil` (unless `-i`)                          | ractor-local, unlike other ARGV ones? bug?; must be c-string result if `str`       |
| `$PROGRAM_NAME`    | `$0`         | ractor | `String` (frozen)  | `string`        |  varies                                       |       |
| `$?`               |              | ractor | `Process::Status?` | read-only       |  `nil`                                        |       |
| `$/`               | `$-0`        |        |                    |                 |                                               |       |
| `$\`               |              |        |                    |                 |                                               |       |
| `$,`               |              |        |                    |                 |                                               |       |
| `$;`               | `$-F`        |        |                    |                 |                                               |       |
| `$F`               |              | global |                    |                 |  (undefined)                                  | Only assigned with `-a` |

[^1]: While technically `any`, all builtin exceptions require a type of `String | Array[String] | Array[Thread::Backtrace::Location]`. (Assigning to and reading from `$@`
is done via by calling the `#set_backtrace(bt)` and `#backtrace()` methods on whatever `$!` is, which means it can be overwritten by end-users; thus,
Assigning to `$@`
actually calls the method `set_backtrace` on whatever `$!` currently is, which can be overwritten by end-users.  `$@` is accessed, )
