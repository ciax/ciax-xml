#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method
#Command < Hash
# Command::Group => {id => Command::Item}
#  Command::Group#add_item(id,title){|id,par|} -> Command::Item
#  Command::Group#update_items(list)
#  Command::Group#list -> Msg::CmdList
#  Command::Group#def_proc ->[{|par,id|},..]
#
# Command::Domain => {id => Command::Item}
#  Command::Domain#add_group(key,title) -> Command::Group
#  Command::Domain#group[key] -> Command::Group
#  Command::Domain#def_proc ->[{|par,id|},..]
#
# Command#new(db) => {id => Command::Item}
#  Command#add_domain(key,title) -> Command::Domain
#  Command#domain[key] -> Command::Domain
#   Command#int -> Command::Domain['int']
#  Command#current -> Command::Item
#  Command#pre_proc -> [{|par,id|},..]
#  Command#def_proc ->[{|par,id|},..]
#  Command#post_proc -> [{|par,id|},..]
#  Command#set(cmd=id+par):{
#    Command[id]#set_par(par)
#    Command#current -> Command[id]
#  } -> Command::Item
# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :current,:domain,:pre_proc,:post_proc
  # CDB: mandatory (:select)
  # optional (:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize
    Command.init_ver(self)
    @current=nil
    @domain={}
    @pre_proc=[]
    @post_proc=[]
  end

  def add_domain(did,color=2)
    @domain[did]=Domain.new(self,color)
  end

  def set(cmd)
    id,*par=cmd
    key?(id) || error
    @current=self[id].set_par(par)
  end

  def to_s
    @domain.values.reverse.map{|dom| dom.to_s}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+to_s)
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
  end

  class Domain < Hash
    attr_reader :group,:def_proc
    def initialize(index,color=2)
      @index=Msg.type?(index,Command)
      @group={}
      @color=color
      @def_proc=[]
    end

    def add_group(gid,title)
      @group[gid]=Group.new(@index,title,2,@color,@def_proc)
    end

    def to_s
      @group.values.map{|grp| grp.to_s}.grep(/./).join("\n")
    end
  end

  class Group < Hash
    attr_reader :list,:def_proc
    def initialize(index,title,col=2,color=2,def_proc=[])
      @list=Msg::CmdList.new({:caption => title,:column => col,:color => color})
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
    def update_items(list)
      @list.update(list)
      list.each{|id,title|
        @index[id]=self[id]=Item.new(id,@index).set_jump
      }
      self
    end

    def to_s
      @list.to_s
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
