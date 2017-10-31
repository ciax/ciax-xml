#!/usr/bin/ruby
require 'libmsgdbg'
# Add deep_include to Module
class Module
  # All classes copy under the module
  def deep_include(smod, dmod = self)
    const_defined?(dmod.to_s) || _fmt_eval('module %s;end', dmod)
    smod.constants.each do |con|
      _classify_(*[smod, dmod].map { |s| format('%s::%s', s, con) })
    end
  end

  private

  def _classify_(sname, dname)
    case (ssub = const_get(sname))
    when Class
      _fmt_eval('class %s < %s;end', dname, sname)
    when Module
      deep_include(ssub, dname)
    else
      _fmt_eval('%s = %s', dname, sname)
    end
  end

  def _fmt_eval(*par)
    module_eval(format(*par))
  end
end

# Common Module
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    ## class name handling
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
