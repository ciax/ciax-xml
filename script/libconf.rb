#!/usr/bin/ruby
module CIAX
  # Hash array of @ary: each Hash is associated with Domain,Group,Item;
  # Usage:[]=/ add to current Hash which will override(hide) upper level Hash;
  # Usage:[]/  get val from current Hash otherwise from upper level of Hash;
  class Config < Hash
    attr_reader :ary
    alias :_org_keys :keys
    def initialize(hash=nil)
      @ary=[self]
      case hash
      when Config
        @ary+=hash.ary
      when Hash
        update hash
      end
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
