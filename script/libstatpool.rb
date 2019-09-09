#!/usr/bin/env ruby
require 'libstatx'

module CIAX
  # Layer status container
  class StatPool < Hashx
    attr_reader :type, :default
    def initialize(obj, prom = nil)
      # Default layer status name
      @default = type?(obj, Statx)
      @type = @default.type
      loop do
        self[obj.type.to_sym] = obj
        obj = obj.sub_stat || break
      end
      self[:sv_stat] = prom if prom && type?(prom, Prompt)
    end

    def get(token)
      token.sub!(/#{@type}:/, '')
      return @default.get(token) unless /:/ =~ token
      layer = $`.to_sym
      cfg_err('No such entry [%s]', layer) unless key?(layer)
      self[layer].get($')
    end

    # Substitute str by self data
    # - str format: ${type:key}
    def subst(str)
      return str unless /\$\{/ =~ str
      enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
        str.gsub(/\$\{(.+)\}/) do
          get(Regexp.last_match(1))
        end
      end
    end

    def cmode(opt)
      each_value { |v| v.cmode(opt) }
    end
  end
end
