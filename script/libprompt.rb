#!/usr/bin/ruby
require 'libvarx'
module CIAX
  # For server status through all layers
  class Prompt < Varx
    NS_COLOR = 9
    attr_reader :db
    # type = site,mcr
    def initialize(type, id)
      super(['server', type].compact.join('_'), id)
      @db = {}
      self[:msg] = ''
    end

    # For String Data
    def add_str(key, val = '')
      self[key] = type?(val.dup, String)
      self
    end

    def rep(key, val)
      cfg_err('Value should be String') unless val.is_a?(String)
      verbose { "Change [#{key}] -> #{val}" }
      super
    end

    # For Binary Data with display db
    def add_flg(db = {})
      @db.update(type?(db, Hash))
      self
    end

    def up(key)
      pre_upd
      self[key] = true
      verbose { "Set [#{key}]" }
      self
    ensure
      post_upd
    end

    def dw(key)
      pre_upd
      self[key] = false
      verbose { "Reset [#{key}]" }
      self
    ensure
      post_upd
    end

    # For Array Data
    def add_array(key, ary = [])
      self[key] = type?(ary, Array) unless self[key].is_a? Array
      self
    end

    def flush(key, ary = [])
      pre_upd
      type?(self[key], Array).replace(ary)
      self
    ensure
      post_upd
    end

    def push(key, elem)
      pre_upd
      self[key].push(elem) unless type?(self[key], Array).include?(elem)
      self
    ensure
      post_upd
    end

    # Show Message
    def msg
      self[:msg]
    end

    def to_v
      verbose { "Shell\n" + inspect }
      @db.map { |k, v| v if self[k] }.join('')
    end

    def server
      ThreadLoop.new('Prompt', 12) do
        exec_buf if @q.empty?
        verbose { 'Waiting' }
        pri_sort(@q.shift)
      end
      self
    end

    # Subtract and merge to self data, return rest of the data
    def sub(input)
      pre_upd
      hash = input.dup
      @db.keys.each do|k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
    ensure
      post_upd
    end

    private(:[], :[]=)
  end
end
