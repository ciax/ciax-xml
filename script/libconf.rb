#!/usr/bin/ruby
module CIAX
  # Hash array of @ary: each Hash is associated with Domain,Group,Item;
  # Usage:[]=/ add to current Hash which will override(hide) upper level Hash;
  # Usage:[]/  get val from current Hash otherwise from upper level of Hash;
  class Config < Hash
    attr_reader :ary
    alias :_org_keys :keys
    alias :_org_key? :key?
    def initialize(hash=nil)
      @ary=[self]
      case hash
      when Config
        @ary+=hash.ary
      when Hash
        update hash
      else
        self[:index]={}
      end
    end

    def key?(id)
      @ary.any?{|h| h._org_key?(id)}
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
      @ary.each{|h|
        return h.fetch(id) if h._org_key?(id)
      }
      nil
    end
  end
end
