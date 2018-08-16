#!/usr/bin/ruby
require 'libupd'

module CIAX
  # Variable Status Data having ID with Saving, Logging feature.
  # Need Header(id,ver) data.
  # Used for freqently changing data with remote.
  # Don't assign an instance variables to any element
  # whose link can be broken by load().
  class Varx < Upd
    attr_reader :type
    def initialize(type, id = nil, ver = nil, host = nil, dir = nil)
      super()
      @type = type
      @dir = dir
      # Headers
      self[:id] = id
      self[:ver] = ver if ver
      self[:host] = host || HOST
    end

    def id
      self[:id]
    end

    def ext_local_file
      require 'libjfile'
      extend(JFile).ext_local_file(@dir)
    end

    def ext_local_log
      require 'libjslog'
      extend(JsLog).ext_local_log
    end

    # Read only as a client
    def ext_remote(host = nil)
      require 'libjhttp'
      extend(JHttp).ext_remote(host, @dir)
    end

    def base_name(tag = nil)
      [@type, self[:id], tag].compact.join('_')
    end
  end
end
