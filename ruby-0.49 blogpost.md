After a friend showed me [ruby 0.49](https://git.ruby-lang.org/ruby.git/refs/tags), I decided to try to get it to work.

# Step 1: Initial compile attempt
I cloned the repo, checked out the old version, and started hacking. I began with the traditional `./configure`, which made the `Makefile`. Then we used `make` and... got a bazillion errors and warnings, preventing anything from working:
```sh
% make
gcc -c -g  -DHAVE_UNISTD_H=1 -DVOID_CLOSEDIR=1 -DGETGROUPS_T=int -DRETSIGTYPE=int -DTM_IN_SYS_TIME=1 -DC_ALLOCA=1 -DSTACK_DIRECTION=0 -DWORDS_BIGENDIAN=1 -I. -I./lib array.c
array.c:24:5: error: implicit declaration of function 'newobj' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
    NEWOBJ(ary, struct RArray);
    ^
./ruby.h:119:45: note: expanded from macro 'NEWOBJ'
#define NEWOBJ(obj,type) type *obj = (type*)newobj(sizeof(type))
                                            ^
array.c:24:5: warning: cast to 'struct RArray *' from smaller integer type 'int' [-Wint-to-pointer-cast]
    NEWOBJ(ary, struct RArray);
    ^~~~~~~~~~~~~~~~~~~~~~~~~~
./ruby.h:119:38: note: expanded from macro 'NEWOBJ'
#define NEWOBJ(obj,type) type *obj = (type*)newobj(sizeof(type))
                                     ^~~~~~~~~~~~~~~~~~~~~~~~~~~
array.c:28:5: error: implicitly declaring library function 'alloca' with type 'void *(unsigned long)' [-Werror,-Wimplicit-function-declaration]
    GC_PRO(ary);
    ^

<snip>

array.c:114:16: warning: cast to 'VALUE *' (aka 'unsigned int *') from smaller integer type 'int' [-Wint-to-pointer-cast]
    ary->ptr = ALLOC_N(VALUE, ARY_DEFAULT_SIZE);
               ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
./ruby.h:243:25: note: expanded from macro 'ALLOC_N'
#define ALLOC_N(type,n) (type*)xmalloc(sizeof(type)*(n))
                        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
array.c:117:12: warning: cast to smaller integer type 'VALUE' (aka 'unsigned int') from 'struct RArray *' [-Wpointer-to-int-cast]
    return (VALUE)ary;
           ^~~~~~~~~~
fatal error: too many errors emitted, stopping now [-ferror-limit=]
13 warnings and 20 errors generated.
make: *** [array.o] Error 1
```

Well, fun. Now what?

# Step 2: Fix the compiler errors.
Ruby 0.49 was written in 1993, which means a lot of the C conventions were wildly different. A quick list of things that were relied on:
- Implicit `int`s for variable types and return values
- Relying on `int`s being 64 bits
- Rely on missing prototypes to have `int`s for all arguments
- Compiler-specific extensions
- Fast-and-loose with some undefined behaviour
among others.

So, let's fix them! I wanted to document all the changes I made, so I added a `__r49_fixes.h` header file with a bunch of macros which can be used to disable changes I made (which would make it identical to the start).

There were still a few warnings left over, but we've ignored them.

Additionally, we added support for 64 bit. This section adds in `__r49_required_change` and `__r49_64bit`.

# Step 3: Running Ruby 0.49!
At this point, we can now run `make` and it successfully compiles Ruby. Let's try running an empty program.
```sh
% ./ruby -e '1'
```
How about something a bit more complex?
```sh
% ./ruby -e 'puts(1)'       
zsh: segmentation fault  ./ruby -e 'puts(1)'
```
Whoops! Looks like we hadn't completely solved everything yet.

Turns out there's a twofold reason for this: `puts` hadn't been added yet in 0.49, and (due to a bug) undefined methods cause segfaults. Let's test this out:
```sh
% ./ruby -e 'print("Hello, world!\n")'  
Hello, world!
% ./ruby -e 'undefined_method()'        
zsh: segmentation fault  ./ruby -e 'undefined_method()'
% 
```

There's a few of these "critical bugs" which makes Ruby 0.49 almost unusable. Others include being unable to use the return value of blocks, and segfaults when attempting using methods, structs, and bignums in invalid type contexts.

These are all fixed via `__r49_critical_bugfix`.

# Step 4: Using Ruby 0.49!
Now that we've gotten those critical bugfixes out of the way, Ruby's now usable. However, as I started using it, I noticed that there were more minor bugs, such as:
- `redo` already existed in the language, but matz missed a single `case` which was required to work
- Aliasing undefined methods would silently pass (and then segfault when it was used)
- Having `()` in an expression context wasn't `nil` but would segfault
- `%` would be incorrectly parsed as a constant sometimes
- `$;` had support but wasn't parsed
- Converting a `Range` of non-ints to a string segfaulted

There's probably more of these lurking around I haven't encountered (especially around `TCPServer`), but these were some of them that I found. (in fact, oen of them is it segfaults if you `retry` out of a protect clause)

All of these are fixed via `__r49_bugfix`

Next up, differences from modern ruby!


