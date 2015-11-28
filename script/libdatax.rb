#!/usr/bin/ruby
require 'libvarx'
require 'libjslog'
require 'libjhttp'

module CIAX
  # Header and Data Container(Hash or Array) with Loading feature
  class Datax < Varx
    # @data is hidden from access by '[]'.
    # @data will be appeared as self['data'] in json file.
    # @data never contains object which can't save with JSON
    def initialize(type, init_struct = {}, data_name = :data)
      super(type)
      # Variable Data (Shown as 'data'(data_name) hash in JSON)
      @data_name = data_name
      @data = init_struct.dup.extend(Enumx)
      @cls_color = 12
    end

    def to_j
      _getdata.to_j
    end

    def to_r
      _getdata.to_r
    end

    def read(json_str = nil)
      super
      _setdata
      self
    end

    def jmerge(json_str)
      inp = json_str
      deep_update(j2h(json_str))
      _mergedata
      self
    end

    def size
      @data.size
    end

    # put() still access to self[]
    def get(id)
      @data[id]
    end

    def num(n)
      get(@data.keys.sort[n])
    end

    private

    def _getdata
      verbose { 'Convert @data to [:data]' }
      hash = Hashx.new(self)
      hash[@data_name] = @data
      hash
    end

    def _setdata
      verbose { 'Convert [:data] to @data' }
      inc = delete(@data_name)
      return unless _check_setdata_(inc)
      inc=_key2str(inc) if @data.is_a?(Hash)
      @data.replace(inc)
      self
    end

    def _mergedata
      verbose { 'Marge [:data] to @data' }
      inc = delete(@data_name)
      return unless _check_setdata_(inc)
      inc=_key2str(inc) if @data.is_a?(Hash)
      @data.deep_update(inc)
      self
    end

    def _check_setdata_(data)
      if !data
        alert("[#{@data_name}] is empty")
      elsif !data.is_a? Enumerable
        alert("[#{@data_name}] is not Enumerablee")
      elsif data.is_a? @data.class
        return true
      else
        alert("[#{@data_name}] class is mismatch (#{@data.class} vs. #{data.class})")
      end
      false
    end

    def _check_load(json_str)
      h = j2h(json_str)
      verbose { "Version compare [#{h[:ver]}] vs. <#{self[:ver]}>" }
      if h.key?(:ver) && h[:ver] != self[:ver]
        alert("Version mismatch [#{h[:ver]}] should be <#{self[:ver]}>")
      end
      true
    end

    def _key2str(hash)
      res={}
      hash.each{ |k,v| res[k.to_s] = v}
      res
    end
  end

  # Data container is Hash
  class DataH < Datax
    # Update with strings (key=val,key=val,..)
    def str_update(str)
      pre_upd
      type?(str, String)
      str.split(',').each do|i|
        k, v = i.split('=')
        @data[k] = v
      end
    ensure
      post_upd
    end

    def put(key, val) # super should be placed at the end of method
      pre_upd
      @data[key] = val
      val
    ensure
      post_upd
    end

    # Replace value
    def rep(key, val)
      pre_upd
      Msg.par_err("No such Key [#{key}]") unless @data.key?(key)
      (@data[key] ||= '').replace(val)
      val
    ensure
      post_upd
    end

    def del(key) # super should be placed at the end of method
      pre_upd
      @data.delete(key)
      self
    ensure
      post_upd
    end

    def keys
      @data.keys
    end

    def key?(key)
      @data.key?(key)
    end

    def empty?
      @data.empty?
    end

    def values
      @data.values
    end

    def lastval
      get(keys.last)
    end

    # Generate DataH
    def pick(keyary)
      dh = DataH.new(@type, {}, @data_name)
      keyary.each do|k|
        if @data.key?(k)
          dh.put(k, get(k))
        else
          warning("No such Key [#{k}]")
        end
      end
      Msg.par_err('No Keys') if dh.empty?
      dh
    end
  end

  # Data container is Array
  class DataA < Datax
    def initialize(type, data_name = :data)
      super(type, [], data_name)
    end

    def add(val)
      @data << val
    end

    def last
      @data.last
    end
  end
end
