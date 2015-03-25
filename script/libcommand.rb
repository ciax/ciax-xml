#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'libcmdlist'
require 'librerange'
require 'liblogging'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module SetProc
    # Add element which belongs a group enclosed with module (name space= Frm,App,..)
    # Need to be set key[:mod] for module in config or attributes
    # class name(String) + module val
    def add(class_name,attr={})
      local_class(class_name,attr[:mod]||@cfg[:mod]).new(@cfg,attr)
    end

    # Proc should return String
    def set_proc(&def_proc)
      @cfg[:def_proc]=type?(def_proc,Proc)
      self
    end
  end

  class CmdShare < Arrayx
    include SetProc
    def get_item(id)
      res=nil
      any?{|e| res=e.get_item(id)}
      res
    end

    def item_proc(id,&def_proc)
      get_item(id).set_proc(&def_proc)
    end

    def valid_keys
      map{|e| e.valid_keys}.flatten
    end

    def set_cmd(args,opt={})
      id,*par=type?(args,Array)
      valid_keys.include?(id) || raise(InvalidCMD,list)
      get_item(id).set_par(par,opt)
    end

    def valid_pars
      map{|e| e.valid_pars}.flatten
    end

    def list
      map{|e| e.list}.grep(/./).join("\n")
    end

    def show_proc(id)
      item=get_item(id)
      cfg=item.cfg
      cls=cfg.generation[cfg.level(:def_proc)][:level]
      " #{id},level=#{cls},item=#{item.object_id},proc=#{cfg[:def_proc].object_id}"
    end
  end

  class Command < CmdShare
    # CDB: mandatory (:body)
    # optional (:label,:parameters,:mod)
    # optionalfrm (:nocache,:response)
    attr_reader :svdom,:lodom,:hidgrp
    def initialize(exe_cfg=nil,attr={})
      @cfg=Config.new('command',exe_cfg).update(attr)
      @cfg.update('color'=>2,'column'=>2)
      @cfg[:def_proc]||=proc{''}
      @cls_color=@cfg[:cls_color]||7
      @pfx_color=@cfg[:pfx_color]||2
      # Server Commands (service commands on Server)
      push @svdom=Domain.new(@cfg,{:domain_id => 'remote'}) # Remote Command Domain
      push @lodom=Domain.new(@cfg,{:domain_id => 'local'}) # Local Command Domain
      @hidgrp=@svdom.add_group('caption' => "Hidden Commands",:group_id => 'hidden')
      @hidgrp.add_item('interrupt')
    end

    def add_nil
      # Accept empty command
      @hidgrp.add_item(nil)
      self
    end
  end

  class Domain < CmdShare
    #cmd_cfg keys: def_proc,group_class,item_class,entity_class
    def initialize(cmd_cfg,attr={})
      @cfg=Config.new('domain',cmd_cfg).update(attr)
      @cls_color=@cfg[:cls_color]
      @pfx_color=@cfg[:pfx_color]
    end

    def join_group(group)
      unshift type?(group,Group)
      group.cfg.override(@cfg)
      group
    end

    def add_group(attr={})
      unshift add('Group',attr)
      first
    end
  end

  class Group < Hashx
    include SetProc
    attr_reader :valid_keys,:cfg
    #dom_cfg keys: caption,color,column
    def initialize(dom_cfg,attr={})
      super()
      @cfg=Config.new('group',dom_cfg).update(attr)
      @valid_keys=@cfg[:valid_keys]||[]
      @cls_color=@cfg[:cls_color]
      @pfx_color=@cfg[:pfx_color]
      @cmdlist=CmdGrps.new(@valid_keys)
      @current=@cmdlist.add_grp(@cfg)
    end

    def add_item(id,title=nil,crnt={})
      crnt[:id]=id
      crnt[:label]=title
      @current[id]=title
      self[id]=add('Item',crnt)
    end

    def del_item(id)
      @valid_keys.delete(id)
      @current.delete(id)
      delete(id)
    end

    def update_items(labels)
      type?(labels,Hash).each{|id,title|
        add_item(id,title)
      }
      self
    end

    def update_lists(cmdlist)
      @cmdlist.concat(type?(cmdlist,CmdGrps))
      self
    end

    def add_dummy(id,title)
      @current.dummy(id,title) #never put into valid_key
      self
    end

    def valid_reset
      @valid_keys.concat(keys).uniq!
      self
    end

    def valid_sub(ary)
      @valid_keys.replace(keys-type?(ary,Array))
      self
    end

    def list
      @cmdlist.to_s
    end

    def valid_pars
      values.map{|e| e.valid_pars}.flatten
    end

    def get_item(id)
      self[id]
    end
  end

  # Corresponds commands
  class Item < Hashx
    include SetProc
    include Math
    attr_reader :cfg
    #grp_cfg should have :id,:label,:parameters,:def_proc
    def initialize(grp_cfg,attr={})
      super()
      @cfg=Config.new('item',grp_cfg).update(attr)
      @cls_color=@cfg[:cls_color]
      @pfx_color=@cfg[:pfx_color]
    end

    def set_par(par,opt={})
      opt[:par]=validate(type?(par,Array))
      verbose("Cmd","SetPAR(#{@cfg[:id]}): #{par}")
      add('Entity',opt)
    end

    def valid_pars
      (@cfg[:parameters]||[]).map{|e| e[:list] if e[:type] == 'str'}.flatten
    end

    private
    # Parameter for validate(cfg[:paremeters]) structure:  [{:type,:list,:default}, ...]
    # Returns converted parameter array
    def validate(pary)
      pary=type?(pary.dup,Array)
      return [] unless @cfg[:parameters]
      @cfg[:parameters].map{|par|
        list=par[:list]||[]
        disp=list.join(',')
        unless str=pary.shift
          next par[:default] if par.key?(:default)
          mary=[]
          mary << "Parameter shortage (#{pary.size}/#{@cfg[:parameters].size})"
          mary << Msg.item(@cfg[:id],@cfg[:label])
          mary << " "*10+"key=(#{disp})"
          Msg.par_err(*mary)
        end
        if list.empty?
          next par[:default] if par.key?(:default)
        else
          case par[:type]
          when 'num'
            begin
              num=eval(str)
            rescue Exception
              Msg.par_err("Parameter is not number")
            end
            verbose("Cmd","Validate: [#{num}] Match? [#{disp}]")
            unless list.any?{|r| ReRange.new(r) == num }
              Msg.par_err("Out of range (#{num}) for [#{disp}]")
            end
            next num.to_s
          when 'reg'
            verbose("Cmd","Validate: [#{str}] Match? [#{disp}]")
            unless list.any?{|r| /#{r}/ === str}
              Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
            end
          else
            verbose("Cmd","Validate: [#{str}] Match? [#{disp}]")
            unless list.include?(str)
              Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
            end
          end
        end
        str
      }
    end
  end

  # Command db with parameter derived from Item
  class Entity < Hashx
    attr_reader :id,:par,:cfg,:layer
    #set should have :def_proc
    def initialize(itm_cfg,attr={})
      super()
      @cfg=Config.new('entity',itm_cfg).update(attr)
      @par=@cfg[:par]
      @id=[@cfg[:id],*@par].join(':')
      @cfg[:cid]=@id
      @cls_color=@cfg[:cls_color]
      @pfx_color=@cfg[:pfx_color]
      @layer=@cfg['layer']
      verbose("Cmd","Config",@cfg.inspect)
      verbose("self",inspect)
    end

    # returns result of def_proc block (String)
    def exe_cmd(src,pri=1)
      verbose("Cmd","Execute [#{@id}] from #{src}")
      @cfg[:def_proc].call(self,src,pri)
    end
  end
end
