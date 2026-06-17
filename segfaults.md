Here's some segafults I've found in ruby:
```sh
#ruby 3.5.0:
ruby --disable=gems -rfileutils -s -e 'p $DEBUG' -- -DEBUG=x

#ruby 3.5.0:
ruby -e 'case when (!false || "a").."b" then end'

#ruby 3.5.0:
ruby --parser=prism -e 'for * in nil do end'
```

This one is incredibly gnarly... Every single one of these methods is required
```ruby
class X
  def coerce(_) = [self, self]
  def abs       = self
  def ceil      = self
  def -(_)      = self
  def +(_)      = 1
  def *(_)      = 1
  def <(_)      = true
  def div(_)    = self
end

3.4.rationalize(X.new).abs * 3
```
