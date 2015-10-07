#!/usr/bin/ruby
# Common Module
require 'libdefine'
require 'fileutils'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    def xmlfiles(type)
      Dir.glob("#{SCRIPT_DIR}/../#{type}-*.xml")
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
