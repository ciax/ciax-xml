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

    def elps_sec(msec, target = nil)
      return 0 unless msec
      target ||= now_msec
      format('%.3f', (target - msec).to_f / 1000)
    end

    def elps_date(msec, target = now_msec)
      return 0 unless msec
      sec = (target - msec).to_f / 1000
      interval(sec)
    end

    def interval(sec)
      return format('%.1f days', sec / 86_400) if sec > 86_400
      fmt = if sec > 3600
              '%H:%M'
            elsif sec > 60
              "%M'%S\""
            else
              '%S"%L'
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
