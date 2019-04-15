#!/usr/bin/env ruby
require 'libmsgdbg'
# Add deep_include to Module
class Module
  # All classes copy under the module
  def deep_include(smod, dmod = self)
    ___alt_const_defined?(dmod.to_s) || __fmt_eval('module %s;end', dmod)
    smod.constants.each do |con|
      ___classify(*[smod, dmod].map { |s| format('%s::%s', s, con) })
    end
  end

  private

  # For Ruby 2.0 or older (use const_defined? for 2.1 or later)
  def ___alt_const_defined?(modstr)
    const_get(modstr)
  rescue NameError
    false
  end

  def ___classify(sname, dname)
    case (ssub = const_get(sname))
    when Class
      __fmt_eval('class %s < %s;end', dname, sname)
    when Module
      deep_include(ssub, dname)
    else
      __fmt_eval('%s = %s', dname, sname)
    end
  end

  def __fmt_eval(*par)
    module_eval(format(*par))
  end
end

# Common Module
module CIAX
  ### Checking Methods ###
  module Msg
    def base_class
      class_path.last(2).join('::')
    end

    def layer_name
      class_path[1].downcase
    end

    module_function

    ## Extend by inherited module
    def ext_mod(name)
      mod = context_module(name)
      return self if is_a?(mod)
      yield extend(mod)
    end

    ## class name handling
    # Full path class name in same namespace
    def context_module(name, mod = nil)
      name = name.to_s
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

    def class_path
      self.class.to_s.split('::')
    end

    def m2id(mod, pos = -1)
      mod.name.split('::')[pos].downcase
    end

    # Module extend order check
    def bad_order(name, *mods)
      if mods.any? { |mod| name.is_a?(mod) }
        sv_err("Bad ext order #{name} -> #{class_path.last}")
      else
        name
      end
    end

    def type_gen(obj, mod)
      obj = yield mod if !obj && defined? yield
      type?(obj, mod)
    end
  end
end
