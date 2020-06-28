#!/usr/bin/env ruby
require 'libmsgerr'
# Common Module
module CIAX
  ### Debug Methods ###
  module Msg
    module_function

    # Watch var for debug
    #  example in block
    #  { var.inspect if condition }
    def _w(name, &take_value)
      return unless take_value && (var = yield)
      show cfmt('%:5s:%s(%:3s) = %p', 'Debug', name, var.object_id, var)
      show caller(1).to_s
    end

    # Assertion
    def type?(name, *modules)
      src = caller(1)
      return name if modules.any? { |mod| name.is_a?(mod) }
      res = 'Parameter type error '
      res << format('<%s>> for %s at %s', name.class, modules, src.first)
      raise(ServerError, res, src)
    end

    # Checking for extension order (File should be after Conv)
    # modules should be String or Symbol
    def not_type?(name, *modules)
      src = caller(1)
      return name unless modules.any? do |mod|
        const_defined?(mod) && name.is_a?(const_get(mod))
      end
      res = 'Wrong extension order of module '
      res << format('<%s>> for %s at %s', name.class, modules, src.first)
      raise(ServerError, res, src)
    end

    def last_caller
      "'" + caller(2..2).first.split('`').last
    end

    def data_type?(data, type)
      return data if data['type'] == type
      data_err("Data type error <#{name.class}> for (#{mod})")
    end

    # Temporary condition test
    #  Put on both branch
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
