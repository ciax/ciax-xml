#!/usr/bin/ruby
require 'libview'
require 'libgetopts'
# Extened Hash
module CIAX
  # Extended Enumerable
  module Enumx
    include View
    def self.extended(obj)
      data_err('Not Enumerable') unless obj.is_a? Enumerable
    end

    def deep_copy
      Marshal.load(Marshal.dump(self))
    end

    # Freeze one level deepth or more
    def deep_freeze
      __rec_proc4enum(self, &:freeze)
      self
    end

    # ope overwrites self
    def deep_update(ope)
      __rec_merge(self, ope)
      self
    end

    # Search String
    def deep_search(reg)
      __rec_proc4str(self) do |obj, path|
        next unless obj.is_a?(String)
        if /#{reg}/ =~ obj
          path << obj
          break path
        end
      end
    end

    # Merge data with setting sub structures
    def jmerge(jstr = nil)
      deep_update(jread(jstr))
    end

    private

    # recursive procs for enumx
    def __rec_proc4enum(enum, &block)
      return unless enum.is_a? Enumerable
      enum.each do |k, v| # v=nil if enum is Array
        __rec_proc4enum(v || k, &block)
      end
      yield enum
    end

    # recursive procs for str
    def __rec_proc4str(enum, path = [], &block)
      if enum.is_a? Enumerable
        ___each_enum(enum, path, block)
      else
        yield(enum, path)
      end
      path
    end

    def ___each_enum(enum, path, block)
      enum.each_with_index do |e, i| # e = Array if enum is Hash
        k, v = e.is_a?(Array) ? e : [i, e]
        path.push(k.to_s)
        __rec_proc4str(v, path, &block).pop
      end
    end

    # other overwrites me (me will change)
    def __rec_merge(me, other)
      me.update(other) do |_k, mv, ov|
        if mv.is_a? Hash
          __rec_merge(mv, ov)
        elsif mv.is_a? Enumerable
          mv.replace(ov)
        else
          ov
        end
      end
    end
  end
end
