#!/usr/bin/ruby
# Common Module
require 'libmsgdbg'
require 'fileutils'
require 'json'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    def expr(str)
      num = str ? eval(str) : 0
      type?(num, Numeric)
    end

    def esc_code(str)
      return unless str
      eval('"' + str + '"')
    end

    def j2h(json_str = nil)
      JSON.parse(json_str)
    rescue JSON::ParserError
      usr_err('NOT JSON')
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    def xmlfiles(type)
      Dir.glob("#{__dir__}/../#{type}-*.xml")
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
