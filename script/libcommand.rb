#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'librerange'
require 'liblogging'

module CIAX
  module GrpShare
    def set_proc(&def_proc)
      @cfg[:def_proc]=type?(def_proc,Proc)
      self
    end

    def item_proc(id,&def_proc)
      get_item(id).set_proc(&def_proc)
    end

    def setcmd(args)
      id,*par=type?(args,Array)
      get_item(id).set_par(par)
    end

    private
    def get_item(id)
      valid_keys.include?(id) || raise(InvalidCMD,list)
      @cfg.index[id]
    end
  end

  class Command < Hashx
    include GrpShare
    # CDB: mandatory (:body)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    def initialize(upper)
      @cfg=Config.new(upper)
      @cfg.update('color'=>2,'column'=>2)
      @cfg[:def_proc]||=proc{}
      # Server Commands (service commands on Server)
      self['sv']=Domain.new(@cfg)
      self['lo']=Domain.new(@cfg)
    end

    def interrupt
      self['sv'].add_group('caption' => "Hidden Group").add_item('interrupt')
    end

    def valid_keys
      values.map{|e|
        e.valid_keys
      }.flatten
    end

    def list
      values.map{|e| e.list}.grep(/./).join("\n")
    end
  end

  class Domain < Arrayx
    include GrpShare
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @ver_color=2
    end

    def join_group(group)
      unshift type?(group,Group)
      group.cfg.override(@cfg)
      group
    end

    def add_group(crnt={})
      unshift (crnt[:group_class]||Group).new(@cfg,crnt)
      last
    end

    def valid_keys
      map{|e| e.valid_keys}.flatten
    end

    def list
      map{|e| e.list}.grep(/./).join("\n")
    end
  end

  class Group < Hashx
    include GrpShare
    attr_reader :valid_keys,:cmdlist,:cfg
    #upper = {caption,color,column}
    def initialize(upper=Config.new,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:item_class]||=Item
      @valid_keys=[]
      @cmdlist=CmdList.new(@cfg,@valid_keys)
      @cmdary=[@cmdlist]
      @ver_color=3
    end

    def add_item(id,crnt={})
      crnt[:id]=id
      @cmdlist[id]=crnt[:label]
      self[id]=@cfg.index[id]=@cfg[:item_class].new(@cfg,crnt)
    end

    def update_items(labels)
      type?(labels,Hash).each{|id,label|
        add_item(id,{:label => label})
      }
      self
    end

    def add_dummy(id,title)
      @cmdlist.dummy(id,title) #never put into valid_key
      self
    end

    def list
      @cmdary.join("\n")
    end
  end

  class Item < Hashx
    include Math
    #cfg should have :id,:label,:parameter,:def_proc
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:entity_class]||=Entity
      @ver_color=5
    end

    def set_proc(&def_proc)
      @cfg[:def_proc]=type?(def_proc,Proc)
      self
    end

    def set_par(par)
      validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@cfg[:id]}): #{par}")
      @cfg[:entity_class].new(@cfg,{:par => par})
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
