#!/usr/bin/env ruby
require 'libupd'

module CIAX
  # Variable Status Data having ID with Saving, Logging feature.
  # Need Header(id, data_ver, format_ver) data.
  #   (@id is for file name at initial setting,  [:id] can be changed)
  # Used for freqently changing data with remote.
  # Don't assign an instance variables to any element
  # whose link can be broken by load().
  class Varx < Upd
    # For checking local/remote, @host is exposed
    attr_reader :type, :id, :host
    def initialize(type, id = nil)
      super()
      @type = type
      # When input from File
      #  obj <= Read[:id] anyway
      id = jread[:id] if !id && !STDIN.tty?
      @id = self[:id] = id
      # @id is for file name (prevent overwritten)
      self[:format_ver] = nil
    end

    # For loading file manipulation module
    def ext_local
      ext_mod(:Local)
    end

    # Read only as a client
    def ext_remote(host = nil)
      require 'libjhttp'
      ext_mod(:JHttp) { |o| o.ext_remote(host, @dir) }
    end

    # Control mode (Local or Remote) by host
    def cmode(host)
      host ? ext_remote(host) : ext_local.ext_file
    end

    def base_name(tag = nil)
      [@type, @id, tag].compact.join('_')
    end

    # With Format Version check
    def jverify(hash = {})
      __chk_ver('format', hash)
      # For back compatibility
      hash[:data_ver] = hash.delete(:ver) if hash.key?(:ver)
      __chk_ver('data', hash) ? hash : {}
    end

    private

    def _attr_set(ver = nil, host = nil, dir = nil)
      # Headers (could be overwritten by file load)
      self[:data_ver] = ver if ver
      self[:host] = host || HOST
      # @dir is subdir on web/file folder (~/.var/@dir)
      @dir = dir
    end

    # Data/Format Version check, no read if different
    # (otherwise old version number remain as long as the file exists)
    def __chk_ver(type, hash)
      key = "#{type}_ver".to_sym
      org = self[key]
      inc = hash[key]
      verbose { cfmt('Checking %s inc<%s> vs org[%s]', key, inc, org) }
      return true if inc == org
      warning('File %s version mismatch <%s> for [%s]', type, inc, org)
      false
    end

    # Local mode
    module Local
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      def ext_local
        raise('Log ext conflicts with Http ext') if @host
        self
      end

      # independent from ext_file
      def ext_log
        require 'libjslog'
        ext_mod(:JsLog)
      end

      def ext_file
        require 'libjfile'
        ext_mod(:JFile) { |o| o.ext_file(@dir) }
      end
    end
  end
end
