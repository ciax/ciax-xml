#!/usr/bin/ruby
require 'libitem'
require 'libdisp'

module CIAX
  class Dummy < Hashx
    include CmdProc
    attr_reader :valid_keys
    # cfg keys: caption,color,column
    def initialize(cfg, atrb = {})
      super()
      @cls_color = 3
      @cfg = cfg.gen(self).update(atrb)
      @displist = Disp.new(@cfg.pick(:caption, :color, :column, :line_number))
      @valid_keys = @displist.valid_keys
    end

    # crnt could have 'label',:body,'unit','group'
    def add_item(id, title = nil, crnt = {})
      @displist.put_item(id, title)
    end

    def valid_pars; end

    def view_list
      @displist.to_s
    end
  end

  class Group < Dummy
    # cfg keys: caption,color,column
    def initialize(cfg, atrb = {})
      super
      @displist.put_grp
    end

    # crnt could have 'label',:body,'unit','group'
    def add_item(id, title = nil, crnt = {})
      super
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
      @displist.merge_sub(type?(displist, Disp))
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

    # Generate Entity
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
