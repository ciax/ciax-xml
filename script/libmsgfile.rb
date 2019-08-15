#!/usr/bin/env ruby
# File input module
require 'libmsgfunc'
require 'fileutils'
module CIAX
  ### File related ###
  module Msg
    #  Used for initial reading to get id
    def pre_read
      return {} if STDIN.tty?
      jstr = gets(nil)
      jstr ? @preload = j2h(jstr) : {}
    end

    # OK for bad file
    #  Used for jverify() input
    def jload(fname)
      return j2h(loadfile(fname)) unless (res = @preload)
      verbose { 'Loading from Preloading' }
      @preload = nil
      res
    rescue InvalidData
      show_err
      Hashx.new
    end

    module_function

    # Json read with contents conversion
    # Invalid json str including nil gives error
    def jread
      unless jstr
        data_err("No data in file(#{ARGV})") unless (jstr = gets(nil))
        show('Getting Data from STDIN')
      end
      j2h(jstr)
    end

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
      return unless chkfile(fname)
      File.open(fname) do |f|
        verbose { "Loading file [#{fname}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        f.read
      end
    rescue Errno::ENOENT
      verbose { "  -- no json file (#{fname})" }
      nil
    end

    # Check file
    def chkfile(fname)
      data_err("Cant read (#{fname})") unless test('r', fname)
      return true if test('s', fname)
      warning('File empty (%s)', fname)
      File.unlink(fname)
      nil
    end
  end
end
