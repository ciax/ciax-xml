#!/usr/bin/ruby
module CIAX
  # Array of WriteShare(Hash): each Hash is associated with Domain,Group,Item;
  # Usage:Setting/ provide @set(WriteShare) and add to ReadShare at each Level, value setting should be done to the @set;
  # Usage:Getting/ simply get form ReadShare, not from @set;
  class Config < Hash
    attr_reader :ary
    alias :_org_keys :keys
    def initialize(hash=nil)
      @ary=[self]
      @ary+=hash.ary if hash.is_a? Config
    end

    def keys
      @ary.map{|h| h._org_keys}.flatten.uniq
    end

    def to_hash
      hash={}
      @ary.reverse.each{|h| hash.update h}
      hash
    end

    def [](id)
      @ary.each{|lv|
        return lv.fetch(id) if lv.key?(id)
      }
      nil
    end
  end
end
