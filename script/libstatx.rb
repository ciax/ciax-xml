#!/usr/bin/ruby
require 'libvarx'
require 'libdb'

module CIAX
  # Status Data by using Db
  # Need Header(Dbi)
  class Statx < Varx
    attr_reader :dbi
    def initialize(type, obj, mod = Db)
      @dbi = type?(___get_dbi(obj, mod), Dbi)
      super(type, @dbi[:site_id] || @dbi[:id], @dbi[:version].to_i, @dbi[:host])
      @layer = @dbi[:layer]
    end

    private

    # Set dbi, otherwise generate by stdin info
    def ___get_dbi(obj, mod)
      if obj.is_a? Dbi
        obj
      elsif obj.is_a? String
        mod.new.get(obj)
      elsif STDIN.tty?
        mod.new.get(nil)
      else
        mod.new.get(jmerge[:id])
      end
    end
  end
end
