#!/usr/bin/env ruby
require 'libvarx'
require 'libdb'

module CIAX
  # Layer status container
  class StatPool < Hashx
    attr_reader :type, :default
    def initialize(obj, prom = nil)
      # Default layer status name
      @default = type?(obj, Statx)
      @type = @default.type
      loop do
        self[obj.type] = obj
        obj = obj.sub_stat || break
      end
      self[:sv_stat] = prom if prom && type?(prom, Prompt)
    end

    def get(token)
      token.sub!(/#{@type}:/, '')
      return @default.get(token) unless /:/ =~ token
      layer = $`
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

  # Status Data by using Db
  #  STDIN function is availabie
  #  Need Header(Dbx::Item)
  class Statx < Varx
    attr_reader :dbi, :sub_stat
    # obj can be Dbx::Index, Array, String
    def initialize(type, obj, mod = Dbx::Index)
      super(type, ___get_id(obj))
      @dbi ||= mod.new.get(@id)
      _attr_set(@dbi[:version].to_i, @dbi[:host])
      @layer = @dbi[:layer]
    end

    # Substitute str by self data
    # - str format: ${key}
    def subst(str)
      return str unless /\$\{/ =~ str
      enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
        str.gsub(/\$\{(.+)\}/) do
          get(Regexp.last_match(1))
        end
      end
    end

    private

    # Set dbi, otherwise generate by stdin info
    # When input from TTY
    #  obj == Dbx::Item    : return obj
    #  obj == String : id <= obj
    #  obj == Array  : id <= obj.shift
    # -----------------
    # Get Dbx::Item with id from Db
    def ___get_id(obj)
      case obj
      when Dbx::Item
        @dbi = obj
        @dbi[:site_id] || @dbi[:id]
      when Array
        obj.shift
      else
        obj
      end
    end
  end
end
