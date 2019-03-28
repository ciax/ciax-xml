#!/usr/bin/env ruby
require 'libdic'
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
    def ___get_dbi(obj, mod)
      return obj if obj.is_a? Dbi
      unless obj || STDIN.tty?
        @preload = jread
        obj = @preload[:id]
      end
      mod.new.get(obj)
    end
  end
end
