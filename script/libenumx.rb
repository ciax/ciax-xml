#!/usr/bin/ruby
require 'libview'
require 'json'
# Extened Hash
module CIAX
  # Extended Enumerable
  module Enumx
    include ViewStruct
    def self.extended(obj)
      fail('Not Enumerable') unless obj.is_a? Enumerable
    end

    def deep_copy
      Marshal.load(Marshal.dump(self))
    end

    # Freeze one level deepth or more
    def deep_freeze
      rec_proc(self, &:freeze)
      self
    end

    # Merge self to ope
    def deep_update(ope, depth = nil)
      rec_merge(ope, self, depth)
      self
    end

    def read(json_str = nil)
      deep_update(j2h(json_str))
    end

    private

    def j2h(json_str = nil)
      JSON.load(json_str || gets(nil) || Msg.give_up("No data in file(#{ARGV})"))
    end

    # r(operand) will be merged to w (w is changed)
    def rec_merge(r, w, d)
      d -= 1 if d
      each_idx(r, w) do|i, cls|
        w = cls.new unless w.is_a? cls
        if d && d < 1
          verbose { "Merging #{i}" }
          w[i] = r[i]
        else
          w[i] = rec_merge(r[i], w[i], d)
        end
      end
    end

    def rec_proc(db)
      each_idx(db) do|i|
        rec_proc(db[i]) { |d| yield d }
      end
      yield db
    end

    def each_idx(ope, res = nil)
      case ope
      when Hash
        ope.each_key { |k| yield k, Hash }
      when Array
        ope.each_index { |i| yield i, Array }
      when String
      else
        return ope
      end
      res || ope.dup
    end
  end

  # Extended Hash
  class Hashx < Hash
    include Enumx
    attr_accessor :vmode
    def initialize(hash = {})
      update(hash)
      @vmode = 'v' # v|r|j
      %w(v r j).each do|k|
        @vmode = k if OPT[k]
      end if defined? OPT
      @cls_color = 6
    end

    def get(id)
      self[id]
    end

    def put(key, val)
      store(key, val)
    end

    # Make empty copy
    def skeleton
      hash = Hashx.new
      keys.each do|i|
        hash[i] = nil
      end
      hash
    end

    # Generate Hash Pick up keys
    def pick(keyary)
      hash = Hashx.new
      keyary.each do|key|
        hash[key] = self[key]
      end
      hash
    end
  end

  # Extended Array
  class Arrayx < Array
    include Enumx
    # sary: array of the element numbers [a,b,c,..]
    def skeleton(sary)
      return '' if sary.empty?
      dary = []
      sary[0].to_i.times do|i|
        dary[i] = skeleton(sary[1..-1])
      end
      dary
    end

    # Get value of Hash which is element of self
    def get(key)
      # In case of find(), find{|e| e.get(key)}.get(key) to get content
      each do|e|
        res = e.get(key)
        return res if res
      end
      nil
    end
  end
end
