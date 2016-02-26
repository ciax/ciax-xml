#!/usr/bin/ruby
require 'libmsgfmt'
# Common Module
module CIAX
  ### Time Format Methods ###
  module Msg
    module_function

    def now_msec
      (Time.now.to_f * 1000).to_i
    end

    def elps_sec(msec, base = nil)
      return 0 unless msec
      base ||= now_msec
      format('%.3f', (base - msec).to_f / 1000)
    end

    def elps_date(msec, base = now_msec)
      return 0 unless msec
      sec = (base - msec).to_f / 1000
      interval(sec)
    end

    def interval(sec)
      return format('%.1f days', sec / 86_400) if sec > 86_400
      if sec > 3600
        fmt = '%H:%M'
      elsif sec > 60
        fmt = "%M'%S\""
      else
        fmt = '%S"%L'
      end
      Time.at(sec).utc.strftime(fmt)
    end

    def date(msec)
      Time.at(msec.to_f / 1000).inspect
    end

    def today
      Time.now.strftime('%Y%m%d')
    end
  end
end
