# This file is part of "lru-cache" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-lru-cache
# ------------------------------------------------------------------------------

require "./spec_helper"

describe "Lifecycle" do
  describe "#after_set" do
    it "is triggered by #set" do
      c = LifecycleCache.new
      c.count_after_set.should eq 0
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      # set value
      c.set :a, "a"
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :a, "updated"
      c.count_after_set.should eq 2
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :b, "b", Time.utc
      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :b, "updated", Time.utc + 5.milliseconds
      c.count_after_set.should eq 4
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      # set item
      c.set :c, {"a", nil}
      c.count_after_set.should eq 5
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :c, {"updated", nil}
      c.count_after_set.should eq 6
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :d, {"d", Time.utc}
      c.count_after_set.should eq 7
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.set :d, {"updated", Time.utc + 5.milliseconds}
      c.count_after_set.should eq 8
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c[:b] = "b"
      c.count_after_set.should eq 9
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c[:b] = "updated"
      c.count_after_set.should eq 10
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c[:c] = {"c", nil}
      c.count_after_set.should eq 11
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c[:c] = {"updated", Time.utc}
      c.count_after_set.should eq 12
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0
    end

    it "is triggered by #add!" do
      c = LifecycleCache.new
      c.count_after_set.should eq 0
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      # add value
      c.add! :a, "a"
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      expect_raises(KeyError) do
        c.add! :a, "updated"
      end

      c.count_after_set.should eq 1
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.add! :b, "b", Time.utc
      c.count_after_set.should eq 2
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      expect_raises(KeyError) do
        c.add! :b, "updated", Time.utc + 5.milliseconds
      end

      c.count_after_set.should eq 2
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      # add item
      c.add! :c, {"a", nil}
      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      expect_raises(KeyError) do
        c.add! :c, {"updated", nil}
      end

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.add! :d, {"d", Time.utc}
      c.count_after_set.should eq 4
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      expect_raises(KeyError) do
        c.add! :d, {"updated", Time.utc + 5.milliseconds}
      end

      c.count_after_set.should eq 4
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0
    end
  end

  describe "#after_delete" do
    it "is triggered by #delete" do
      c = LifecycleCache.new
      c.set :a, "a"
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.delete(:a)
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0
      c.has?(:a).should be_false

      # With expiration
      c.set :a, "a", Time.utc + 5.milliseconds
      c.count_after_set.should eq 2
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0

      c.has?(:a).should be_true
      c.delete(:a)
      c.count_after_set.should eq 2
      c.count_after_delete.should eq 2
      c.count_after_clear.should eq 0
      c.has?(:a).should be_false

      c.set :a, "a", Time.utc + 5.milliseconds
      c.has?(:a).should be_true
      sleep 5.milliseconds
      c.has?(:a).should be_false
      c.count_after_set.should eq 3
      c.count_after_delete.should eq 3
      c.count_after_clear.should eq 0

      # non-existent
      c.delete(:none)
      c.count_after_set.should eq 3
      c.count_after_delete.should eq 3
      c.count_after_clear.should eq 0

      # LRU order
      c = LifecycleCache.new max_size: 2
      c.set :a, "a"
      c.set :b, "b"
      c.keys.should eq([:a, :b])
      c.set :c, "c"
      c.keys.should eq([:b, :c])

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0

      # Return
      c = LifecycleCache.new
      c.set :a, "a"
      c.delete(:a).should eq({"a", nil})
      c.delete(:none).should eq nil

      c.count_after_set.should eq 1
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0
    end

    it "should be triggered when an item expire" do
      c = LifecycleCache.new
      c.set :a, "a", Time.utc + 5.milliseconds
      c.has?(:a).should be_true
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      sleep 5.milliseconds
      c.has?(:a).should be_false
      c.count_after_set.should eq 1
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0
    end

    it "should be triggered when max_size is reached" do
      c = LifecycleCache.new max_size: 2
      c.set :a, "a"
      c.set :b, "b"
      c.set :c, "c"

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 1
      c.count_after_clear.should eq 0
      c.keys.should eq([:b, :c])
    end
  end

  describe "#after_clear" do
    it "is triggered by #clear" do
      c = LifecycleCache.new

      # With items
      c.set :a, "a"
      c.set :b, "b", Time.utc + 5.milliseconds
      c.set :c, "c"

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 0

      c.clear

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 1

      # Without item
      c.size.should eq 0
      c.clear

      c.count_after_set.should eq 3
      c.count_after_delete.should eq 0
      c.count_after_clear.should eq 2
    end
  end

  it "triggers" do
    c = LifecycleCache.new
    c.set(:a, "a")
    c[:a]
    c[:a]?
    c[:b]?
    c[:a] = {"a", nil}
    c[:a] = "a"
    c[:b] = "a"
    c.max_size
    c.size
    c.has?(:a)
    c.has?(:b)
    c.get(:b)
    c.get!(:a)
    c.set(:b, "b")
    c.set(:a, {"a", nil})
    c.set(:a, {"b", nil})
    c.add!(:uniq1, "u1")
    c.add!(:uniq2, {"u2", nil})
    c.delete(:b)
    c.delete(:uniq2)
    c.expire_at!(:uniq1)
    c.keys
    c.items
    c.clear
    c.set(:a, "a")
    c.touch(:a)

    c.count_after_set.should eq 10
    c.count_after_delete.should eq 2
    c.count_after_clear.should eq 1
  end
end
