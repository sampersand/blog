Here's some segafults I've found in ruby:
```sh
#ruby 3.5.0:
ruby --disable=gems -rfileutils -s -e 'p $DEBUG' -- o-DEBUG=x

#ruby 3.5.0:
ruby -e 'case when (!false || "a").."b" then end'

#ruby 3.5.0:
ruby --parser=prism -e 'for * in nil do end'
```
