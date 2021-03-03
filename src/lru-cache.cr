# This file is part of "lru-cache" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-lru-cache
# ------------------------------------------------------------------------------

# LRU cache (Least Recently Used).
# `LRUCache` supports lifecycle, a global item size limit
# and an expiration time can be set for each item.
#
# If a *max_size* is defined, the LRU cache can only contain *max_size* items.
# Beyond *max_size*, items are deleted from the oldest to the most recently used.
class LRUCache(K, V)
  # Creates a new LRUCache instance.
  # If *max_size* is defined, the LRU cache can only contain *max_size* items.
  # Beyond *max_size*, items are deleted from the oldest to the most recently used.
  def initialize(*, @max_size : Int32? = nil)
    @items = {} of K => {V, Time?}
  end

  # Same as `get!(key)`.
  def [](key : K) : V
    get!(key)
  end

  # Same as `get(key)`.
  def []?(key : K) : V?
    get(key)
  end

  # Same as `set!(key, item)`
  def []=(key : K, item : Tuple(V, Time?)) : LRUCache
    set(key, item)
  end

  # Same as `set(key, value)`.
  def []=(key : K, value : V) : LRUCache
    set(key, value)
  end

  # Returns the max items allowed in the cache.
  def max_size : Int32?
    @max_size
  end

  # Returns the cache size (numbers of items in the cache).
  def size : Int32
    @items.size
  end

  # Checks if the cache has an item by its *key*.
  # This method checks the item expiration but does not consider
  # the item to be used (the order in the LRU cache is inchanged).
  def has?(key : K) : Bool
    if @items.has_key?(key)
      return !delete_if_expired!(key)
    end

    false
  end

  # Get a value by its *key*.
  # Returns the item value or `nil`.
  def get(key : K) : V?
    return @items[key][0] if touch(key)
  end

  # If *key* does not exist, this methods raises a *KeyError* exception.
  def get!(key : K) : V
    touch(key)
    @items[key][0]
  end

  # Sets a value in the cache.
  def set(key : K, value : V, expire_at : Time? = nil) : LRUCache
    set(key, {value, expire_at})
  end

  # Sets an item in the cache.
  def set(key : K, item : Tuple(V, Time?)) : LRUCache
    @items.delete(key)

    if _max_size = @max_size
      if @items.size >= _max_size
        while @items.size >= _max_size
          deleted_key, deleted_item = @items.shift
          after_delete(deleted_key, deleted_item)
        end
      end
    end

    @items[key] = item
    after_set(key, item)
    self
  end

  # Adds a value in the cache.
  # If *key* exists, this methods raises a *KeyError* exception.
  def add!(key : K, value : V, expire_at : Time? = nil) : LRUCache
    add!(key, {value, expire_at})
  end

  # Adds an item in the cache.
  # If *key* exists, this methods raises a *KeyError* exception.
  def add!(key : K, item : Tuple(V, Time?)) : LRUCache
    raise KeyError.new("#add! - Cannot add an item on an existing key.") if @items.has_key?(key)
    set(key, item)
  end

  # Deletes an item from the cache.
  # Returns the deleted item or `nil`.
  def delete(key : K) : Tuple(V, Time?)?
    item = @items.delete(key)
    after_delete(key, item) unless item.nil?
    item
  end

  # Returns the expiration time of a *key*.
  def expire_at!(key : K) : Time?
    touch(key)
    @items[key][1]
  end

  # Returns all keys.
  def keys : Array(K)
    @items.keys
  end

  # Returns the `Hash` containing all items.
  # The `Hash` can be handled normally without affecting the behavior of
  # the LRU cache.
  def items : Hash(K, Tuple(V, Time?))
    @items
  end

  # Empties the cache.
  def clear : LRUCache
    @items.clear
    after_clear
    self
  end

  # Given that the LRU cache purge the items least-recently-used,
  # this method touches an item to consider it as recent use.
  # This makes it possible to up an old element.
  # If the item does not exist, nothing happens.
  #
  # Returns `true` if the existing item has been touched,
  # `false` if not (because does not exist).
  def touch(key : K) : Bool
    if @items.has_key?(key) && !delete_if_expired!(key)
      @items[key] = @items.delete(key).not_nil!
      return true
    end

    false
  end

  # Returns `true` if the item has been deleted.
  private def delete_if_expired!(key : K) : Bool
    # If time is not nil and expired
    if expire_at = @items[key][1]
      if expire_at <= Time.utc
        delete(key)
        return true
      end
    end

    false
  end

  # ----------------------------------------------------------------------------
  # Lyfecycle
  # ----------------------------------------------------------------------------

  # Optional lifecycle method.
  # Overwrite this method to execute Crystal code after setting an item (`add!`, `set`).
  private def after_set(key : K, item : Tuple(V, Time?))
  end

  # Optional lifecycle method.
  # Overwrite this method to execute Crystal code after deleting an item (`delete`, expiration).
  private def after_delete(key : K, item : Tuple(V, Time?)?)
  end

  # Optional lifecycle method.
  # Overwrite this method to execute Crystal code after clearing all the cache (`clear`).
  private def after_clear
  end
end
