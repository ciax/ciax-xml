#!/usr/bin/env ruby
require 'libvarx'
require 'libdb'

module CIAX
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
      @stat_dic = Hashx.new(@type => self)
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

    # Substitute value (used for subst)
    def subst_val(key)
      get(key.sub(/#{@type}:/, ''))
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
