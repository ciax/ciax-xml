#!/usr/bin/ruby
require 'libjslog'
require 'libjfile'
require 'libjhttp'
require 'libupd'
require 'libdb'

module CIAX
  # Variable Status Data with Saving, Logging feature
  # Need Header(id,ver) data
  class Varx < Upd
    attr_reader :type, :dbi
    def initialize(type, id = nil, ver = nil, host = nil)
      super()
      @type = type
      # Headers
      self[:id] = id
      self[:ver] = ver if ver
      self[:host] = host || ENV['HOSTNAME'].strip
      # Setting (Not shown in JSON)
    end

    # Read only as a client
    def ext_http(host = nil)
      extend(JHttp).ext_http(host)
    end

    def ext_file
      extend(JFile).ext_file
    end

    def ext_log
      extend(JsLog).ext_log
    end

    private

    # Set dbi, otherwise generate by stdin info
    def _setdbi(obj = nil, mod = Db)
      case obj
      when Dbi
        dbi = obj
      when String
        dbi = mod.new.get(obj)
      else
        id = STDIN.tty? ? ARGV.shift : read[:id]
        dbi = mod.new.get(id)
      end
      @dbi = type?(dbi, Dbi)
      _setid(dbi[:site_id] || dbi[:id])
      self[:ver] = dbi[:version].to_i
      self
    end

    def _setid(id)
      self[:id] = id || Msg.cfg_err('ID')
      self
    end

    def _file_base(tag = nil)
      [@type, self[:id], tag].compact.join('_')
    end
  end
end
