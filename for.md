- USes `Array.try_convert` for top-level stuff
- Explicitly allows `END { ... }` inside it

```ruby
for CONSTANT in Array true do break end

def capture_stdout
  class << out = -''; alias write concat end

  for $> in Array[out, $>] do
    String.try_convert $> and yield
  end

  out
end

p capture_stdout { puts "oh hi" }
```
