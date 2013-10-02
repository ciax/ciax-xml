#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'librerange'
require 'liblogging'

#Access method
# Entity => {:label,:args}
#  Entity#exe
#
# Item => {:label,:parameter,:body,:args}
#  Item#set_par(par) -> Entity
#  Item#cfg -> {:def_proc}
#
# Group => {id => Item}
#  Group#list -> CmdList.to_s
#  Group#cfg -> {:def_proc}
#  Group#add_item(id,title){|id,par|} -> Item
#  Group#update_items(list){|id|}
#  Group#valid_keys -> Array
#
# Domain => {id => Group}
#  Domain#list -> String
#  Domain#cfg -> {:def_proc}
#  Domain#add_group(key,title) -> Group
#  Domain#item(id) -> Item
#
# Command => {id => Domain}
#  Command#list -> String
#  Command#current -> Item
#  Command#setcmd(args=[id,*par]):{
#    Item#set_par(par)
#    Command#current -> Item
#  } -> Item
# Keep current command and parameters

module CIAX
  class Comshare < Hashx
    attr_reader :cfg
    def initialize(upper=Config.new,crnt={},&def_proc)
      @cfg=Config.new(upper).update(crnt)
      set_proc(&def_proc)
      @list=[] # For ordering
    end

    def set_proc(&def_proc)
      @cfg[:def_proc]=def_proc if def_proc
      self
    end

    def valid_keys
      values.map{|e|
        e.valid_keys
      }.flatten
    end
  end

  class Command < Comshare
    # CDB: mandatory (:body)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    def initialize
      super(Config.new,{:command => self}){}
      # Server Commands (service commands on Server)
      sv=self['sv']=Domain.new(@cfg,{'color' => 2})
      sv.add_group('hid',{'caption'=>"Hidden Group"}).add_item('interrupt')
      # Local(Long Jump) Commands (local handling commands on Client)
      sl=self['lo']=Domain.new(@cfg,{'color' => 2})
    end

    def setcmd(args)
      type?(args,Array)
      id,*par=args
      dom=domain_with_item(id) || raise(InvalidCMD,list)
      dom.setcmd(args)
    end

    def int_proc=(p)
      self['sv']['hid']['interrupt'].cfg[:def_proc]=type?(p,Proc)
    end

    def list
      values.map{|dom| dom.list}.grep(/./).join("\n")
    end

    def domain_with_item(id)
      values.any?{|dom|
        return dom if dom.group_with_item(id)
      }
    end
  end

  class Domain < Comshare
    def initialize(upper=Config.new,crnt={},&def_proc)
      super
      @cfg[:domain]=self
      @grplist=[] # For ordering
      @ver_color=2
    end

    def update(h)
      h.values.each{|v| @grplist.unshift type?(v,Group)}
      super
    end

    def []=(gid,grp)
      @grplist.unshift grp
      super
    end

    def add_group(gid,par={},cls=Group,&def_proc)
      self[gid]=cls.new(@cfg,par,&def_proc)
    end

    def setcmd(args)
      type?(args,Array)
      id,*par=args
      grp=group_with_item(id) || raise(InvalidCMD,list)
      grp.setcmd(args)
    end

    def list
      @grplist.map{|grp| grp.list}.grep(/./).join("\n")
    end

    def group_with_item(id)
      values.any?{|grp|
        return grp if grp.valid_keys.include?(id)
      }
    end
  end

  class Group < Comshare
    attr_reader :valid_keys,:cmdlist
    #upper = {caption,color,column}
    def initialize(upper=Config.new,crnt={},&def_proc)
      super
      @cfg[:group]=self
      @valid_keys=[]
      @cmdlist=CmdList.new(@cfg,@valid_keys)
      @cmdary=[@cmdlist]
      @ver_color=3
    end

    def setcmd(args)
      id,*par=type?(args,Array)
      @valid_keys.include?(id) || raise(InvalidCMD,list)
      verbose("CmdGrp","SetCMD (#{id},#{par})")
      self[id].set_par(par)
    end

    def list
      @cmdary.join("\n")
    end

    def add_item(id,title=nil,parameter=nil,&def_proc)
      @cmdlist[id]=title
      cfg={:id => id,:label => title}
      cfg[:parameter] = parameter if parameter
      self[id]=new_item(cfg,&def_proc)
    end

    def update_items(labels)
      type?(labels,Hash)
      labels.each{|id,title|
        @cmdlist[id]=title
        self[id]=new_item({:id => id})
      }
      self
    end

    def add_dummy(id,title)
      @cmdlist.dummy(id,title) #never put into valid_key
      self
    end

    def new_item(crnt,&def_proc)
      Item.new(@cfg,crnt,&def_proc)
    end
  end

  class Item < Comshare
    include Math
    #set should have :def_proc
    def initialize(upper=Config.new,crnt={},&def_proc)
      super
      @cfg[:item]=self
      @id=@cfg[:id]
      @ver_color=5
    end

    def set_par(par)
      @par=validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@id}): #{par}")
      new_entity({:par => par})
    end

    def new_entity(crnt)
      Entity.new(@cfg,crnt)
    end

    private
    # Parameter structure [{:type,:list,:default}, ...]
    def validate(pary)
      pary=type?(pary.dup,Array)
      return [] unless @cfg[:parameter]
      @cfg[:parameter].map{|par|
        list=par[:list]||[]
        disp=list.join(',')
        unless str=pary.shift
          if par.key?(:default)
            next par[:default]
          else
            Msg.par_err(
                        "Parameter shortage (#{pary.size}/#{@cfg[:parameter].size})",
                        Msg.item(@id,@cfg[:label]),
                        " "*10+"key=(#{disp})")
          end
        end
        case par[:type]
        when 'num'
          begin
            num=eval(str)
          rescue Exception
            Msg.par_err("Parameter is not number")
          end
          verbose("CmdItem","Validate: [#{num}] Match? [#{disp}]")
          unless list.empty? || list.any?{|r| ReRange.new(r) == num }
            Msg.par_err("Out of range (#{num}) for [#{disp}]")
          end
          num.to_s
        when 'str'
          verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
          unless list.empty? || list.include?(str)
            Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
          end
          str
        when 'reg'
          verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
          unless list.empty? || list.any?{|r| /#{r}/ === str}
            Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
          end
          str
        end
      }
    end
  end

  class Entity < Hashx
    attr_reader :id,:par,:args,:cfg
    #set should have :def_proc
    def initialize(upper,crnt)
      @cfg=Config.new(upper).update(crnt)
      @id=@cfg[:id]
      @par=@cfg[:par]
      @args=[@id,*@par]
      @cfg[:cid]=@args.join(':') # Used by macro
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@args}")
      @cfg[:def_proc].call(self)
      self
    end
  end
end
