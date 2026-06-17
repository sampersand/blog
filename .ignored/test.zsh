#!/bin/zsh
# disable set
# setopt cshjunkieloops
function set_fn {
	local ___set_arg__
	while (( $# )) {
		__set_arg__=$1; shift
		if [[ $1 != = ]] {
			: ${(P)__set_arg__::=}
			continue
		}
		shift

		if [[ $1 != '(' ]] {
			: ${(P)__set_arg__::=$1}
			shift
			continue
		}

		: ${(AP)__set_arg__::=}
		shift
		while [[ ${1-} != ')' ]] {
			if (( $# == 0 )) { print missing closing \) >&2; return 1 }
			builtin set -A "$__set_arg__" "${(AP)__set_arg__}" "$1"
			shift
		}
		shift
	}
}

alias set='noglob set_fn' # TODO: don't count parens in that one line?
alias endif=fi

setopt cshjunkieloops
set arg = ( 3 4 5 )
emulate csh
print $(( [#16_4] 65536 ** 2 ))
exit
setopt SH_GLOB
set x = 3
# \set -xv
alias -g '(=(('
alias -g ')=))'
\set -xv
# alias if='if noglob'
if let '$x < 10'; then
	echo $x
endif

