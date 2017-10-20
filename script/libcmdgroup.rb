#!/usr/bin/ruby
require 'libcmditem'
require 'libdispgrp'
# CIAX-XML
module CIAX
  module Cmd
    # Dummy Command Group
    class Dummy < Hashx
      include CmdProc
      attr_reader :valid_keys
      # cfg keys: caption,color,column
      def initialize(cfg, atrb = Hashx.new)
        super()
        @cfg = cfg.gen(self).update(atrb)
        @displist = Disp.new(@cfg.pick(%i(caption color column line_number)))
        @cfg[:disp] = @displist
        @valid_keys = @displist.valid_keys
        @displist.rank = ENV['RANK'].to_i
      end

      # crnt could have 'label',:body,'unit','group'
      def add_dummy(id, title = nil) # returns Display
        @displist.put_item(id, title)
      end

      def add_item(id, title = nil, atrb = Hashx.new) # returns Item
        @displist.put_item(id, title)
        @valid_keys << id
        self[id] = Item.new(@cfg, atrb.update(id: id))
      end

      # Generate Entity
      def set_cmd(args, opt = {})
        id, *par = type?(args, Array)
        @displist.valid?(id) || com_err(view_list)
        get(id).set_par(par, opt)
      end

      def view_list
        @displist.to_s
      end

      def valid_pars; end
    end

    # Command Group
    class Group < Dummy
      # cfg keys: caption,color,column
      def initialize(cfg, atrb = Hashx.new)
        super
      end

      # atrb could have 'label',:body,'unit','group'
      def add_item(id, title = nil, atrb = Hashx.new) # returns Item
        @displist.put_item(id, title)
        new_item(id, atrb)
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
        displist.keys.each { |id| new_item(id) }
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

      private

      def new_item(id, atrb = {})
        # atrb could be dbi[:index][id]
        atrb[:id] = id
        self[id] = context_constant('Item').new(@cfg, atrb)
      end
    end
  end
end
