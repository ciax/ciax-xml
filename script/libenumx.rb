#!/usr/bin/ruby
require 'libview'
require 'libgetopts'
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
      rec_proc4enum(self, &:freeze)
      self
    end

    # Merge self to ope
    def deep_update(ope)
      rec_merge(self, ope)
      self
    end

    # Search String
    def deep_search(reg)
      path = []
      rec_proc4str(self, path) do |obj|
        next unless obj.is_a?(String)
        if /#{reg}/ =~ obj
          path << obj
          break
        end
      end
      path
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

    def rec_proc4enum(enum, &block)
      return unless enum.is_a? Enumerable
      enum.each do |k, v| # v=nil if enum is Array
        rec_proc4enum(v || k, &block)
      end
      block.call(enum)
    end

    def rec_proc4str(enum, path = [], &block)
      if enum.is_a? Enumerable
        enum.each_with_index do |e, i| # e = Array if enum is Hash
          k, v = e.is_a?(Array) ? e : [i, e]
          path.push(k.to_s)
          rec_proc4str(v, path, &block)
          path.pop
        end
      else
        block.call(enum, path)
      end
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
      update(hash) if hash
      vmode(VMODE) # v|r|j
    end

    # Generate value if init_proc and no key
    def get(key, &init_proc)
      self[key] = init_proc.call(key) if !key?(key) && init_proc
      self[key]
    end

    # Put value. return nil if no changes
    def put(key, val)
      return if self[key] == val
      store(key, val)
    end

    # Replace value. return nil if no changes
    def repl(key, val)
      Msg.par_err("No such Key [#{key}]") unless key?(key)
      Msg.cfg_err('Value should be String') unless val.is_a?(String)
      return if fetch(key) == val
      verbose { "Replace:timing(#{key}) #{fetch(key)} ->  #{val}" }
      fetch(key).replace(val)
    end

    # Make empty copy
    def skeleton
      hash = Hashx.new
      keys.each do|i|
        hash[i] = nil
      end
      hash
    end

    # Generate Hashx with picked up keys
    def pick(keyary, atrb = {})
      hash = Hashx.new(atrb)
      keyary.each do|key|
        hash[key] = self[key] if key?(key)
      end
      hash
    end

    # Pick Hash which isn't Array or Hash for XML attributes
    def attributes(id = nil)
      atrb = Hashx.new
      atrb[:id] = id if id
      each do |k, v|
        next if v.is_a? Enumerable
        atrb[k] = v
      end
      atrb
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

    # Generate Hash with key array
    def a2h(*keys)
      atrb = Hashx.new
      each do |val|
        key = keys.shift
        atrb[key] = val if key
      end
      atrb
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
