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
      _rec_proc4enum(self, &:freeze)
      self
    end

    # ope overwrites self
    def deep_update(ope)
      _rec_merge(self, ope)
      self
    end

    # Search String
    def deep_search(reg)
      _rec_proc4str(self) do |obj, path|
        next unless obj.is_a?(String)
        if /#{reg}/ =~ obj
          path << obj
          break path
        end
      end
    end

    # Overwrite data
    def jread(jstr = nil)
      inp = jstr || gets(nil) || data_err("No data in file(#{ARGV})")
      j2h(inp)
    end

    # Merge data with setting sub structures
    def jmerge(jstr = nil)
      deep_update(jread(jstr))
    end

    private

    # recursive procs for enumx
    def _rec_proc4enum(enum, &block)
      return unless enum.is_a? Enumerable
      enum.each do |k, v| # v=nil if enum is Array
        _rec_proc4enum(v || k, &block)
      end
      yield enum
    end

    # recursive procs for str
    def _rec_proc4str(enum, path = [], &block)
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
        _rec_proc4str(v, path, &block).pop
      end
    end

    # other overwrites me (me will change)
    def _rec_merge(me, other)
      me.update(other) do |_k, mv, ov|
        if mv.is_a? Hash
          _rec_merge(mv, ov)
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
      @layer = layer_name
    end

    # Generate value if init_proc and no key
    def get(key, &init_proc)
      self[key] = yield key if !key?(key) && init_proc
      self[key]
    end

    # Put value. return self
    def put(key, val, &done_proc)
      return self unless __diff?(key, val)
      store(key, val)
      yield if done_proc
      self
    end

    # Replace value. return self
    def repl(key, val, &done_proc)
      Msg.par_err("No such Key [#{key}]") unless key?(key)
      Msg.cfg_err('Value should be String') unless val.is_a?(String)
      if __diff?(key, val)
        verbose { "Replace:timing(#{key}) #{fetch(key)} ->  #{val}" }
        fetch(key).replace(val)
        yield if done_proc
      end
      self
    end

    # Delete key, return self
    def del(key, &done_proc)
      if key?(key)
        delete(key)
        yield if done_proc
      end
      self
    end

    # Make empty copy (Empty string because it can be operated with replacement)
    def skeleton
      keys.each_with_object(Hashx.new) do |i, hash|
        hash[i] = ''
      end
    end

    # Generate Hashx with picked up keys
    def pick(keyary, atrb = {})
      keyary.each_with_object(Hashx.new(atrb)) do |key, hash|
        hash[key] = self[key] if key?(key)
      end
    end

    # Pick Hash which isn't Array or Hash for XML attributes
    def attributes(id = nil)
      atrb = Hashx.new(id ? { id: id } : {})
      each_with_object(atrb) do |k, v, hash|
        next if v.is_a? Enumerable
        hash[k] = v
      end
    end

    private

    def __diff?(key, val)
      # allows no key
      self[key] != val
    end
  end

  # Extended Array
  class Arrayx < Array
    include Enumx
    # sary: array of the element numbers [a,b,c,..]
    def skeleton(sary)
      return '' if sary.empty?
      sary[0].to_i.times.each_with_object([]) do |i, dary|
        dary[i] = skeleton(sary[1..-1])
      end
    end

    # Get value of Hash which is element of self
    def get(key)
      # In case of find(), get(find{|e| e.get(key)}) to get content
      res = nil
      find { |e| res = e.get(key) } && res
    end

    # Generate Hash with key array
    def a2h(*keys)
      each_with_object(Hashx.new) do |val, atrb|
        key = keys.shift
        atrb[key] = val if key
      end
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
