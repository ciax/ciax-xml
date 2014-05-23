#!/usr/bin/ruby
require 'libenumx'
require 'libconf'
require 'libcmdlist'
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

  class Command < Arrayx
    # CDB: mandatory (:body)
    # optional (:label,:parameters)
    # optionalfrm (:nocache,:response)
    include AryShare
    attr_reader :svdom,:lodom,:hidgrp
    def initialize(upper=nil)
      @cfg=Config.new('command',upper)
      @cfg.update('color'=>2,'column'=>2)
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
    def initialize(upper,attr={})
      @cfg=Config.new('domain',upper).update(attr)
      @ver_color=2
    end

    def join_group(group)
      unshift type?(group,Group)
      group.cfg.override(@cfg)
      group
    end

    def add_group(attr={})
      unshift (attr[:group_class]||Group).new(@cfg,attr)
      first
    end
  end

  class Group < Hashx
    include HshShare
    attr_reader :valid_keys,:cfg
    #upper keys: caption,color,column
    def initialize(upper,attr)
      @cfg=Config.new('group',upper).update(attr)
      @cfg[:item_class]||=Item
      @valid_keys=@cfg[:valid_keys]||[]
      @cmdary=[CmdList.new(@cfg,@valid_keys)]
      @ver_color=3
    end

    def add_item(id,title=nil,crnt={})
      crnt[:id]=id
      crnt[:label]=title
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

    def valid_pars
      values.map{|e| e.valid_pars}.flatten
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
    #cfg should have :id,:label,:parameters,:def_proc
    def initialize(upper,attr={})
      @cfg=Config.new('item',upper).update(attr)
      @cfg[:entity_class]||=Entity
      @ver_color=5
    end

    def set_par(par,opt={})
      opt[:par]=validate(type?(par,Array))
      verbose(self.class,"SetPAR(#{@cfg[:id]}): #{par}")
      @cfg[:entity_class].new(@cfg,opt)
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
            verbose("CmdItem","Validate: [#{num}] Match? [#{disp}]")
            unless list.any?{|r| ReRange.new(r) == num }
              Msg.par_err("Out of range (#{num}) for [#{disp}]")
            end
            next num.to_s
          when 'reg'
            verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
            unless list.any?{|r| /#{r}/ === str}
              Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
            end
          else
            verbose("CmdItem","Validate: [#{str}] Match? [#{disp}]")
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
    attr_reader :id,:par,:cfg
    #set should have :def_proc
    def initialize(upper,attr={})
      @cfg=Config.new('entity',upper).update(attr)
      @par=@cfg[:par]
      @id=[@cfg[:id],*@par].join(':')
      @cfg[:cid]=@id
      @ver_color=5
      verbose(self.class,"Config #{@cfg.inspect}")
    end

    def exe
      verbose(self.class,"Execute #{@id}")
      @cfg[:def_proc].call(self)
    end
  end
end
