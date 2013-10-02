#!/usr/bin/ruby
module CIAX
  # Recursive hash array of @generation: each Hash is associated with Domain,Group,Item;
  # Structure: Command[cfg]
  #         -> Domain[cfg,command_cfg]
  #         -> Group[cfg,domain_cfg,command_cfg]
  #         -> Item[cfg,group_cfg,domain_cfg,command_cfg]...
  # Usage:[]=/ add to current Hash which will override(hide) upper level Hash;
  # Usage:[]/  get val from current Hash otherwise from upper generation of Hash;
  class Config < Hash
    attr_reader :generation,:index
    def initialize(hash={})
      @generation=[self]
      case hash
      when Config
        @generation+=hash.generation
        @index=hash.index
      else
        @index=hash
      end
    end

    def total_key?(id)
      @generation.any?{|h| h.key?(id)}
    end

    def total_keys
      @generation.map{|h| h.keys}.flatten.uniq
    end

    def to_hash
      hash={}
      @generation.reverse.each{|h| hash.update h}
      hash
    end

    def [](id)
      @generation.each{|h|
        return h.fetch(id) if h.key?(id)
      }
      nil
    end
  end
end
