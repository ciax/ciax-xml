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
#  Group#add_item(id,title) -> Item
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
#  Command#setcmd(args=[id,*par]):{
#    Item#set_par(par)
#  } -> Item
# Keep current command and parameters

module CIAX
  class Itemshare < Hashx
    attr_reader :cfg
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:def_proc]||=proc{}
    end

    def set_proc(&def_proc)
      @cfg[:def_proc]=type?(def_proc,Proc)
      self
    end
  end

  class Grpshare < Itemshare
    def add(id,chld)
      type?(chld,Class)
      ele=chld.new(@cfg)
      ele.cfg[:id]=id
      self[id]=ele
    end

    def join(id,ele)
      ele.cfg.override(@cfg)
      self[id]=ele
    end

    def valid_keys
      values.map{|e|
        e.valid_keys
      }.flatten
    end

    def setcmd(args)
      type?(args,Array)
      id,*par=args
      valid_keys.include?(id) || raise(InvalidCMD,list)
      @cfg.index[id].set_par(par)
    end

    def list
      values.map{|e| e.list}.grep(/./).join("\n")
    end
  end

  class Command < Grpshare
    # CDB: mandatory (:body)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    def initialize(upper,crnt={})
      super
      # Server Commands (service commands on Server)
      @cfg.update('color'=>2,'column'=>2)
      add('sv')
    end

    def add(id,cls=Domain)
      super
    end

    def interrupt(&interrupt)
      self['sv'].add_group('hid',{'caption' => "Hidden Group"}).add_item('interrupt')
    end
  end

  class Domain < Grpshare
    def initialize(upper,crnt={})
      super
      @ver_color=2
    end

    def add(id,cls=Group)
      super
    end

    def add_group(id,crnt={})
      grp=add(id)
      grp.cfg.update(crnt)
      grp
    end
  end

  class Group < Grpshare
    attr_reader :valid_keys,:cmdlist
    #upper = {caption,color,column}
    def initialize(upper=Config.new,crnt={})
      super
      @valid_keys=[]
      @cmdlist=CmdList.new(@cfg,@valid_keys)
      @cmdary=[@cmdlist]
      @ver_color=3
    end

    def add(id,cls=Item)
      @cfg.index[id]=super
    end

    def list
      @cmdary.join("\n")
    end

    def add_item(id,crnt={})
      item=add(id,Item)
      item.cfg.update(crnt)
      @cmdlist[id]=crnt[:label]
      item
    end

    def update_items(labels,cls=Item)
      type?(labels,Hash)
      labels.each{|id,title|
            @cmdlist[id]=title
            add(id,cls)
          }
      self
    end

    def add_dummy(id,title)
      @cmdlist.dummy(id,title) #never put into valid_key
      self
    end
  end

  class Item < Itemshare
    include Math
    #cfg should have :label,:parameter,:def_proc
    def initialize(upper,crnt={})
      super
      @ver_color=5
    end

    def set_par(par,cls=Entity)
      validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@cfg[:id]}): #{par}")
      cls.new(@cfg,{:par => par})
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
            mary=[]
            mary << "Parameter shortage (#{pary.size}/#{@cfg[:parameter].size})"
            mary << Msg.item(@cfg[:id],@cfg[:label])
            mary << " "*10+"key=(#{disp})"
            Msg.par_err(*mary)
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
    def initialize(upper,crnt={})
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
