#!/usr/bin/ruby
require 'libjfile'
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
      self['id'] = id
      self['ver'] = ver if ver
      self['host'] = host || `hostname`.strip
      # Setting (Not shown in JSON)
    end

    def setdbi(dbi)
      @dbi = type?(dbi, Dbi)
      _setid(dbi['site_id'] || dbi['id'])
      self['ver'] = dbi['version'].to_i
      self
    end

    def ext_file
      extend(JFile).ext_file
    end
    
    private

    def _setid(id)
      self['id'] = id || Msg.cfg_err('ID')
      self
    end

    def _file_base(tag = nil)
      [@type, self['id'], tag].compact.join('_')
    end
  end
end
