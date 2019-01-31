#!/usr/bin/env ruby
require 'libmsgerr'
# Common Module
module CIAX
  ### Debug Methods ###
  module Msg
    module_function

    # For Debug
    def _w(var, str = '') # watch var for debug
      clr = ':' + caller(1).first.split('/').last
      res = if var.is_a?(Enumerable)
              colorize(str, 5) + clr + ___prt_enum(var)
            else
              colorize(var, 5) + clr
            end
      show res
    end

    def ___prt_enum(var)
      res = colorize("(#{var.object_id})", 3)
      res << var.dup.extend(Enumx).path
    end

    # Assertion
    def type?(name, *modules)
      src = caller(1)
      return name if modules.any? { |mod| name.is_a?(mod) }
      res = 'Parameter type error '
      res << format('<%s>> for %s at %s', name.class, modules, src.first)
      raise(ServerError, res, src)
    end

    def data_type?(data, type)
      return data if data['type'] == type
      data_err("Data type error <#{name.class}> for (#{mod})")
    end

    # Temporary condition test
    def good(str = '')
      show("Good for #{str}")
      true
    end

    def bad(str = '')
      show("Bad for #{str}")
      false
    end
  end
end
