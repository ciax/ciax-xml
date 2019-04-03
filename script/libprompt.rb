#!/usr/bin/env ruby
require 'libvarx'
module CIAX
  # For server status through all layers
  #   This instance will be assigned as @sv_stat in other classes
  class Prompt < Varx
    attr_reader :db
    # type = site,mcr
    def initialize(type, id)
      super(['server', type].compact.join('_'), id)
      @db = {}
      self[:msg] = ''
      init_time2cmt
      @layer = 'all'
    end

    # For String Data
    def init_str(key, val = '') # returns self
      self[key] = type?(val.dup, String) unless self[key].is_a? String
      self
    end

    # For Binary Data with display db
    # Value should be String to replace
    def init_flg(db = {}) # returns self
      @db.update(type?(db, Hash))
      db.keys.each { |k| self[k] = 'false' }
      self
    end

    def up(key)
      cfg_err("No such flag [#{key}]") unless key?(key)
      verbose { "Flag up #{key} (#{self[key]})" }
      repl(key, 'true')
      self
    end

    def dw(key)
      cfg_err("No such flag [#{key}]") unless key?(key)
      verbose { "Flag down #{key} (#{self[key]})" }
      repl(key, 'false')
      self
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
    def init_array(key, ary = []) # returns self
      self[key] = type?(ary, Array) unless self[key].is_a? Array
      self
    end

    def flush(key, ary = [])
      type?(self[key], Array).replace(ary)
      self
    end

    def push(key, elem) # returns self
      self[key].push(elem) # unless type?(self[key], Array).include?(elem)
      self
    end

    def erase(key, elem)
      type?(self[key], Array).delete(elem)
      self
    end

    # For Message
    def msg
      self[:msg]
    end

    def seterr
      repl(:msg, $ERROR_INFO.to_s.split("\n").first)
    end

    def to_v
      verbose { 'Shell' + inspect }
      # Because true(String) will be converted to Boolean in JSON
      @db.map { |k, v| v if self[k].to_s == 'true' }.join
    end

    # Subtract and merge to self data, return rest of the data
    def sub(input)
      hash = input.dup
      @db.keys.each do |k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
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
