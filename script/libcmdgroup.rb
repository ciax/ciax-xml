#!/usr/bin/ruby
require 'libcmditem'
require 'libdispgrp'
# CIAX-XML
module CIAX
  module CmdBase
    # Command Group
    class Group < Hashx
      include CmdFunc
      attr_reader :valid_keys
      # cfg keys: caption,color,column
      def initialize(super_cfg, atrb = Hashx.new)
        super()
        @cfg = super_cfg.gen(self).update(atrb)
        @displist = Disp.new(@cfg.pick(%i(caption color column line_number)))
        @cfg[:disp] = @displist
        @valid_keys = @displist.valid_keys
        rank(ENV['RANK'].to_i)
      end

      def add_dummy(id, title = nil) # returns Display
        @displist.put_item(id, title)
      end

      # atrb could be dbi[:index][id]
      # atrb could have 'label',:body,'unit','group'
      def add_item(id, title = nil, atrb = Hashx.new) # returns Item
        return self[id] if key?(id)
        @displist.put_item(id, title)
        _new_item(id, atrb)
      end

      def del_item(id)
        @displist.delete(id)
        delete(id)
      end

      def clear_item
        @displist.clear
        clear
      end

      def merge_items(displist)
        @displist.merge_sub(displist)
        displist.keys.each { |id| _new_item(id) }
        self
      end

      def valid_reset
        @displist.index.reset!
        self
      end

      def valid_sub(ary)
        @valid_keys.replace(keys - type?(ary, Array))
        self
      end

      def valid_pars
        values.map(&:valid_pars).flatten
      end

      def view_list
        @displist.to_s
      end

      def rank(n)
        @displist.rank = n
        self
      end

      def rankup
        @displist.rank = @displist.rank + 1
        self
      end

      private

      # atrb can be /cdb//index[id] which contains [:parameter] and so on
      def _new_item(id, atrb = Hashx.new)
        self[id] = context_module('Item').new(@cfg, atrb.update(id: id))
      end
    end
  end
end
