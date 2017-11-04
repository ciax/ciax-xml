#!/usr/bin/ruby
require 'libupd'

module CIAX
  # Variable Status Data having ID with Saving, Logging feature
  # Need Header(id,ver) data
  # Used for freqently changing data with remote
  class Varx < Upd
    attr_reader :type, :id
    def initialize(type, id = nil, ver = nil, host = nil)
      super()
      @type = type
      # Headers
      __set_id(id)
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

    def base_name(tag = nil)
      [@type, self[:id], tag].compact.join('_')
    end

    def __set_id(id)
      @id = self[:id] = id
    end
  end
end
