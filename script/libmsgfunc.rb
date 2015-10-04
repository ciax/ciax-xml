#!/usr/bin/ruby
# Common Module
require 'fileutils'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
