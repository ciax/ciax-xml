#!/usr/bin/ruby
module CIAX
  # Recursive hash array of @generation: each Hash is associated with Domain,Group,Item;
  # Structure: Command[cfg]
  #         -> Domain[cfg,command_cfg]
  #         -> Group[cfg,domain_cfg,command_cfg]
  #         -> Item[cfg,group_cfg,domain_cfg,command_cfg]...
  # Usage:[]=/ add to current Hash which will override(hide) upper level Hash;
  # Usage:[]/  get val from current Hash otherwise from upper generation of Hash;
  class Config < Hashx
    attr_reader :generation,:layers
    def initialize(name,cfg=nil)
      super()
      @generation=[self]
      @layers={}
      self[:level]=name
      case cfg
      when Config
        override(cfg)
      when Hash
        update(cfg)
      end
    end

    def override(cfg)
      @layers=type?(cfg,Config).layers
      @generation.concat(cfg.generation)
      self
    end

    def all_key?(id)
      @generation.any?{|h| h.key?(id)}
    end

    def all_keys
      @generation.map{|h| h.keys}.flatten.uniq
    end

    def to_hash
      hash=Hashx.new
      @generation.reverse.each{|h| hash.update h}
      hash
    end

    def [](id)
      @generation.each{|h|
        return h.fetch(id) if h.key?(id)
      }
      nil
    end

    def level(id)
      i=0
      @generation.each{|h|
        return i if h.key?(id)
        i+=1
      }
    end

    def path
      "******[\n"+@generation.map{|h|
        '{'+h.map{|k,v|
          case v
          when String,Numeric
            val=v.inspect
          else
            val=v.class
          end
          k.inspect.to_s+'=>'+val.to_s
        }.join(', ')+'} ('+h.object_id.to_s+')'
      }.join("\n")+"\n]******(#{object_id})\n"
    end
  end
end
