#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'librerange'
require 'liblogging'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module HshShare
    def set_proc(&def_proc)
      @cfg[:def_proc]=type?(def_proc,Proc)
      self
    end
  end

  module AryShare
    include HshShare
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

    def par_list
      map{|e| e.par_list}.flatten
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

  class Command < Arrayx
    # CDB: mandatory (:body)
    # optional (:label,:parameter)
    # optionalfrm (:nocache,:response)
    include AryShare
    attr_reader :svdom,:lodom,:hidgrp
    def initialize(upper)
      @cfg=Config.new(upper)
      @cfg.update(:level =>'command','color'=>2,'column'=>2)
      @cfg[:def_proc]||=proc{''}
      # Server Commands (service commands on Server)
      push @svdom=Domain.new(@cfg,{:domain_id => 'remote'}) # Remote Command Domain
      push @lodom=Domain.new(@cfg,{:domain_id => 'local'}) # Local Command Domain
      @hidgrp=@svdom.add_group('caption' => "Hidden Commands",:group_id => 'hidden')
      @hidgrp.add_item('interrupt')
    end
  end

  class Domain < Arrayx
    include AryShare
    #upper keys: def_proc,group_class,item_class,entity_class
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:level]='domain'
      @ver_color=2
    end

    def join_group(group)
      unshift type?(group,Group)
      group.cfg.override(@cfg)
      group
    end

    def add_group(crnt={})
      unshift (crnt[:group_class]||Group).new(@cfg,crnt)
      first
    end
  end

  class Group < Hashx
    include HshShare
    attr_reader :valid_keys,:cfg
    #upper keys: caption,color,column
    def initialize(upper=Config.new,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:level]='group'
      @cfg[:item_class]||=Item
      @valid_keys=@cfg[:valid_keys]||[]
      @cmdary=[CmdList.new(@cfg,@valid_keys)]
      @ver_color=3
    end

    def add_item(id,title=nil,crnt={})
      crnt[:id]=id
      @cmdary.last[id]=title
      self[id]=@cfg[:item_class].new(@cfg,crnt)
    end

    def update_items(labels)
      type?(labels,Hash).each{|id,title|
        add_item(id,title)
      }
      self
    end

    def add_dummy(id,title)
      @cmdary.last.dummy(id,title) #never put into valid_key
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
      @cmdary.map{|l| l.to_s}.grep(/./).join("\n")
    end

    def par_list
      values.map{|e| e.par_list}.flatten
    end   

    def get_item(id)
      self[id]
    end
  end

  # Corresponds commands
  class Item < Hashx
    include HshShare
    include Math
    attr_reader :cfg
    #cfg should have :id,:label,:parameter,:def_proc
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:level]='item'
      @cfg[:entity_class]||=Entity
      @ver_color=5
    end

    def set_par(par,opt={})
      opt[:par]=validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@cfg[:id]}): #{par}")
      @cfg[:entity_class].new(@cfg,opt)
    end

    def par_list
      (@cfg[:parameter]||[]).map{|e| e[:list] if e[:type] == 'str'}.flatten
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

  # Command db with parameter derived from Item
  class Entity < Hashx
    attr_reader :id,:par,:cfg
    #set should have :def_proc
    def initialize(upper,crnt={})
      @cfg=Config.new(upper).update(crnt)
      @cfg[:level]='entity'
      @par=@cfg[:par]
      @id=[@cfg[:id],*@par].join(':')
      @cfg[:cid]=@id
      @ver_color=5
    end

    def exe
      verbose(self.class,"Execute #{@id}")
      @cfg[:def_proc].call(self)
    end
  end
end
