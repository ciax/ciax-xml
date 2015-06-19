#!/usr/bin/ruby
require 'libenumx'
require 'libconf'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module AddElem
    # Add element which belongs a group enclosed with module (name space= Frm,App,..)
    # Need to be set key[:mod] for module in config or attributes
    # class name(String) + module val
    def add(class_name,attr={})
      context_class(class_name,attr[:mod]||@cfg[:mod]).new(@cfg,attr)
    end
  end

  class CmdAry < Arrayx
    include AddElem
    def get_item(id)
      res=nil
      any?{|e| res=e.get_item(id)}
      res
    end

    def item_proc(id,&def_proc)
      get_item(id).cfg.proc(&def_proc)
    end

    def valid_keys
      map{|e| e.valid_keys}.flatten
    end

    def set_cmd(args,opt={})
      id,*par=type?(args,Array)
      valid_keys.include?(id) || raise(InvalidCMD,view_list)
      get_item(id).set_par(par,opt)
    end

    def valid_pars
      map{|e| e.valid_pars}.flatten
    end

    def view_list
      map{|e| e.view_list}.grep(/./).join("\n")
    end

    def show_proc(id)
      item=get_item(id)
      cfg=item.cfg
      cls=cfg.generation[cfg.level(:def_proc)][:level]
      " #{id},level=#{cls},item=#{item.object_id},proc=#{cfg[:def_proc].object_id}"
    end
  end
end
