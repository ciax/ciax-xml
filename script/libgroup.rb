#!/usr/bin/ruby
require 'libitem'
require 'libdisplay'

module CIAX
  class Group < Hashx
    include CmdProc
    attr_reader :valid_keys
    # dom_cfg keys: caption,color,column
    def initialize(cfg, attr = {})
      super()
      @cls_color = 3
      @cfg = cfg.gen(self).update(attr)
      @valid_keys = @cfg[:valid_keys] || []
      @displist = Display.new(@cfg, @valid_keys)
      @cfg['color'] ||= 2
      @cfg['column'] ||= 2
    end

    # crnt could have 'label',:body,'unit','group'
    def add_item(id, title = nil, crnt = {})
      crnt['label'] = subgrp[id] = title
      new_item(id, crnt)
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
      @displist.merge_group!(type?(displist, Display))
      self
    end

    def add_dummy(id, title)
      @displist[id]=title # never put into valid_key
      self
    end

    def valid_reset
      @displist.reset!
      self
    end

    def valid_sub(ary)
      @valid_keys.replace(keys - type?(ary, Array))
      self
    end

    def view_list
      @displist.to_s
    end

    def valid_pars
      values.map(&:valid_pars).flatten
    end

    def set_cmd(args, opt = {})
      id, *par = type?(args, Array)
      @valid_keys.include?(id) || fail(InvalidCMD, view_list)
      get(id).set_par(par, opt)
    end

    private

    def new_item(id, crnt = {})
      crnt[:id] = id
      self[id] = context_constant('Item').new(@cfg, crnt)
    end
  end
end
