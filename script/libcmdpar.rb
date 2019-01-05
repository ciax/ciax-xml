#!/usr/bin/ruby
require 'libhashx'
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
      attr_reader :list
      def initialize(hash = {})
        super
        @list = (self[:list] ||= [])
      end

      def valid_pars
        self[:type] == 'str' ? get(:list) : []
      end

      def validate(str)
        list = get(:list)
        csv = a2csv(list)
        return ___use_default(csv) unless str
        return method('_val_' + get(:type)).call(str, list, csv) if list
        __get_default || str
      end

      def def_par(str = nil)
        self[:default] = str || valid_pars.first
      end

      private

      def __get_default
        return unless key?(:default)
        df = get(:default)
        return df if df && valid_pars.include?(df)
        delete(:default)
        nil
      end

      def ___use_default(csv)
        df = __get_default
        raise ParShortage, csv unless df
        verbose { "Validate: Using default value [#{df}]" }
        df
      end

      def _val_num(str, list, csv)
        num = expr(str)
        verbose { "Validate: [#{num}] Match? [#{csv}]" }
        return num.to_s if list.any? { |r| ReRange.new(r) == num }
        par_err("Out of range (#{num}) for [#{csv}]")
      end

      def _val_reg(str, list, csv)
        verbose { "Validate: [#{str}] Match? [#{csv}]" }
        return str if list.any? { |r| Regexp.new(r).match(str) }
        par_err("Parameter Invalid Reg (#{str}) for [#{csv}]")
      end

      def _val_str(str, list, csv)
        verbose { "Validate: [#{str}] Match? [#{csv}]" }
        return str if list.include?(str)
        par_err("Parameter Invalid Str (#{str}) for [#{csv}]")
      end
    end
  end
end
