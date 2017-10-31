#!/usr/bin/ruby
require 'libmsgdbg'
# Common Module
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    ## class name handling

    # All classes copy under the module
    def deep_include(dmod, smod)
      const_defined?(dmod.to_s) || module_eval("module #{dmod};end")
      smod.constants.each do |con|
        ssub = const_get("#{smod}::#{con}")
        dsub = "#{dmod}::#{con}"
        if ssub.is_a?(Class)
          class_eval("class #{dsub} < #{ssub.name};end")
        elsif ssub.is_a?(Module)
          deep_include(dsub, ssub)
        end
      end
    end

    # Full path class name in same namespace
    def context_module(name, mod = nil)
      type?(name, String)
      mod ||= self.class
      mary = mod.to_s.split('::')
      chk_module(mary, name)
    end

    def chk_module(mary, name)
      cpath = (mary + [name]).join('::')
      return CIAX.const_get(cpath)
    rescue NameError
      mary.pop || give_up("No such constant #{name}")
      retry
    end

    def layer_module
      CIAX.const_get self.class.name.split('::')[1]
    end

    def layer_name
      class_path[1].downcase
    end

    def class_path
      self.class.to_s.split('::')
    end

    def m2id(mod, pos = -1)
      mod.name.split('::')[pos].downcase
    end
  end
end
