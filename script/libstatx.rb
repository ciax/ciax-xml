#!/usr/bin/env ruby
require 'libvarx'
require 'libdb'

module CIAX
  # Layer status container
  class StatDic < Hashx
    def initialize(type, obj)
      # Default layer status name
      @type = type
      @obj = obj
      self[type] = @obj
    end

    def get(token)
      token.sub!(/#{@type}:/, '')
      return @obj.get(token) if /:/ !~ token
      layer = $LAST_MATCH_INFO
      cfg_err("No such entry #{layer}") unless key?(layer)
      self[layer].get($')
    end
  end

  # Status Data by using Db
  #  STDIN function is availabie
  #  Need Header(Dbx::Item)
  class Statx < Varx
    attr_reader :dbi, :stat_dic
    def initialize(type, obj, mod = Dbx::Index)
      super(type, ___get_id(obj))
      @dbi ||= mod.new.get(@id)
      _attr_set(@dbi[:version].to_i, @dbi[:host])
      @layer = @dbi[:layer]
      @stat_dic = StatDic.new(@type, self)
    end

    # Substitute str by self data
    # - str format: ${key}
    def subst(str)
      return str unless /\$\{/ =~ str
      enclose("Substitute from [#{str}]", 'Substitute to [%s]') do
        str.gsub(/\$\{(.+)\}/) do
          subst_val(Regexp.last_match(1))
        end
      end
    end

    def subst_val(key)
      @stat_dic.get(key)
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
