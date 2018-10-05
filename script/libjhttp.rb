#!/usr/bin/ruby
require 'open-uri'

module CIAX
  # Variable Status Data
  class Varx
    # JSON Http Loading module
    module JHttp
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      def ext_remote(host, dir = nil)
        @host = host || 'localhost'
        @dir = format('/%s/', dir || 'json')
        verbose { "Initiate Http (#{@host})" }
        self[:id] || Msg.cfg_err('ID')
        @upd_procs << proc { load }
        load
        self
      end

      def load(tag = nil)
        url = format('http://%s%s%s.json', @host, @dir, base_name(tag))
        jstr = ___read_url(url)
        if jstr.empty?
          warning(" -- json url file (#{url}) is empty at loading")
        else
          replace(jread(jstr))
        end
        cmt
      end

      def latest
        load
      end

      private

      def ___read_url(url)
        jstr = ''
        open(url) do |f|
          verbose { "Loading url [#{url}](#{f.size})" }
          jstr = f.read
        end
        jstr
      rescue OpenURI::HTTPError
        alert("  -- no url file (#{url})")
        jstr
      end
    end
  end
end
