#!/usr/bin/ruby
require 'libupd'
require 'libdb'
require 'libjsave'

module CIAX
  # Variable Status Data with Saving, Logging feature
  # Need Header(id,ver) data
  class Varx < Upd
    attr_reader :type, :dbi
    def initialize(type, id = nil, ver = nil, host = nil)
      super()
      @type = type
      # Headers
      self['id'] = id
      self['ver'] = ver if ver
      self['host'] = host || `hostname`.strip
      # Setting (Not shown in JSON)
      @thread = Thread.current # For Thread safe
    end

    def setdbi(dbi)
      @dbi = type?(dbi, Dbi)
      _setid(dbi['site_id'] || dbi['id'])
      self['ver'] = dbi['version'].to_i
      self
    end

    def ext_save # Save data at every after update
      extend JSave
      ext_save
      self
    end

    def ext_log # Write only for server
      extend JsLog
      ext_log
      self
    end

    private

    def _setid(id)
      self['id'] = id || Msg.cfg_err('ID')
      self
    end

    def file_base(tag = nil)
      [@type, self['id'], tag].compact.join('_')
    end
  end
end
