Here's some segafults I've found in ruby:
```sh
ruby --disable=gems -rfileutils -s <(echo 'p $DEBUG') -DEBUG=x
ruby -e 'case when (!false || "a").."b" then end'
```
