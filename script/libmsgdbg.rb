#!/usr/bin/ruby
require 'libmsgerr'
# Common Module
module CIAX
  ### Debug Methods ###
  module Msg
    module_function

    # For Debug
    def _w(var, str = '') # watch var for debug
      clr = ':' + caller(1).first.split('/').last
      if var.is_a?(Enumerable)
        res = color(str, 5) + clr + _prt_enum(var)
      else
        res = color(var, 5) + clr
      end
      warn res
    end

    def _prt_enum(var)
      res = color("(#{var.object_id})", 3)
      res << var.dup.extend(Enumx).path
    end

    # Assertion
    def type?(name, *modules)
      src = caller(1)
      modules.each do|mod|
        unless name.is_a?(mod)
          res = "Parameter type error <#{name.class}> for (#{mod})"
          fail(ServerError, res, src)
        end
      end
      name
    end

    def data_type?(data, type)
      return data if data['type'] == type
      fail "Data type error <#{name.class}> for (#{mod})"
    end
  end
end
