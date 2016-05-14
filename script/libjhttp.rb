#!/usr/bin/ruby
require 'open-uri'

module CIAX
  # JSON Http Loading module
  module JHttp
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_http(host)
      @host = host || 'localhost'
      verbose { "Initiate Http (#{@host})" }
      self[:id] || Msg.cfg_err('ID')
      @upd_procs << proc { load }
      load
      self
    end

    def load(tag = nil)
      url = file_url(tag)
      open(url) do|f|
        verbose { "Loading url [#{url}](#{f.size})" }
        json_str = f.read
        return read(json_str) unless json_str.empty?
      end
      warning(" -- json url file (#{url}) is empty at loading")
      self
    rescue OpenURI::HTTPError
      alert("  -- no url file (#{url})")
    end

    def latest
      load
    end

    private

    def file_url(tag = nil)
      'http://' + @host + '/json/' + _file_base(tag) + '.json'
    end
  end
end
