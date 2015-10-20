#!/usr/bin/ruby
# Common Module
require 'fileutils'
require 'libmsgdbg'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    def expr(str)
      cfg_err("Expression is empty") unless str
      num = eval(str)
      type?(num, Numeric)
    end

    def esc_code(str)
      return unless str
      eval('"' + str + '"')
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
