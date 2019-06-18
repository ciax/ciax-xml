#!/usr/bin/env ruby
require 'open-uri'

module CIAX
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
      self
    end

    def load(tag = nil)
      url = format('http://%s%s%s.json', @host, @dir, base_name(tag))
      jstr = ___read_url(url)
      if jstr.empty?
        warning(' -- json url file (%s) is empty at loading', url)
      else
        ___store(jstr, url)
      end
      self
    end

    def latest
      # It works because cmt_procs doesn't have conversion.
      load
    end

    private

    def ___read_url(url)
      jstr = ''
      open(url) { |f| jstr = f.read }
      jstr
    rescue OpenURI::HTTPError
      alert('  -- no url file (%s)', url)
      jstr
    end

    def ___store(jstr, url)
      lt = time
      deep_update(jverify(j2h(jstr)))
      verbose { cfmt('Loaded url [%s](%d) of %s', url, size, hour(time)) }
      cmt if time > lt
    end
  end
end
