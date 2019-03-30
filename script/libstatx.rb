#!/usr/bin/env ruby
require 'libvarx'
require 'libdb'

module CIAX
  # Status Data by using Db
  #  STDIN function is availabie
  #  Need Header(Dbi)
  class Statx < Varx
    attr_reader :dbi
    def initialize(type, obj, mod = Db)
      super(type)
      @dbi = type?(___get_dbi(obj, mod), Dbi)
      _attr_set(@dbi[:site_id] || @dbi[:id], @dbi[:version].to_i, @dbi[:host])
      @layer = @dbi[:layer]
    end

    def ext_local
      super.load
    end

    private

    # Set dbi, otherwise generate by stdin info
    # When input from TTY
    #  obj == Dbi    : return obj
    #  obj == String : id <= obj
    #  obj == Array  : id <= obj.shift
    # When input from File
    #  obj <= Read[:id] anyway
    # -----------------
    # Get Dbi with id from Db
    def ___get_dbi(obj, mod)
      return obj if obj.is_a? Dbi
      id = if STDIN.tty?
             obj.is_a?(Array) ? obj.shift : obj
           else
             (@preload = jread)[:id]
           end
      mod.new.get(id)
    end
  end
end
