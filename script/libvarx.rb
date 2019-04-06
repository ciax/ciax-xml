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
      id = (@preload = jread)[:id] if !id && !STDIN.tty?
      @id = self[:id] = id
      # @id is for file name (prevent overwritten)
      self[:format_ver] = nil
    end

    # For loading file manipulation module
    def ext_local
      extend(context_module('Local')).ext_local
    end

    # Read only as a client
    def ext_remote(host = nil)
      require 'libjhttp'
      return self if is_a? JHttp
      extend(JHttp).ext_remote(host, @dir)
    end

    # Control mode (Local or Remote) by host
    def cmode(host)
      host ? ext_remote(host) : ext_local.ext_file
    end

    def base_name(tag = nil)
      [@type, @id, tag].compact.join('_')
    end

    # With Format Version check
    def jverify(jstr = nil, fname = nil)
      fname = " of [#{fname}]" if fname
      hash = jread(jstr)
      __chk_ver("format#{fname}", hash)
      # For back compatibility
      hash[:data_ver] = hash.delete(:ver) if hash.key?(:ver)
      __chk_ver("data#{fname}", hash)
      hash
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
      return if inc == org
      data_err(cfmt('File %s version mismatch <%s> for [%s]', type, inc, org))
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

      # independent from ext_local_file
      def ext_log
        require 'libjslog'
        return self if is_a? JsLog
        extend(JsLog).ext_log
      end

      def ext_file
        require 'libjfile'
        return self if is_a? JFile
        extend(JFile).ext_file(@dir)
      end
    end
  end
end
