#!/usr/bin/ruby
require 'open-uri'

module CIAX
  module Http
    def self.extended(obj)
      Msg.type?(obj, Datax)
    end

    def ext_http(host)
      @host = host || 'localhost'
      verbose { "Initialize(#{@host})" }
      self['id'] || Msg.cfg_err('ID')
      @pre_upd_procs << proc { load }
      load
      self
    end

    def load(tag = nil)
      url = file_url(tag)
      json_str = ''
      open(url){|f|
        verbose { "Loading url [#{url}](#{f.size})" }
        json_str = f.read
      }
      if json_str.empty?
        warning(" -- json url file (#{url}) is empty at loading")
      else
        read(json_str)
      end
      self
    rescue OpenURI::HTTPError
      alert("  -- no url file (#{url})")
    end

    private
    def file_url(tag = nil)
      'http://' + @host + '/json/' + file_base(tag) + '.json'
    end
  end
end
