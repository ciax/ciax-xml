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
      _setid(id)
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
    def _setdbi(obj = nil, mod = Db)
      dbi = _getdbi_(obj, mod)
      @dbi = type?(dbi, Dbi)
      _setid(dbi[:site_id] || dbi[:id]) || Msg.cfg_err('ID')
      self[:ver] = dbi[:version].to_i
      @layer = dbi[:layer]
      self
    end

    def _getdbi_(obj, mod)
      case obj
      when Dbi
        obj
      when String
        mod.new.get(obj)
      else
        id = STDIN.tty? ? ARGV.shift : jmerge[:id]
        mod.new.get(id)
      end
    end

    def _setid(id)
      @id = self[:id] = id
    end

    def _file_base(tag = nil)
      [@type, self[:id], tag].compact.join('_')
    end
  end
end
