#!/usr/bin/ruby
require 'libenumx'
require 'librerange'
module CIAX
  # Command Module
  module CmdBase
    # Parameter commands
    class Parameter < Hashx
      # Parameter for validate (element of cfg[:parameters]#Array)
      #   structure:  {:type,:list,:default}
      # *Empty parameter will replaced to :default
      # *Error if str doesn't match with strings listed in :list
      # *If no :list, override input with :default
      # Returns converted parameter array
      #
      # input | :list | in :list? | :default | output
      #   o   |   x   |    -      |    x     | input
      #   o   |   o   |    o      |    *     | input
      #   o   |   o   |    x      |    *     | error
      #   x   |   *   |    -      |    o     | :default
      #   *   |   x   |    -      |    o     | :default
      def valid_pars
        e[:type] == 'str' ? e[:list] : []
      end

      def validate(str)
        return ___use_default unless str
        list = get(:list)
        return method('_val_' + get(:type)).call(str, list) if list
        key?(:default) ? get(:default) : str
      end

      private

      def _val_num(str, list)
        num = expr(str)
        verbose { "Validate: [#{num}] Match? [#{a2csv(list)}]" }
        return num.to_s if list.any? { |r| ReRange.new(r) == num }
        par_err("Out of range (#{num}) for [#{a2csv(list)}]")
      end

      def _val_reg(str, list)
        verbose { "Validate: [#{str}] Match? [#{a2csv(list)}]" }
        return str if list.any? { |r| Regexp.new(r).match(str) }
        par_err("Parameter Invalid Reg (#{str}) for [#{a2csv(list)}]")
      end

      def _val_str(str, list)
        verbose { "Validate: [#{str}] Match? [#{a2csv(list)}]" }
        return str if list.include?(str)
        par_err("Parameter Invalid Str (#{str}) for [#{a2csv(list)}]")
      end

      def ___use_default
        raise ParShortage unless key?(:default)
        verbose { "Validate: Using default value [#{get(:default)}]" }
        get(:default)
      end
    end
  end
end
