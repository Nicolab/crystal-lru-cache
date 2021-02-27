# This file is part of "lru-cache" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-lru-cache
# ------------------------------------------------------------------------------

require "./spec_helper"

describe LRUCache do
  it "#max_size" do
    c = Cache.new
    c.max_size.should be_nil

    c = Cache.new max_size: 2
    c.max_size.should eq 2
    c.set(:a, "a")
    c.set(:b, "b")
    c.set(:c, "c")
    c.has?(:a).should be_false
    c.keys.should eq [:b, :c]
    c.get!(:c).should eq "c"
    c.get!(:b).should eq "b"
    c.max_size.should eq 2

    expect_raises(KeyError, "Missing hash key: :a") do
      c.get!(:a)
    end

    # With expiration
    c.set(:ephemeral, "Goodbye", Time.utc + 5.milliseconds)
    c.has?(:ephemeral).should be_true
    # last used (:b, then :ephemeral)
    c.keys.should eq [:b, :ephemeral]
    sleep 5.milliseconds
    c.has?(:ephemeral).should be_false
    c.keys.should eq [:b]

    c = Cache.new
    c.max_size.should be_nil
    c.size.should eq 0
  end

  it "#size" do
    c = Cache.new
    c.size.should eq 0

    c.set(:a, "a")
    c.size.should eq 1

    c.set(:b, "b")
    c.size.should eq 2

    c.set(:b, "c")
    c.size.should eq 2

    c.set(:c, "c")
    c.size.should eq 3

    c.clear
    c.size.should eq 0
  end

  it "#has?" do
    c = Cache.new
    c.set(:a, "a")
    c.has?(:a).should be_true
    c.has?(:b).should be_false
    c.delete(:a)
    c.has?(:a).should be_false

    # does not change the order
    c.set(:a, "a")
    c.set(:b, "b")
    c.keys.should eq [:a, :b]
    c.has?(:a).should be_true
    c.keys.should eq [:a, :b]

    # With expiration
    c.set(:ephemeral, "Goodbye", Time.utc + 5.milliseconds)
    c.has?(:ephemeral).should be_true
    c.has?(:b).should be_true
    c.keys.should eq [:a, :b, :ephemeral]
    sleep 5.milliseconds
    c.has?(:ephemeral).should be_false
    c.keys.should eq [:a, :b]
  end

  it "#get" do
    c = Cache.new

    c.set(:a, "a")
    c.get(:a).should be_a(String)
    c.get(:none).should eq nil

    # With expiration
    time = Time.utc + 5.milliseconds
    c.set(:a, "a", time)
    c.get(:a).should eq "a"
    sleep 5.milliseconds
    c.get(:a).should eq nil
  end

  it "#get!" do
    c = Cache.new

    c.set(:a, "a")
    c.get!(:a).should be_a(String)

    expect_raises(KeyError, "Missing hash key: :none") do
      c.get!(:none)
    end

    # With expiration
    time = Time.utc + 5.milliseconds
    c.set(:a, "a", time)
    c.get!(:a).should eq "a"
    sleep 5.milliseconds
    expect_raises(KeyError, "Missing hash key: :a") do
      c.get!(:a)
    end
  end

  it "#set value" do
    c = Cache.new
    c.set(:a, "a")
    c.has?(:a).should be_true
    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    # Update with expiration
    time = Time.utc + 5.milliseconds
    c.set(:a, "a", time)
    c.has?(:a).should be_true
    c.get!(:a).should eq "a"
    c.expire_at!(:a).should eq time
    sleep 5.milliseconds
    c.has?(:a).should be_false
    c.get(:a).should eq nil

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end
  end

  it "#set item" do
    c = Cache.new
    c.set(:a, {"a", nil})
    c.has?(:a).should be_true
    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    # Update with expiration
    time = Time.utc + 5.milliseconds
    c.set(:a, {"a", time})
    c.has?(:a).should be_true
    c.expire_at!(:a).should eq time
    sleep 5.milliseconds
    c.has?(:a).should be_false
    c.get(:a).should eq nil

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end
  end

  it "#add! value" do
    c = Cache.new
    c.add!(:a, "a")
    c.add!(:b, "b")
    c.has?(:a).should be_true
    c.has?(:b).should be_true
    c.get!(:a).should eq "a"
    c.get!(:b).should eq "b"
    c.expire_at!(:a).should be_nil
    c.expire_at!(:b).should be_nil

    # Try to update
    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, "updated")
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, "updated", Time.utc + 10.seconds)
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    c.get!(:b).should eq "b"
    c.expire_at!(:b).should be_nil

    # With expiration
    c = Cache.new
    time = Time.utc + 5.milliseconds
    c.add!(:a, "a", time)
    c.add!(:b, "b", time + 1.nanosecond)
    c.has?(:a).should be_true
    c.has?(:b).should be_true
    c.get!(:a).should eq "a"
    c.get!(:b).should eq "b"
    c.expire_at!(:a).should eq time
    c.expire_at!(:b).should eq(time + 1.nanosecond)

    # Try to update
    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, "updated")
    end

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:b, "updated")
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should eq time

    c.get!(:b).should eq "b"
    c.expire_at!(:b).should eq(time + 1.nanosecond)

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, "updated", Time.utc + 10.seconds)
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should eq time

    sleep 5.milliseconds
    c.has?(:a).should be_false
    c.get(:a).should eq nil

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end

    c.add!(:a, "new")
    c.has?(:a).should be_true
    c.get!(:a).should eq "new"
    c.expire_at!(:a).should eq nil
  end

  it "#add! item" do
    c = Cache.new
    c.add!(:a, {"a", nil})
    c.add!(:b, {"b", nil})
    c.has?(:a).should be_true
    c.has?(:b).should be_true
    c.get!(:a).should eq "a"
    c.get!(:b).should eq "b"
    c.expire_at!(:a).should be_nil
    c.expire_at!(:b).should be_nil

    # Try to update
    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, {"updated", nil})
    end

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:b, {"updated", nil})
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, {"updated", Time.utc + 10.seconds})
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should be_nil

    c.get!(:b).should eq "b"
    c.expire_at!(:b).should be_nil

    # With expiration
    c = Cache.new
    time = Time.utc + 5.milliseconds
    c.add!(:a, {"a", time})
    c.add!(:b, {"b", time + 1.nanosecond})
    c.has?(:a).should be_true
    c.has?(:b).should be_true
    c.get!(:a).should eq "a"
    c.get!(:b).should eq "b"
    c.expire_at!(:a).should eq time
    c.expire_at!(:b).should eq(time + 1.nanosecond)

    # Try to update
    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, {"updated", nil})
    end

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:b, {"updated", nil})
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should eq time

    c.get!(:b).should eq "b"
    c.expire_at!(:b).should eq(time + 1.nanosecond)

    expect_raises(KeyError, "#add! - Cannot add an item on an existing key.") do
      c.add!(:a, {"updated", Time.utc + 10.seconds})
    end

    c.get!(:a).should eq "a"
    c.expire_at!(:a).should eq time

    sleep 5.milliseconds
    c.has?(:a).should be_false
    c.get(:a).should eq nil

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end

    c.add!(:a, {"new", nil})
    c.has?(:a).should be_true
    c.get!(:a).should eq "new"
    c.expire_at!(:a).should eq nil
  end

  it "#delete" do
    c = Cache.new
    c.set(:a, "a")
    c.has?(:a).should be_true
    value, expire_at = c.delete(:a).not_nil!
    c.has?(:a).should be_false
    value.should eq "a"
    expire_at.should eq nil
    c.delete(:a).should eq nil

    # With expiration
    time = Time.utc + 10.seconds
    c.set(:a, "a", time)
    c.has?(:a).should be_true
    value, expire_at = c.delete(:a).not_nil!
    c.has?(:a).should be_false
    value.should eq "a"
    expire_at.should eq time
    c.delete(:a).should eq nil
  end

  it "#expire_at!" do
    c = Cache.new
    time = Time.utc + 10.seconds
    c.set(:a, "a", time)
    c.set(:b, "b")
    c.expire_at!(:a).should eq time
    c.expire_at!(:b).should eq nil

    expect_raises(KeyError, "Missing hash key: :c") do
      c.expire_at!(:c)
    end

    c.delete(:a)

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end

    c.set(:a, "a", Time.utc)

    expect_raises(KeyError, "Missing hash key: :a") do
      c.expire_at!(:a)
    end

    c.set(:d, "d", Time.utc)

    expect_raises(KeyError, "Missing hash key: :d") do
      c.expire_at!(:d)
    end
  end

  it "#keys" do
    c = Cache.new(max_size: 3)
    c.set(:a, "a", Time.utc + 10.seconds)
    c.set(:b, "b")
    c.set(:c, "c")
    c.keys.should eq [:a, :b, :c]
    c.set(:d, "d")
    c.keys.should eq [:b, :c, :d]
  end

  it "#items" do
    c = Cache.new
    c.items.should be_a Hash(Symbol, Tuple(String, Time?))
    c.set(:a, "a")
    c.items[:a].should eq({"a", nil})

    time = Time.utc + 10.seconds
    c.set(:b, "b", time)
    c.items[:b].should eq({"b", time})
    c.items.should eq({:a => {"a", nil}, :b => {"b", time}})
  end

  it "#clear" do
    c = Cache.new
    c.set(:a, "a", Time.utc + 10.seconds)
    c.set(:b, "b")
    c.size.should eq 2
    old = c.clear
    old.should be_a LRUCache(Symbol, String)
    old.size.should eq 0
    c.size.should eq 0
    c.should eq old

    # With items limit
    c = Cache.new(max_size: 3)
    c.set(:a, "a", Time.utc + 10.seconds)
    c.set(:b, "b")
    c.size.should eq 2
    old = c.clear
    old.should be_a LRUCache(Symbol, String)
    old.size.should eq 0
    c.size.should eq 0
    c.should eq old
  end

  it "#touch and LRU behaviour" do
    c = Cache.new max_size: 3
    c.max_size.should eq 3
    c.set(:a, "a")
    c.set(:b, "b")
    c.keys.should eq [:a, :b]
    c.items.first_key.should eq :a
    c.items.last_key.should eq :b

    # goes up :a in the stack
    c.touch(:a).should be_true
    c.keys.should eq [:b, :a]
    c.items.first_key.should eq :b
    c.items.last_key.should eq :a

    c.set(:c, "c")
    c.keys.should eq [:b, :a, :c]

    c.touch(:b).should be_true
    c.keys.should eq [:a, :c, :b]
    c.items.first_key.should eq :a
    c.items.last_key.should eq :b

    c.set(:d, "d")
    c.keys.should eq [:c, :b, :d]
    c.items.first_key.should eq :c
    c.items.last_key.should eq :d

    # Not touched
    c.has?(:a).should be_false
    c.keys.should eq [:c, :b, :d]
    c.items.first_key.should eq :c
    c.items.last_key.should eq :d

    # Touch the last (should be inchanged)
    c.touch(:d).should be_true
    c.keys.should eq [:c, :b, :d]
    c.items.first_key.should eq :c
    c.items.last_key.should eq :d

    # Touch the middle
    c.touch(:b).should be_true
    c.keys.should eq [:c, :d, :b]
    c.items.first_key.should eq :c
    c.items.last_key.should eq :b

    # Touch the first
    c.touch(:c).should be_true
    c.keys.should eq [:d, :b, :c]
    c.items.first_key.should eq :d
    c.items.last_key.should eq :c

    # With expiration
    c.set(:ephemeral, "Goodbye", Time.utc + 5.milliseconds)
    c.has?(:ephemeral).should be_true

    # first to last used ":d, :b, :c, then :ephemeral",
    # but max_size is 3 items. So:
    c.keys.should eq [:b, :c, :ephemeral]
    c.items.first_key.should eq :b
    c.items.last_key.should eq :ephemeral

    c.touch(:c).should be_true
    c.keys.should eq [:b, :ephemeral, :c]

    c.touch(:ephemeral).should be_true
    c.keys.should eq [:b, :c, :ephemeral]

    # re-touch the same
    c.touch(:ephemeral).should be_true
    c.keys.should eq [:b, :c, :ephemeral]

    sleep 5.milliseconds
    c.has?(:ephemeral).should be_false
    c.keys.should eq [:b, :c]
  end

  describe "shorcut" do
    it "[]" do
      c = Cache.new

      c[:a] = "a"
      c[:a].should be_a(String)

      expect_raises(KeyError, "Missing hash key: :none") do
        c[:none]
      end

      # With expiration
      time = Time.utc + 5.milliseconds
      c[:a] = {"a", time}
      c[:a].should eq "a"
      sleep 5.milliseconds
      expect_raises(KeyError, "Missing hash key: :a") do
        c[:a]
      end
    end

    it "[]?" do
      c = Cache.new

      c[:a] = "a"
      c[:a]?.should be_a(String | Nil)
      c[:none]?.should eq nil

      # With expiration
      time = Time.utc + 5.milliseconds
      c[:a] = {"a", time}
      c[:a]?.should eq "a"
      sleep 5.milliseconds
      c[:a]?.should eq nil
    end

    it "[]= item" do
      c = Cache.new
      c[:a] = {"a", nil}
      c.has?(:a).should be_true
      c[:a].should eq "a"
      c.expire_at!(:a).should be_nil

      # Update with expiration
      time = Time.utc + 5.milliseconds
      c[:a] = {"a", time}
      c.has?(:a).should be_true
      c.expire_at!(:a).should eq time
      sleep 5.milliseconds
      c.has?(:a).should be_false
      c[:a]?.should eq nil

      expect_raises(KeyError, "Missing hash key: :a") do
        c.expire_at!(:a)
      end
    end

    it "[]= value" do
      c = Cache.new
      c[:a] = "a"
      c.has?(:a).should be_true
      c[:a].should eq "a"
      c.expire_at!(:a).should be_nil
    end
  end

  # Not too violent for small CI servers
  context "Benchmark" do
    it "should be fast" do
      c = LRUCache(String, String).new max_size: 1000
      start = Time.monotonic

      2000.times do |i|
        k = "k#{i}"
        v = "v #{i}"
        c.add!(k, v)
        c.has?(k).should be_true
        c.get!(k).should eq v

        c.set(k, v, Time.utc + 1.nanoseconds)
        c.size.should be <= 1000
      end

      c.max_size.should eq 1000
      c.size.should eq 1000

      # delete 1000 existing items and 1000 non-existent (removed) items
      2000.times do |i|
        c.delete("k#{i}")
      end

      elapsed_total = Time.monotonic - start

      # NOTE: test expectations (`.should`) consumes a large part of the execution time.
      # 4000 iterations = 25 milliseconds in my computer. But it is preferable
      # to allow a fairly large time margin for small CI servers.
      elapsed_total.should be < 150.milliseconds

      c = LifecycleLRUCache(Symbol, String).new max_size: 2
      start = Time.monotonic
      c.add! :a, "a", Time.utc + 5.milliseconds
      c.add! :b, "b"
      c.add! :c, "c"
      c.add! :d, "d", Time.utc
      c.get!(:c)
      c.get(:b)
      c.has?(:a)
      c.delete(:b)
      c.clear
      elapsed_total = Time.monotonic - start
      elapsed_total.should be < 1.millisecond
    end
  end
end
