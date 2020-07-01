#!/usr/bin/env ruby
require 'libview'
# Extened Hash
module CIAX
  # Extended Enumerable
  module Enumx
    include View::Mode
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

    # Merge all the element with keeping structure
    # ope overwrites self
    def deep_update(ope, concat = false)
      __rec_merge(self, ope, concat)
      self
    end

    # Fill up all the empty(nil) element
    # ope overwrites self
    def deep_fillup(ope)
      __rec_fillup(self, ope)
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
      deep_update(j2h(jstr).extend(Enumx))
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
    def __rec_merge(me, other, concat)
      me.update(other) do |_k, mv, ov|
        if mv.is_a? Hash
          __rec_merge(mv, ov, concat)
        elsif mv.is_a? Array
          concat ? mv.concat(ov) : mv.replace(ov)
        else
          ov
        end
      end
    end

    # other fills up my blank (me will change)
    # don't merge non existent keys of me
    def __rec_fillup(me, other)
      return me unless __chk_cls(Hash, me, other)
      me.each do |k, mv|
        fv = other[k]
        next if __repl_enum(mv, fv)
        me.store(k, fv) if mv.to_s.empty?
      end
      me
    end

    def __repl_enum(mv, fv)
      return unless __chk_cls(Enumerable, mv, fv)
      if __chk_cls(Hash, mv, fv)
        __rec_fillup(mv, fv)
      elsif __chk_cls(Array, mv, fv)
        __rec_fillup_ary(mv, fv)
      end
    end

    def __rec_fillup_ary(me, other)
      return unless __chk_cls(Array, me, other)
      me.each_with_index do |mv, i|
        fv = other[i]
        next if __repl_enum(mv, fv)
        me[i] = fv if mv.to_s.empty?
      end
      me
    end

    def __chk_cls(cls, *ary)
      ary.all? { |v| v.is_a?(cls) }
    end
  end
end
