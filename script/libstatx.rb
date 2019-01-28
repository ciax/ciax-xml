#!/usr/bin/ruby
require 'libvarx'
require 'libdb'

module CIAX
  # Status Data by using Db
  # Need Header(Dbi)
  class Statx < Varx
    attr_reader :dbi
    def initialize(type, obj, mod = Db)
      super(type)
      @dbi = type?(___get_dbi(obj, mod), Dbi)
      _attr_set(@dbi[:site_id] || @dbi[:id], @dbi[:version].to_i, @dbi[:host])
      @layer = @dbi[:layer]
    end

    private

    # Set dbi, otherwise generate by stdin info
    def ___get_dbi(obj, mod)
      return obj if obj.is_a? Dbi
      obj = jmerge[:id] unless STDIN.tty?
      mod.new.get(obj)
    end
  end
end
