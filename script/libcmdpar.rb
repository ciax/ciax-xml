#!/usr/bin/env ruby
require 'libhashx'
require 'librerange'
module CIAX
  # Command Module
  module CmdBase
    # Parameter Array
    class ParArray < Arrayx
      def initialize(obj = 0, val = '.')
        case obj
        when Array
          super(obj.map { |e| Parameter.new(e) })
        when Numeric
          super(obj) { Parameter.new(type: 'reg', list: [val]) }
        else
          super
        end
      end

      def valid_pars
        map { |p| p.get(:list) }.flatten
      end

      def validate(ary)
        type?(ary, Array)
        map { |p| p.validate(ary.shift) }
      end

      ## Refernce Parameter Setting
      # returns Reference Parameter Array
      def add_enum(list, default = nil)
        push Parameter.new(type: 'str', list: type?(list, Array))
        last[:default] = default if default && list.include?(default)
        self
      end

      def add_reg(str, default = nil)
        push Parameter.new(type: 'reg', list: [str])
        last[:default] = default if default && Regexp.new(str).match(default)
        self
      end

      # Parameter for numbers
      def add_num(default = nil)
        add_reg('^[0-9]+$', default)
      end
    end

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

      def validate(str)
        list = get(:list)
        csv = a2csv(list)
        return ___use_default(csv) unless str
        return method('_val_' + get(:type)).call(str, list, csv) if list
        __get_default || str
      end

      def def_par(str = nil)
        self[:default] = str || get(:list).first
      end

      private

      def ___chk_default
        return unless key?(:default)
        df = get(:default)
        df || delete(:default)
      end

      def ___chk_def_str(df)
        return df if self[:type] != 'str'
        get(:list).include?(df)
      end

      def ___chk_def_reg(df)
        return df if self[:type] != 'reg'
        get(:list).any? do |r|
          Regexp.new(r).match(df)
        end
      end

      def __get_default
        df = ___chk_default
        return df if ___chk_def_str(df) && ___chk_def_reg(df)
        delete(:default)
        false
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
