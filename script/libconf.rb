#!/usr/bin/env ruby
require 'libhashx'
require 'libconfview'
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
    include ConfigView
    attr_reader :generation, :access_method_keys
    alias this_keys keys
    alias this_key? key?
    def initialize(spcfg = nil, obj = self)
      super()
      @generation = [self]
      @access_method_keys = []
      self[:obj] = obj
      ___init_param(spcfg)
    end

    def gen(obj)
      Config.new(self, obj)
    end

    def join_in(spcfg)
      @generation.concat(spcfg.generation)
      @access_method_keys.concat(spcfg.access_method_keys)
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

    private

    def ___init_param(spcfg)
      case spcfg
      when Config
        join_in(spcfg)
      when Hash
        update(spcfg)
        @access_method_keys.concat(spcfg.keys)
      end
      ___access_method
    end

    def ___access_method
      @access_method_keys.each do |k|
        next if respond_to?(k)
        define_singleton_method(k) { self[k] }
      end
    end
  end
end
