# LRU cache

[![CI Status](https://github.com/Nicolab/crystal-lru-cache/workflows/CI/badge.svg?branch=master)](https://github.com/Nicolab/crystal-lru-cache/actions) [![GitHub release](https://img.shields.io/github/release/Nicolab/crystal-lru-cache.svg)](https://github.com/Nicolab/crystal-lru-cache/releases) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://nicolab.github.io/crystal-lru-cache/)

:gem: Key/value LRU cache that supports lifecycle, global size limit and expiration time.

> LRU: Least Recently Used

_lru-cache_ supports lifecycle, a global item size limit and an expiration time can be set for each item independently.

If a *max_size* is defined, the LRU cache can only contain *max_size* items.
Beyond *max_size*, items are deleted from the oldest to the most recently used.

A caching system is a vital part, it must be simple to use, reliable and efficient. _lru-cache_ is battle tested 👌

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
   dependencies:
     lru-cache:
       github: nicolab/crystal-lru-cache
       version: ~> 1.0.1 # Check the latest version!
```

2. Run `shards install`

## Usage

```crystal
require "lru-cache"

cache = LRUCache(String, String).new(max_size: 10_000)

cache.set("hello", "Hello Crystal!")
puts cache.get("hello") # => "Hello Crystal!"

# or
puts cache["hello"] # => "Hello Crystal!"

puts cache.has?("hello") # => true

# Time limit
cache.set("hello", "Hello Crystal!", Time.utc + 1.hour)

puts cache.expire_at "hello" # => Time.utc + 1.hour

# Deletes "hello" item
cache.delete "hello"

# Empties the cache
cache.clear
```

Lifecycle:

```crystal
require "lru-cache"

class Cache(K, V) < LRUCache(K, V)
  # Optional lifecycle method to be executed after setting an item (`add!` and `set`).
  private def after_set(key : K, item : Tuple(V, Time?))
    puts "after_set: #{key}"
    pp item
  end

  # Optional lifecycle method to be executed after deleting an item (`delete`).
  private def after_delete(key : K, item : Tuple(V, Time?)?)
    puts "after_delete: #{key}"
    pp item
  end

  # Optional lifecycle method to be executed after clearing all the cache (`clear`).
  private def after_clear
    puts "after_clear"
  end
end

cache = Cache(String, String).new(max_size: 10_000)

cache.set("hello", "Hello Crystal!")
cache.set("foo", "bar")
cache.delete("foo")
cache.clear
```

📘 [API doc](https://nicolab.github.io/crystal-lru-cache/)

## Development

Install dev dependencies:

```sh
shards install
```

Run:

```sh
crystal spec
```

Clean before commit:

```sh
crystal tool format
./bin/ameba
```

## Contributing

1. Fork it (https://github.com/Nicolab/crystal-lru-cache/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## LICENSE

[MIT](https://github.com/Nicolab/crystal-lru-cache/blob/master/LICENSE) (c) 2021, Nicolas Talle.

## Author

| [![Nicolas Tallefourtane - Nicolab.net](https://www.gravatar.com/avatar/d7dd0f4769f3aa48a3ecb308f0b457fc?s=64)](https://github.com/sponsors/Nicolab) |
|---|
| [Nicolas Talle](https://github.com/sponsors/Nicolab) |
| [![Make a donation via Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PGRH4ZXP36GUC) |
