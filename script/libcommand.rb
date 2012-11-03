#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method
#Command < Hash
# Command::Group => {id => Command::Item}
#  Command::Group#list -> Msg::CmdList.to_s
#  Command::Group#add_item(id,title){|id,par|} -> Command::Item
#  Command::Group#update_items(list){|id|}
#  Command::Group#def_proc ->[{|item|},..]
#
# Command::Domain => {id => Command::Item}
#  Command::Domain#list -> String
#  Command::Domain#add_group(key,title) -> Command::Group
#  Command::Domain#group[key] -> Command::Group
#  Command::Domain#list -> String
#  Command::Domain#def_proc ->[{|item|},..]
#
# Command#new(db) => {id => Command::Item}
#  Command#list -> String
#  Command#add_domain(key,title) -> Command::Domain
#  Command#domain[key] -> Command::Domain
#   Command#int -> Command::Domain['int']
#  Command#current -> Command::Item
#  Command#def_proc ->[{|item|},..]
#  Command#set(cmd=id+par):{
#    Command[id]#set_par(par)
#    Command#current -> Command[id]
#  } -> Command::Item
# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :current,:domain,:def_proc
  # CDB: mandatory (:select)
  # optional (:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize
    Command.init_ver(self)
    @current=nil
    @domain={}
    @def_proc=[]
  end

  def add_domain(id,color=2)
    @domain[id]=Domain.new(self,color,@def_proc)
  end

  def set(cmd)
    id,*par=cmd
    key?(id) || error
    @current=self[id].set_par(par)
  end

  def list
    @domain.values.reverse.map{|dom| dom.list}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+list)
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
  end

  class Domain < Hash
    attr_reader :group,:def_proc
    def initialize(index,color=2,def_proc=[])
      @index=Msg.type?(index,Command)
      @group={}
      @color=color
      @def_proc=Msg.type?(def_proc,Array)
    end

    def add_group(gid,caption)
      attr={"caption" => caption,"column" => 2,"color" => @color}
      @group[gid]=Group.new(@index,attr,@def_proc)
    end

    def init_proc(&p)
      values.each{|v|
        v.init_proc(&p)
      }
      self
    end

    def list
      @group.values.map{|grp| grp.list.to_s}.grep(/./).join("\n")
    end
  end

  class Group < Hash
    attr_reader :list,:def_proc
    def initialize(index,attr,def_proc=[])
      Msg.type?(attr,Hash)
      @list=Msg::CmdList.new(attr)
      @index=Msg.type?(index,Command)
      @def_proc=Msg.type?(def_proc,Array)
    end

    def add_item(id,title=nil,parameter=nil)
      @list[id]=title
      item=@index[id]=self[id]=Item.new(id,@index,@def_proc)
      property={:label => title}
      property[:parameter] = parameter if parameter
      self[id].update(property)
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(labels,ary=nil)
      ary||=labels.keys
      ary.each{|id|
        @list[id]=labels[id]
        self[id]=Item.new(id,@index)
      }
      @index.update(self)
      self
    end

    def init_proc(&p)
      values.each{|v|
        v.init_proc(&p)
      }
      self
    end
  end

  module Logging
    def self.extended(obj)
      Msg.type?(obj,Command)
      obj.extend Object::Logging
    end

    def set(cmd)
      obj=super
      append(cmd)
      obj
    end
  end
end
require 'libcmditem'
