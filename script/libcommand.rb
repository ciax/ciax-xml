#!/usr/bin/ruby
require 'libcmdary'
require 'libcmdlist'
require 'librerange'
require 'liblogging'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  class Command < CmdAry
    # CDB: mandatory (:body)
    # optional ('label',:parameters)
    # optionalfrm (:nocache,:response)
    attr_reader :rem,:loc,:hidgrp
    def initialize(exe_cfg=nil,attr={})
      # Add exe_cfg to @generation as ancestor, add attr to self
      # @cfg is isolated from exe_cfg
      # So it is same meaning to set value to 'attr' and @cfg
      @cfg=Config.new('command',exe_cfg).update(attr)
      @cfg[:def_proc]||=proc{''}
      @cls_color=@cfg[:cls_color]||7
      @pfx_color=@cfg[:pfx_color]||2
      # Server Commands (service commands on Server)
      push @rem=Domain.new(@cfg,{:domain_id => 'remote'}) # Remote Command Domain
      push @loc=Domain.new(@cfg,{:domain_id => 'local'}) # Local Command Domain
      @hidgrp=@rem.add_group('caption' => "Hidden Commands",:group_id => 'hidden')
      @hidgrp.add_item('interrupt')
    end

    def add_nil
      # Accept empty command
      @hidgrp.add_item(nil)
      self
    end
  end

  class Domain < CmdAry
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
    attr_reader :cfg,:valid_keys
    #dom_cfg keys: caption,color,column
    def initialize(dom_cfg,attr={})
      super()
      @cfg=Config.new('group',dom_cfg).update(attr)
      @valid_keys=@cfg[:valid_keys]||[]
      @cls_color=@cfg[:cls_color]
      @pfx_color=@cfg[:pfx_color]
      @cmdlist=CmdList.new(@cfg,@valid_keys)
      @cfg['color']||=2
      @cfg['column']||=2
    end

    def add_item(id,title=nil,crnt={})
      crnt['clabel']=current[id]=title
      new_item(id,crnt)
    end

    def del_item(id)
      @valid_keys.delete(id)
      current.delete(id)
      delete(id)
    end

    def merge_items(cmdlist)
      type?(cmdlist,CmdList).each{|cg|
        cg.each{|id,title|
          new_item(id,{'clabel'=> title})
        }
      }
      @current=@cmdlist.merge!(cmdlist).last
      self
    end

    def add_dummy(id,title)
      current.dummy(id,title) #never put into valid_key
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

    def view_list
      @cmdlist.to_s
    end

    def valid_pars
      values.map{|e| e.valid_pars}.flatten
    end

    def get_item(id)
      self[id]
    end

    private
    def new_item(id,crnt={})
      crnt[:id]=id
      self[id]=add('Item',crnt)
    end

    def current
      @current||=@cmdlist.new_grp
    end
  end

  # Corresponds commands
  class Item < Hashx
    include SetProc
    attr_reader :cfg
    #grp_cfg should have :id,'label',:parameters,:def_proc
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
          mary << Msg.item(@cfg[:id],@cfg['label'])
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
            unless list.any?{|r| Regexp.new(r) === str}
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
  class Entity
    include Msg
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
