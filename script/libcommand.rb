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
  class Command < Hashx
    attr_reader :cfg
    # CDB: mandatory (:body)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    def initialize
      @cfg=Config.new({:command => self})
      # Server Commands (service commands on Server)
      sv=self['sv']=Domain.new(@cfg,{'color' => 2})
      sv.add_group('hid',"Hidden Group").add_item('interrupt')
      sv.add_group('int','Internal Commands')
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

    def valid_keys
      values.map{|dom|
        dom.valid_keys
      }.flatten
    end

    def domain_with_item(id)
      values.any?{|dom|
        return dom if dom.group_with_item(id)
      }
    end
  end

  class Domain < Hashx
    attr_reader :cfg
    def initialize(upper=Config.new,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:domain]=self
      @cfg[:def_proc]=proc{}
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

    def add_group(gid,caption,column=nil,color=nil)
      grp=Group.new(@cfg)
      grp.cfg['caption']=caption
      grp.cfg['column']=column||2
      grp.cfg['color']=color if color
      self[gid]=grp
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

    def valid_keys
      values.map{|grp|
        grp.valid_keys
      }.flatten
    end

    def group_with_item(id)
      values.any?{|grp|
        return grp if grp.valid_keys.include?(id)
      }
    end
  end

  class Group < Hashx
    attr_reader :valid_keys,:cmdlist,:cfg
    #upper = {caption,color,column}
    def initialize(upper=Config.new,crnt={})
      @valid_keys=[]
      @cfg=Config.new(upper).update(crnt)
      @cfg[:group]=self
      @cmdlist=CmdList.new(@cfg,@valid_keys)
      @ver_color=3
    end

    def setcmd(args)
      id,*par=type?(args,Array)
      @valid_keys.include?(id) || raise(InvalidCMD,list)
      verbose("CmdGrp","SetCMD (#{id},#{par})")
      self[id].set_par(par)
    end

    def list
      @cmdlist.to_s
    end

    def add_item(id,title=nil,parameter=nil)
      @cmdlist[id]=title
      item=self[id]=Item.new(@cfg,{:id => id})
      item[:label]= title
      item[:parameter] = parameter if parameter
      item
    end

    def update_items(labels)
      type?(labels,Hash)
      labels.each{|id,title|
        @cmdlist[id]=title
        self[id]=Item.new(@cfg,{:id => id})
      }
      self
    end

    def add_dummy(id,title)
      @cmdlist.dummy(id,title) #never put into valid_key
      self
    end
  end

  class Item < Hashx
    include Math
    attr_reader :cfg
    #set should have :def_proc
    def initialize(upper=Config.new,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:item]=self
      @id=@cfg[:id]
      @ver_color=5
    end

    def set_par(par)
      @par=validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@id}): #{par}")
      Entity.new(@cfg,{:par => par})
    end

    private
    # Parameter structure [{:type,:list,:default}, ...]
    def validate(pary)
      pary=type?(pary.dup,Array)
      return [] unless self[:parameter]
      self[:parameter].map{|par|
        list=par[:list]||[]
        disp=list.join(',')
        unless str=pary.shift
          if par.key?(:default)
            next par[:default]
          else
            Msg.par_err(
                        "Parameter shortage (#{pary.size}/#{self[:parameter].size})",
                        Msg.item(@id,self[:label]),
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
    def initialize(upper=Config.new,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @id=@cfg[:id]
      @par=@cfg[:par]
      @args=[@id,*@par]
      self[:cid]=@args.join(':') # Used by macro
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@args}")
      @cfg[:def_proc].call(self)
      self
    end
  end
end
