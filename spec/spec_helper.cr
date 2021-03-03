# This file is part of "lru-cache" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-lru-cache
# ------------------------------------------------------------------------------

require "spec"
require "../src/lru-cache"

alias Cache = LRUCache(Symbol, String)
alias LifecycleCache = LifecycleLRUCache(Symbol, String)

# LRU cache with hooks.
class LifecycleLRUCache(K, V) < LRUCache(K, V)
  getter count_after_set : Int32 = 0
  getter count_after_delete : Int32 = 0
  getter count_after_clear : Int32 = 0

  # Lifecycle method to be executed after setting an item (`add!` and `set`).
  private def after_set(key : K, item : Tuple(V, Time?))
    @count_after_set += 1
  end

  # Lifecycle method to be executed after deleting an item (`delete`, expiration).
  private def after_delete(key : K, item : Tuple(V, Time?)?)
    @count_after_delete += 1
  end

  # Lifecycle method to be executed after clearing all the cache (`clear`).
  private def after_clear
    @count_after_clear += 1
  end
end
