#!/usr/bin/env ruby
# File input module
require 'libmsgfunc'
require 'fileutils'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    ## File related ##

    def xmlfiles(type)
      Dir.glob("#{__dir__}/../#{type}-*.xml").map { |f| File.absolute_path(f) }
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end

    # File feature
    def loadfile(fname)
      data_err("Cant read (#{fname})") unless test('r', fname)
      warning('File empty (%s)', fname) unless test('s', fname)
      File.open(fname) do |f|
        verbose { "Loading file [#{fname}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        f.read
      end
    rescue Errno::ENOENT
      verbose { "  -- no json file (#{fname})" }
    end

    # Json read with contents conversion
    def jread(jstr = nil)
      return j2h(jstr) if jstr
      data_err("No data in file(#{ARGV})") unless (jstr = gets(nil))
      show('Getting Data from STDIN')
      j2h(jstr)
    end

    # OK for bad file
    def jload(fname)
      jread(loadfile(fname))
    rescue InvalidData
      show_err
      Hashx.new
    end
  end
end
