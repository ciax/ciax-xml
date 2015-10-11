#!/usr/bin/ruby
require 'libmsgdbg'
# Common Module
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    ## class name handling
    # Full path class name in same namespace
    def context_constant(name, mod = nil)
      type?(name, String)
      mod ||= self.class
      mary = mod.to_s.split('::')
      mary.size.times do
        cpath = (mary + [name]).join('::')
        begin
          return CIAX.const_get(cpath)
        rescue NameError
          mary.pop
        end
      end
      give_up("No such constant #{name}")
    end

    def layer_module
      CIAX.const_get self.class.name.split('::')[1]
    end

    def class_path
      self.class.to_s.split('::')[1..-1]
    end

    def m2id(mod, pos = -1)
      mod.name.split('::')[pos].downcase
    end
  end
end
