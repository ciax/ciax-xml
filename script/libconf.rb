#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Recursive hash array of @generation:
  #   each Hash is associated with Domain,Group,Item;
  # Structure: Command[cfg]
  #         -> Domain[cfg,command_cfg]
  #         -> Group[cfg,domain_cfg,command_cfg]
  #         -> Item[cfg,group_cfg,domain_cfg,command_cfg]...
  # Usage:[]=
  #   add to current Hash which will overwrite(hide) upper level Hash;
  # Usage:[]
  #   get val from current Hash otherwise from upper generation of Hash;
  class Config < Hashx
    attr_reader :generation
    alias this_keys keys
    alias this_key? key?
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
      @generation.map(&:this_keys).flatten.uniq
    end

    def to_hash
      hash = Hashx.new
      @generation.reverse_each { |h| hash.update h }
      hash
    end

    # If content is Array, merge generations
    def [](id)
      @generation.each do |gen|
        return gen.fetch(id) if gen.this_key?(id)
      end
      nil
    end

    # Check key if it is correct type. Used for argument validation.
    def check_type(key, type)
      sv_err("No such key in Config [#{key}]") unless self[key]
      sv_err("Confi Key Type is mismatch [#{key}]") unless self[key].is_a?(type)
      true
    end

    # Check key existence
    def check_keys(kary)
      errs = []
      kary.each { |k| key?(k) || errs.push(k) }
      errs.empty? || cfg_err("Conf does not have #{errs}")
    end

    # Get the object of upper generation in which Config is generated
    def ancestor(n)
      @generation[n][:obj]
    end

    # Show all contents of all generation
    def path(key = nil)
      i = 0
      ary = @generation.map do |h|
        "  [#{i += 1}]{" + _show_generation_(key, h) + "} (#{h.object_id})"
      end
      _decorate_(ary.reverse)
    end

    # Show list of all key,val which will be taken with [] access
    def list
      db = {}
      @generation.each_with_index do |h, i|
        h.each { |k, v| db[k] = [i, v] unless db.key?(k) }
      end
      ary = db.map do |k, a|
        val = _show_db_(a[1])
        "  #{k} (#{a[0]}) = #{val}"
      end
      _decorate_(ary.reverse)
    end

    private

    def _show_db_(v)
      case v
      when String, Numeric, Enumerable
        _show_(v.inspect)
      when Proc
        _show_(v.class)
      else
        _show_(v)
      end
    end

    def _decorate_(ary)
      ["******[Config]******(#{object_id})", *ary, '************'].join("\n")
    end

    def _show_generation_(key, h)
      h.map do |k, v|
        next if key && k != key
        val = k == :obj ? _show_(v.class) : _show_contents_(v)
        "#{k.inspect.sub(/^:/, '')}: #{val}"
      end.compact.join(', ')
    end

    def _show_contents_(v)
      case v
      when Hash, Proc
        _show_(v.class)
      when Array
        _show_array_(v)
      else
        _show_(v.inspect)
      end
    end

    def _show_array_(v)
      '[' + v.map do |e|
        case e
        when Enumerable
          _show_(e.class)
        else
          _show_(e.inspect)
        end
      end.join(',') + "](#{v.object_id})"
    end

    def _show_(v)
      v.to_s.sub('CIAX::', '')
    end
  end

  # Option parser with Config
  class ConfOpts < GetOpts
    def initialize(usagestr, optargs = {})
      super do |opt, args|
        yield(Config.new(opt: opt, jump_groups: [], args: args), args)
      end
    end
  end
end
