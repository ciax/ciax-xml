#!/usr/bin/env ruby
require 'libhashx'
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
    def initialize(super_cfg = nil, obj = self)
      super()
      @generation = [self]
      self[:obj] = obj
      case super_cfg
      when Config
        join_in(super_cfg)
      when Hash
        update(super_cfg)
        ___access_method
      end
    end

    def gen(obj)
      self.class.new(self, obj)
    end

    def join_in(super_cfg)
      @generation.concat(super_cfg.generation)
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
      sv_err("Config Key Type mismatch [#{key}]") unless self[key].is_a?(type)
      true
    end

    # Check key existence
    def check_keys(kary)
      absents = kary.find_all { |k| !key?(k) }
      absents.empty? || cfg_err("Conf does not have #{absents}")
    end

    # Get the object of upper generation in which Config is generated
    def ancestor(n)
      @generation[n][:obj]
    end

    # Show all contents of all generation
    def path(key = nil)
      i = 0
      ary = @generation.map do |h|
        "  [#{i += 1}]{" + ___show_generation(key, h) + "} (#{h.object_id})"
      end
      __decorate(ary.reverse)
    end

    # Show list of all key,val which will be taken with [] access
    def listing
      db = {}
      @generation.each_with_index do |h, i|
        h.each { |k, v| db[k] = [i, v] unless db.key?(k) }
      end
      ary = db.map do |k, a|
        val = ___show_db(a[1])
        "  #{k} (#{a[0]}) = #{val}"
      end
      __decorate(ary.reverse)
    end

    private

    def ___access_method
      this_keys.each do |k|
        define_singleton_method(k) { self[k] }
      end
    end

    def ___show_db(v)
      return __show(v.inspect) if __any_mod?(v, String, Numeric, Enumerable)
      return __show(v.class) if v.is_a? Proc
      __show(v)
    end

    def __decorate(ary)
      ["******[Config]******(#{object_id})", *ary, '************'].join("\n")
    end

    def ___show_generation(key, h)
      h.map do |k, v|
        next if key && k != key.to_sym
        val = k == :obj ? __show(v.class) : ___show_contents(v)
        "#{k.inspect.sub(/^:/, '')}: #{val}"
      end.compact.join(', ')
    end

    def ___show_contents(v)
      return __show(v.class) if __any_mod?(v, Hash, Proc)
      return ___show_array(v) if v.is_a? Array
      __show(v.inspect)
    end

    def ___show_array(v)
      '[' + v.map do |e|
        __show(e.is_a?(Enumerable) ? e.class : e.inspect)
      end.join(',') + "](#{v.object_id})"
    end

    def __show(v)
      v.to_s.sub('CIAX::', '')
    end

    def __any_mod?(v, *modary)
      modary.any? { |mod| v.is_a? mod }
    end
  end

  # Option parser with Config
  class ConfOpts < Config
    def initialize(ustr = '', optargs = {})
      GetOpts.new(ustr, optargs) do |opt, args|
        super(args: args, opt: opt)
        yield(self)
      end
    end

    def proj
      self[:proj] ||= (ENV['PROJ'] || self[:args].shift)
    end
  end
end
