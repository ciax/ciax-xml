#!/usr/bin/ruby
require 'libenumx'
require 'librerange'
module CIAX
  # Command Module
  module CmdBase
    # Parameter commands
    class ParArray < Arrayx
      # Parameter for validate(cfg[:parameters])
      #   structure:  [{:type,:list,:default}, ...]
      # *Empty parameter will replaced to :default
      # *Error if str doesn't match with strings listed in :list
      # *If no :list, returns :default
      # Returns converted parameter array
      def valid_pars
        map do |e|
          e[:list] if e[:type] == 'str'
        end.flatten
      end

      def validate(pary, psize)
        psize = type?(pary, Array).size
        map do |pref|
          next ___use_default(pref, psize) unless (str = pary.shift)
          line = pref[:list]
          next method('_val_' + pref[:type]).call(str, line) if line
          pref.key?(:default) ? pref[:default] : str
        end
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

      def ___use_default(pref, psize)
        if pref.key?(:default)
          verbose { "Validate: Using default value [#{pref[:default]}]" }
          pref[:default]
        else
          ___err_shortage(pref, psize)
        end
      end

      def ___err_shortage(pref, psize)
        frac = format('(%d/%d)', psize, @cfg[:parameters].size)
        mary = ['Parameter shortage ' + frac]
        mary << @cfg[:disp].item(@id)
        mary << ' ' * 10 + "key=(#{a2csv(pref[:list])})"
        par_err(*mary)
      end
    end
  end
end
