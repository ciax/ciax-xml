#!/usr/bin/env ruby
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
        @id || Msg.cfg_err('ID')
        @upd_procs.append(self, :http) { load }
        upd
      end

      def load(tag = nil)
        fname = base_name(tag)
        url = format('http://%s%s%s.json', @host, @dir, fname)
        jstr = ___read_url(url)
        if jstr.empty?
          warning(' -- json url file (%s) is empty at loading', url)
        else
          ___chkupd(jstr, fname)
        end
        self
      end

      def latest
        load
      end

      private

      def ___chkupd(jstr, fname)
        lt = self[:time]
        deep_update(jverify(jstr, fname))
        cmt if self[:time] > lt
      end

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
