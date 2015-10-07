#!/usr/bin/ruby
require 'libitem'
require 'libdisp'

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
      @displist = Disp::List.new(@cfg, @valid_keys)
      @cfg['color'] ||= 2
      @cfg['column'] ||= 2
    end

    def add_item(id, title = nil, crnt = {})
      crnt['label'] = current[id] = title
      new_item(id, crnt)
    end

    def del_item(id)
      @valid_keys.delete(id)
      current.delete(id)
      delete(id)
    end

    def clear_item
      @valid_keys.clear
      @displist.clear
      clear
    end

    def merge_items(displist)
      type?(displist, Disp::List).each do|cg|
        cg.each do|id, title|
          new_item(id, { 'label' => title })
        end
      end
      @current = @displist.merge!(displist).last
      self
    end

    def add_dummy(id, title)
      current.dummy(id, title) # never put into valid_key
      self
    end

    def valid_reset
      @valid_keys.concat(keys).uniq!
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

    def current
      @current ||= @displist.new_grp
    end
  end
end
