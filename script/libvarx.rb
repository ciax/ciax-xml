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
    def initialize(type)
      super()
      @type = type
      # @id is for file name (prevent overwritten)
      self[:format_ver] = nil
    end

    # independent from ext_local_file
    def ext_local_log
      require 'libjslog'
      raise('Log ext conflicts with Http ext') if @host
      extend(JsLog).ext_local_log
    end

    # For loading file manipulation module
    def ext_local
      _ext_local_file
    end

    # Read only as a client
    def ext_remote(host = nil)
      require 'libjhttp'
      extend(JHttp).ext_remote(host, @dir)
    end

    def base_name(tag = nil)
      [@type, @id, tag].compact.join('_')
    end

    # With Format Version check
    def jverify(jstr = nil)
      hash = jread(jstr)
      msg = _val_diff?(:format_ver, hash)
      return hash unless msg
      warning(msg)
      Hashx.new
    end

    private

    def _ext_local_file
      require 'libjfile'
      raise('File ext conflicts with Http ext') if @host
      extend(JFile)
      _ext_local_file(@dir)
    end

    def _attr_set(id = nil, ver = nil, host = nil, dir = nil)
      # Headers (could be overwritten by file load)
      @id = (self[:id] ||= id)
      self[:ver] = ver if ver
      self[:host] = host || HOST
      # @dir is subdir on web/file folder (~/.var/@dir)
      @dir = dir
    end

    def _val_diff?(key, hash)
      inc = hash[key]
      org = self[key]
      return if inc == org
      format('File format version mismatch <%s> for [%s]', inc, org)
    end
  end
end
