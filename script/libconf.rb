#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Recursive hash array of @generation: each Hash is associated with Domain,Group,Item;
  # Structure: Command[cfg]
  #         -> Domain[cfg,command_cfg]
  #         -> Group[cfg,domain_cfg,command_cfg]
  #         -> Item[cfg,group_cfg,domain_cfg,command_cfg]...
  # Usage:[]=/ add to current Hash which will overwrite(hide) upper level Hash;
  # Usage:[]/  get val from current Hash otherwise from upper generation of Hash;
  class Config < Hashx
    attr_reader :generation
    alias :this_keys :keys
    alias :this_key? :key?
    def initialize(cfg = nil, obj = self)
      super()
      @generation = [self]
      self[:obj] = obj
      case cfg
      when Config
        join_in(cfg)
      when Hash
        update(cfg)
      end
    end

    def gen(obj)
      Config.new(self, obj)
    end

    def join_in(cfg)
      @generation.concat(cfg.generation)
      self
    end

    def key?(id)
      @generation.any? { |h| h.this_key?(id) }
    end

    def keys
      @generation.map { |h| h.this_keys }.flatten.uniq
    end

    def to_hash
      hash = Hashx.new
      @generation.reverse.each { |h| hash.update h }
      hash
    end

    # If content is Array, merge generations
    def [](id)
      @generation.each{|gen|
        return gen.fetch(id) if gen.this_key?(id)
      }
      nil
    end

    # Check key if it is correct type. Used for argument validation.
    def check(name, type)
      sv_err("No such key in Config [#{name}]") unless self[name]
      sv_err("Type is mismatch for Config key [#{name}]") unless self[name].is_a?(type)
      true
    end

    # Get the object of upper generation in which Config is generated 
    def ancestor(n)
      @generation[n][:obj]
    end

    # Show all contents of all generation
    def path(key = nil)
      i = 0
      str = ''
      @generation.each{|h|
        str = "  [#{i}]{" + h.map{|k, v|
          next if key and k != key
          case v
          when Hash, Proc, CmdProc
            val = v.class
          when Array
            val = '[' + v.map{|e|
              case e
              when Enumerable
                e.class
              else
                e.inspect
              end
            }.join(',') + "](#{v.object_id})"
          else
            val = v.inspect
          end
          k.inspect.to_s + '=>' + val.to_s
        }.compact.join(', ') + '} (' + h.object_id.to_s + ")\n" + str
        i += 1
      }
      "******[Config]******(#{object_id})\n#{str}************\n"
    end

    # Show list of all key,val which will be taken with [] access
    def list
      i = 0
      db = {}
      @generation.each{|h|
        h.each{|key, val|
          db[key] = [i, val] unless db.key?(key)
        }
        i += 1
      }
      "******[Config]******(#{object_id})\n" + db.map{|key, ary|
        case v = ary[1]
        when String, Numeric, Enumerable
          val = v.inspect
        when Proc
          val = v.class
        else
          val = v
        end
        "  #{key} (#{ary[0]}) = #{val}"
      }.reverse.join("\n") + "\n************\n"
    end
  end
end
