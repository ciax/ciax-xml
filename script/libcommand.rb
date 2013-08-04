#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method
#
# Item => {:label,:parameter,:select,:cmd}
#  Item#set_par(par)
#  Item#procs -> {:def_proc}
#
# Group => {id => Item}
#  Group#list -> CmdList.to_s
#  Group#procs -> {:def_proc}
#  Group#add_item(id,title){|id,par|} -> Item
#  Group#update_items(list){|id|}
#  Group#valid_keys -> Array
#
# Domain => {id => Group}
#  Domain#list -> String
#  Domain#procs -> {:def_proc}
#  Domain#add_group(key,title) -> Group
#  Domain#item(id) -> Item
#
#
# Command => {id => Domain}
#  Command#list -> String
#  Command#current -> Item
#  Command#setcmd(cmd=[id,*par]):{
#    Item#set_par(par)
#    Command#current -> Item
#  } -> Item
# Keep current command and parameters

module CIAX
  class ProcAry < Array
    def [](id)
      each{|prcs|
        return prcs[id] if prcs.key?(id)
      }
      Proc.new
    end
  end

  class Command < ExHash
    # CDB: mandatory (:select)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    def initialize
      # Server Commands (service commands on Server)
      sv=self['sv']=Domain.new(2)
      sv.add_group('hid',"Hidden Group").add_item('interrupt')
      sv.add_group('int','Internal Commands')
      # Local(Long Jump) Commands (local handling commands on Client)
      self['lo']=Domain.new(9)
    end

    def setcmd(cmd)
      type?(cmd,Array)
      id,*par=cmd
      dom=domain_with_item(id) || raise(InvalidCMD,list)
      dom.setcmd(cmd)
    end

    def list
      values.map{|dom| dom.list}.grep(/./).join("\n")
    end

    def int_proc=(p)
      self['sv']['hid']['interrupt'].procs[:def_proc]=type?(p,Proc)
    end

    def domain_with_item(id)
      values.any?{|dom|
        return dom if dom.group_with_item(id)
      }
    end
  end

  class Domain < ExHash
    attr_reader :procs
    def initialize(color=2)
      @procs={}
      @grplist=[]
      @color=color
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

    def add_group(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => @color}
      self[gid]=Group.new(attr,[@procs])
    end

    def add_dummy(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => 1}
      self[gid]=Group.new(attr)
    end

    def setcmd(cmd)
      type?(cmd,Array)
      id,*par=cmd
      grp=group_with_item(id) || raise(InvalidCMD,list)
      grp.setcmd(cmd)
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

  class Group < ExHash
    attr_reader :valid_keys,:cmdlist,:procs
    #attr = {caption,color,column,:members}
    def initialize(attr,procary=[])
      @attr=type?(attr,Hash)
      @valid_keys=[]
      @cmdlist=CmdList.new(@attr,@valid_keys)
      @procs={}
      @procary=[@procs]+type?(procary,Array)
      @ver_color=3
    end

    def setcmd(cmd)
      id,*par=type?(cmd,Array)
      @valid_keys.include?(id) || raise(InvalidCMD,list)
      verbose("CmdGrp","SetCMD (#{id},#{par})")
      self[id].set_par(par)
    end

    def list
      @cmdlist.to_s
    end

    def add_item(id,title=nil,parameter=nil)
      @cmdlist[id]=title
      item=self[id]=Item.new(id,@procary)
      property={:label => title}
      property[:parameter] = parameter if parameter
      item.update(property)
      item
    end

    def update_items(labels)
      labels.each{|id,title|
        @cmdlist[id]=title
        self[id]=Item.new(id,@procary)
      }
      self
    end
  end

  class Item < ExHash
    include Math
    attr_reader :id,:par,:cmd,:procs
    #procs should have :def_proc
    def initialize(id,procary=[])
      @id=id
      @par=[]
      @cmd=[]
      @procs={}
      @procary=ProcAry.new([@procs]+type?(procary,Array))
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@cmd}")
      @procary[:def_proc].call(self)
      self
    end

    def set_par(par)
      @par=validate(type?(par,Array))
      @cmd=[@id,*par]
      self[:cmd]=@cmd.join(':') # Used by macro
      verbose(self.class,"SetPAR(#{@id}): #{par}")
      self
    end

    private
    # Parameter structure {:type,:val}
    def validate(pary)
      pary=type?(pary.dup,Array)
      return pary unless self[:parameter]
      self[:parameter].map{|par|
        disp=par[:list].join(',')
        unless str=pary.shift
        Msg.par_err(
                "Parameter shortage (#{pary.size}/#{self[:parameter].size})",
                Msg.item(@id,self[:label]),
                " "*10+"key=(#{disp})")
        end
        case par[:type]
        when 'num'
          begin
            num=eval(str)
          rescue Exception
            Msg.par_err("Parameter is not number")
          end
          verbose("CmdItem","Validate: [#{num}] Match? [#{disp}]")
          unless par[:list].any?{|r| ReRange.new(r) == num }
            Msg.par_err("Out of range (#{num}) for [#{disp}]")
          end
          num.to_s
        when 'str'
          verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
          unless par[:list].include?(str)
            Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
          end
          str
        when 'reg'
          verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
          unless par[:list].any?{|r| /#{r}/ === str}
            Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
          end
          str
        end
      }
    end
  end
end
