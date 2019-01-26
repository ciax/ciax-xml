#!/usr/bin/ruby
require 'libupd'

module CIAX
  # Variable Status Data having ID with Saving, Logging feature.
  # Need Header(id,ver) data.
  # Used for freqently changing data with remote.
  # Don't assign an instance variables to any element
  # whose link can be broken by load().
  class Varx < Upd
    attr_reader :type, :id
    def initialize(type, id = nil, ver = nil, host = nil, dir = nil)
      super()
      @type = type
      # @id is for file name (prevent overwritten)
      @id = id
      # @dir is subdir on web/file folder (~/.var/@dir)
      @dir = dir
      # Headers (could be overwritten by file load)
      self[:format_ver] = nil
      self[:id] = id
      self[:ver] = ver if ver
      self[:host] = host || HOST
    end

    def id
      self[:id]
    end

    def ext_local_file
      require 'libjfile'
      raise('File ext conflicts with Http ext') if @host
      extend(JFile).ext_local_file(@dir)
    end

    # independent from ext_local_file
    def ext_local_log
      require 'libjslog'
      raise('Log ext conflicts with Http ext') if @host
      extend(JsLog).ext_local_log
    end

    # Read only as a client
    def ext_remote(host = nil)
      require 'libjhttp'
      extend(JHttp).ext_remote(host, @dir)
    end

    def base_name(tag = nil)
      [@type, @id, tag].compact.join('_')
    end
  end
end
