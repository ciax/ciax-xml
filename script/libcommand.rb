#!/usr/bin/ruby
require 'libenumx'
require 'libmsg'
require 'librerange'
require 'liblogging'

#Access method
#
# Item => {:label,:parameter,:select,:args}
#  Item#set_par(par)
#  Item#share -> {:def_proc}
#
# Group => {id => Item}
#  Group#list -> CmdList.to_s
#  Group#share -> {:def_proc}
#  Group#add_item(id,title){|id,par|} -> Item
#  Group#update_items(list){|id|}
#  Group#valid_keys -> Array
#
# Domain => {id => Group}
#  Domain#list -> String
#  Domain#share -> {:def_proc}
#  Domain#add_group(key,title) -> Group
#  Domain#item(id) -> Item
#
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
  # Array of Share(Hash): each Hash is associated with Domain,Group,Item;
  # Usage:Setting/ provide @share(Share) and add to ShareAry at each Level, value setting should be done to the @share;
  # Usage:Getting/ simply get form ShareAry, not from @share;
  class Share < Hash
    private :[]
  end

  class ShareAry < Array
    private :[]=

    def [](id)
      each{|lv|
        return lv.fetch(id) if lv.key?(id)
      }
      Msg.warn("No such key in ShareAry [#{id}]")
      nil
    end
  end

  class Command < Hashx
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

    def setcmd(args)
      type?(args,Array)
      id,*par=args
      dom=domain_with_item(id) || raise(InvalidCMD,list)
      dom.setcmd(args)
    end

    def int_proc=(p)
      self['sv']['hid']['interrupt'].share[:def_proc]=type?(p,Proc)
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
    attr_reader :share
    def initialize(color=2)
      @share=Share.new
      @share[:def_proc]=proc{}
      @grplist=[] # For ordering
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

    def add_group(gid,caption,column=2,color=@color)
      attr={'caption' => caption,'column' => column,'color' => color}
      self[gid]=Group.new(attr,[@share])
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
    attr_reader :valid_keys,:cmdlist,:share
    #attr = {caption,color,column,:members}
    def initialize(attr,upper=[])
      @attr=type?(attr,Hash)
      @valid_keys=[]
      @cmdlist=CmdList.new(@attr,@valid_keys)
      @share=Share.new
      @shary=ShareAry.new([@share]+type?(upper,Array))
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
      item=self[id]=Item.new(id,@shary)
      item[:label]= title
      item[:parameter] = parameter if parameter
      item
    end

    def update_items(labels)
      type?(labels,Hash)
      labels.each{|id,title|
        @cmdlist[id]=title
        self[id]=Item.new(id,@shary)
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
    attr_reader :id,:par,:args,:share,:shary
    #share should have :def_proc
    def initialize(id,upper=[])
      @id=id
      @par=[]
      @args=[]
      @share=Share.new
      @shary=ShareAry.new([@share]+type?(upper,Array))
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@args}")
      @shary[:def_proc].call(self)
      self
    end

    def set_par(par)
      @par=validate(type?(par,Array))
      @args=[@id,*@par]
      self[:cid]=@args.join(':') # Used by macro
      verbose(self.class,"SetPAR(#{@id}): #{@par}")
      self
    end

    private
    # Parameter structure [{:type,:list,:default}, ...]
    def validate(pary)
      pary=type?(pary.dup,Array)
      return pary unless self[:parameter]
      self[:parameter].map{|par|
        disp=par[:list].join(',')
        unless str=pary.shift||par[:default]
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
