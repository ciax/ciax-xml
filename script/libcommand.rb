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
#  Item#def_proc -> Proc
#
# Group => {id => Item}
#  Group#list -> CmdList.to_s
#  Group#add_item(id,title){|id,par|} -> Item
#  Group#update_items(list){|id|}
#  Group#valid_keys -> Array
#  Group#def_proc -> Proc
#
# Domain => {id => Group}
#  Domain#list -> String
#  Domain#add_group(key,title) -> Group
#  Domain#def_proc -> Proc
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
      self['sv']['hid']['interrupt'].def_proc=type?(p,Proc)
    end

    def domain_with_item(id)
      values.any?{|dom|
        return dom if dom.group_with_item(id)
      }
    end

    def valid_keys
      res=[]
      values.each{|dom|
        dom.values.each{|grp|
          res+=grp.valid_keys
        }
      }
      res
    end
  end

  class Domain < ExHash
    attr_reader :def_proc
    def initialize(color=2)
      @def_proc=Proc.new{}
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
      self[gid]=Group.new(attr,@def_proc)
    end

    def add_dummy(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => 1}
      self[gid]=BasicGroup.new(attr)
    end

    def def_proc=(dp)
      @def_proc=type?(dp,Proc)
      values.each{|v|
        v.def_proc=dp
      }
      dp
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
        return grp if grp.key?(id)
      }
    end
  end

  class BasicGroup < ExHash # No parameter
    attr_reader :valid_keys,:cmdlist,:def_proc
    #attr = {caption,color,column,:members}
    def initialize(attr,def_proc=Proc.new{})
      @attr=type?(attr,Hash)
      @valid_keys=[]
      @cmdlist=CmdList.new(@attr,@valid_keys)
      @def_proc=type?(def_proc,Proc)
      @ver_color=3
    end

    def add_item(id,title)
      @cmdlist[id]=title
      self
    end

    def update_items(labels)
      labels.each{|k,v|
        @cmdlist[k]=v
      }
      self
    end

    def setcmd(cmd)
      type?(cmd,Array)
      id,*par=cmd
      key?(id) || raise(InvalidCMD,list)
      @valid_keys.include?(id) || raise(InvalidCMD,list)
      verbose("CmdGrp","SetCMD (#{id},#{par})")
      self[id].set_par(par)
    end

    def list
      @cmdlist.to_s
    end
  end

  class Group < BasicGroup
    def add_item(id,title=nil,parameter=nil)
      super(id,title)
      item=self[id]=Item.new(id,@def_proc)
      property={:label => title}
      property[:parameter] = parameter if parameter
      item.update(property)
      item
    end

    def update_items(labels)
      labels.each{|id,title|
        @cmdlist[id]=title
        self[id]=Item.new(id,@def_proc)
      }
      self
    end

    def def_proc=(dp)
      @def_proc=type?(dp,Proc)
      values.each{|v|
        v.def_proc=dp
      }
      dp
    end
  end

  class Item < ExHash
    include Math
    attr_reader :id,:par,:cmd
    attr_accessor :def_proc
    def initialize(id,def_proc=Proc.new{})
      @id=id
      @par=[]
      @cmd=[]
      @def_proc=type?(def_proc,Proc)
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@cmd}")
      @def_proc.call(self)
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
