#!/usr/bin/env ruby
require 'libcmdform'
require 'libdispgrp'
# CIAX-XML
module CIAX
  module CmdBase
    # Command Group
    class Group < Hashx
      include CmdFunc
      attr_reader :valid_keys
      # cfg keys: caption,color,column
      def initialize(spcfg, atrb = Hashx.new)
        super()
        @cfg = spcfg.gen(self).update(atrb)
        datr = @cfg.pick(:caption, :color, :column, :line_number)
        @disp_dic = Disp::Index.new(datr)
        @cfg[:disp] = @disp_dic
        @valid_keys = @disp_dic.valid_keys
        rank(ENV['RANK'].to_i)
      end

      def add_dummy(id, title = nil) # returns Display
        @disp_dic.put_item(id, title)
      end

      # atrb could be dbi[:index][id]
      # atrb could have 'label',:body,'unit','group'
      def add_form(id, title = nil, atrb = Hashx.new) # returns Form
        return self[id] if key?(id)
        @disp_dic.put_item(id, title)
        _new_form(id, atrb)
      end

      def del_form(id)
        @disp_dic.delete(id)
        delete(id)
      end

      def clear_form
        @disp_dic.clear
        clear
      end

      def merge_forms(disp_dic)
        @disp_dic.merge_sub(disp_dic)
        disp_dic.keys.each { |id| _new_form(id) }
        self
      end

      def valid_reset
        @disp_dic.index.reset!
        self
      end

      # Subtract ary from full keys from valid_keys
      def valid_sub(ary)
        @valid_keys.replace(keys - type?(ary, Array))
        verbose do
          "(#{@cfg[:id]}) valid_keys " +
            (ary.empty? ? 'restored' : "subtracted with #{ary.inspect}")
        end
        self
      end

      def valid_pars
        values.map(&:valid_pars).flatten
      end

      def view_dic
        @disp_dic.to_s
      end

      def rank(n)
        @disp_dic.rank = n
        self
      end

      def rankup
        @disp_dic.rank = @disp_dic.rank + 1
        self
      end

      private

      # atrb can be /cdb//index[id] which contains [:parameter] and so on
      def _new_form(id, atrb = Hashx.new)
        self[id] = context_module('Form').new(@cfg, atrb.update(id: id))
      end
    end
  end
end
