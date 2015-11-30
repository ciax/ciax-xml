#!/usr/bin/ruby
require 'libview'
# Extened Hash
module CIAX
  # Extended Enumerable
  module Enumx
    include View
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
    def deep_update(ope)
      rec_merge(self, ope)
      self
    end

    # Override data
    def read(json_str = nil)
      inp = json_str || gets(nil) || usr_err("No data in file(#{ARGV})")
      replace(j2h(inp))
    end

    # Merge data
    def load(json_str = nil)
      inp = json_str || gets(nil) || usr_err("No data in file(#{ARGV})")
      deep_update(j2h(inp))
    end

    private

    def rec_proc(db)
      each_idx(db) do|i|
        rec_proc(db[i]) { |d| yield d }
      end
      yield db
    end

    # r(operand) will be merged to w (w is changed)
    def rec_merge(me, other)
      me.update(other) do |_k, mv, ov|
        if mv.is_a? Hash
          rec_merge(mv, ov)
        else
          ov
        end
      end
    end
  end

  # Extended Hash
  class Hashx < Hash
    include Enumx
    def initialize(hash = {})
      update(hash)
      vmode(:v) # v|r|j
      %i(v r j).each do|k|
        vmode(k) if OPT[k]
      end if defined? OPT
      @cls_color = 6
    end

    def get(key)
      self[key]
    end

    def put(key, val)
      store(key, val)
    end

    # Replace value
    def rep(key, val)
      Msg.par_err("No such Key [#{key}]") unless key?(key)
      fetch(key).replace(val)
      val
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
        hash[key] = self[key] if key?(key)
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

  if __FILE__ == $PROGRAM_NAME
    a = Hashx.new
    a[:b] = { c: { 'd' => 'e' } }
    puts a.to_v
    e = Hashx.new(b: { c: { d: 'x' } })
    puts e.to_v
    puts a.deep_update(e).to_v
  end
end
