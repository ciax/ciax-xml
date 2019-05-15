#!/usr/bin/env ruby
require 'libenumx'
# CIAX-XML
module CIAX
  # Extended Hash
  class Hashx < Hash
    include Enumx
    def initialize(hash = {})
      update(hash) if hash
      @layer = layer_name
    end

    # Generate value if @get_proc and no key
    def get(key, &gen_proc)
      self[key] ||= yield key if gen_proc
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
      key?(key) || par_err("No such Key [#{key}]")
      val.is_a?(String) || cfg_err("Value is not String [#{val}]/#{val.class}")
      if __diff?(key, val)
        verbose { "Replace:timing(#{key}) #{fetch(key)} ->  #{val}" }
        fetch(key).replace(val)
        yield if done_proc
      end
      self
    end

    # Delete keyary, return self
    def del(*keyary, &done_proc)
      yield if keyary.any? { |k| delete(k) } && done_proc
      self
    end

    # Fill in unexistent keys by other Hash
    def cover(other)
      update(other) { |_, v| v }
    end

    # Make empty copy (Empty string because it can be operated with replacement)
    def skeleton
      keys.each_with_object(Hashx.new) do |i, hash|
        hash[i] = ''
      end
    end

    # Generate Hashx with picked up keys
    def pick(*keyary)
      keyary.each_with_object(Hashx.new) do |key, hash|
        hash[key] = self[key] if key?(key)
      end
    end

    # key list that value is true
    def trues
      select { |_k, v| v }.keys
    end

    # Pick Hash which isn't Array or Hash for XML attributes
    def attrs
      hash = Hashx.new
      each do |k, v|
        hash[k] = v unless v.is_a? Enumerable
      end
      hash
    end

    def first
      self[keys.first]
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

    def key?(key)
      any? { |e| e.key?(key) }
    end

    # Update interface for TagList
    def upd
      self
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
