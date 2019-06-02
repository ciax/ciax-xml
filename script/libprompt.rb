#!/usr/bin/env ruby
require 'libvarx'
module CIAX
  # For server status through all layers
  #   This instance will be assigned as @sv_stat in other classes
  class Prompt < Varx
    attr_reader :flg_db
    # type = site,mcr
    def initialize(type, id)
      cfg_err('No ID') unless id
      super(['server', type].compact.join('_'), id)
      # @flg_db: [key <-> Symbol at true] Database
      @flg_db = {}
      self[:msg] = ''
      init_time2cmt
    end

    # For String Data
    def init_str(key, val = '') # returns self
      self[key] = type?(val.dup, String) unless self[key].is_a? String
      self
    end

    # For Binary Data with display flg_db
    # Value should be String to replace
    def init_flg(flg_db = {}) # returns self
      @flg_db.update(type?(flg_db, Hash))
      flg_db.keys.each do |k|
        self[k] = 'false'
      end
      self
    end

    def up(*keya)
      keya.each { |key| __turn_flag(key, 'up', 'true') }
      self
    end

    def dw(*keya)
      keya.each { |key| __turn_flag(key, 'down', 'false') }
      self
    end

    def set_flg(key, flag)
      flag ? up(key) : dw(key)
    end

    def reset
      verbose { cfmt('Reset Flags %p', @flg_db.keys) }
      @flg_db.keys.each { |k| repl(k, 'false') }
      self
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
      verbose { cfmt('Flushed queue %p', self[key]) }
      self
    end

    def push(key, elem) # returns self
      self[key].push(elem) # unless type?(self[key], Array).include?(elem)
      verbose { cfmt('Pushed queue %p', self[key]) }
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
      @flg_db.map { |k, v| v if self[k].to_s == 'true' }.join
    end

    # Subtract and merge to self data, return rest of the data
    def subtr(input)
      hash = input.dup
      @flg_db.keys.each do |k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
    end

    # Merge sub prompt for picked up keys
    def sub_merge(sub, args)
      type?(sub, Prompt)
      @flg_db.update(sub.flg_db)
      # Upper layer propagation
      sub.cmt_procs.append(self, @id, 4) do |ss|
        update(ss.pick(args)).cmt
      end
      self
    end

    private(:[]=)
    protected(:[])

    private

    def __turn_flag(key, label, tfstr)
      cfg_err("No such flag [#{key}]") unless key?(key)
      verbose do
        chg = self[key] != tfstr ? '-> changed' : ''
        cfmt('Flag %s [%s] %s', label, key, chg)
      end
      repl(key, tfstr)
      self
    end
  end
end
