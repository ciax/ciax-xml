#!/usr/bin/ruby
require 'libupd'
require 'libdb'

module CIAX
  # Variable Status Data with Saving, Logging feature
  # Need Header(id,ver) data
  # Used for freqently changing data with remote
  class Varx < Upd
    attr_reader :type, :dbi, :id
    def initialize(type, id = nil, ver = nil, host = nil)
      super()
      @type = type
      # Headers
      _set_id(id)
      self[:ver] = ver if ver
      self[:host] = host || HOST
    end

    def ext_local_file(dir = nil)
      require 'libjfile'
      extend(JFile).ext_local_file(dir)
    end

    def ext_local_log
      require 'libjslog'
      extend(JsLog).ext_local_log
    end

    # Read only as a client
    def ext_http(host = nil, dir = nil)
      require 'libjhttp'
      extend(JHttp).ext_http(host, dir)
    end

    private

    # Set dbi, otherwise generate by stdin info
    def set_dbi(obj = nil, mod = Db)
      dbi = _get_dbi_(obj, mod)
      @dbi = type?(dbi, Dbi)
      _set_id(dbi[:site_id] || dbi[:id]) || Msg.cfg_err('ID')
      self[:ver] = dbi[:version].to_i
      @layer = dbi[:layer]
      self
    end

    def base_name(tag = nil)
      [@type, self[:id], tag].compact.join('_')
    end

    def _get_dbi_(obj, mod)
      if obj.is_a? Dbi
        obj
      elsif obj.is_a? String
        mod.new.get(obj)
      elsif STDIN.tty?
        mod.new.get(nil)
      else
        mod.new.get(jmerge[:id])
      end
    end

    def _set_id(id)
      @id = self[:id] = id
    end
  end
end
