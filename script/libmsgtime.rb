#!/usr/bin/env ruby
require 'libmsgfmt'
# Common Module
module CIAX
  ### Time Format Methods ###
  module Msg
    module_function

    def now_msec
      (Time.now.to_f * 1000).to_i
    end

    def elps_sec(base_msec, later_msec = nil)
      return 0 unless base_msec
      later_msec ||= now_msec
      format('%.3f', (later_msec - base_msec).to_f / 1000)
    end

    def elps_date(base_msec, later_msec = now_msec)
      return 0 unless base_msec
      sec = (later_msec - base_msec).to_f / 1000
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
  # Show Elapsed time
  class Elapsed
    include Msg
    def initialize(stat)
      @base = stat
    end

    def to_s
      elps_date(@base[:time])
    end
  end
end
