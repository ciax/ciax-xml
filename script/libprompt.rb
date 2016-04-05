#!/usr/bin/ruby
require 'libvarx'
module CIAX
  # For server status through all layers
  class Prompt < Varx
    attr_reader :db
    # type = site,mcr
    def initialize(type, id)
      super(['server', type].compact.join('_'), id)
      @db = {}
      self[:msg] = ''
      @post_upd_procs << proc { verbose { "Save #{id}:timing #{pick(%i(busy queue))}" } }
    end

    # For String Data
    def add_str(key, val = '')
      self[key] = type?(val.dup, String) unless self[key].is_a? String
      self
    end

    def repl(key, val)
      super && verbose { "Changes [#{key}] -> #{val}" } && self
    end

    # For Binary Data with display db
    # Value should be String to replace
    def add_flg(db = {})
      @db.update(type?(db, Hash))
      db.keys.each { |k| self[k] = 'false' }
      self
    end

    def up(key)
      cfg_err("No such flag [#{key}]") unless key?(key)
      repl(key, 'true')
    end

    def dw(key)
      cfg_err("No such flag [#{key}]") unless key?(key)
      repl(key, 'false')
    end

    def set_flg(key, flag)
      flag ? up(key) : dw(key)
    end

    # flag will be converted to Boolean in JSON
    # when the string is 'true' or 'false'
    def up?(key)
      self[key].to_s == 'true'
    end

    # For Array Data
    def add_array(key, ary = [])
      self[key] = type?(ary, Array) unless self[key].is_a? Array
      self
    end

    def flush(key, ary = [])
      type?(self[key], Array).replace(ary)
      self
    ensure
      time_upd
      post_upd
    end

    def push(key, elem)
      self[key].push(elem) unless type?(self[key], Array).include?(elem)
      self
    ensure
      time_upd
      post_upd
    end

    # Show Message
    def msg
      self[:msg]
    end

    def to_v
      verbose { 'Shell' + map { |k, v| "#{k}:'#{v}'(#{v.object_id})" }.inspect }
      # Because true(String) will be converted to Boolean in JSON
      @db.map { |k, v| v if self[k].to_s == 'true' }.join
    end

    # Subtract and merge to self data, return rest of the data
    def sub(input)
      hash = input.dup
      @db.keys.each do|k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
    ensure
      time_upd
      post_upd
    end

    # Merge sub prompt for picked up keys
    def sub_merge(sub, args)
      type?(sub, Prompt)
      @db.update(sub.db)
      update(sub.pick(args))
    end

    private(:[]=)
    protected(:[])
  end
end
