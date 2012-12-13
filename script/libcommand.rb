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
    @def_proc=ExeProc.new
  end

  def add_domain(id,color=2)
    @domain[id]=Domain.new(self,color,@def_proc)
  end

  def setcmd(cmd)
    id,*par=cmd
    key?(id) || error
    Command.msg{"SetCMD (#{id},#{par})"}
    @current=self[id].set_par(par)
  end

  def list
    @domain.values.map{|dom| dom.list}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+list)
  end

  class Domain < Hash
    attr_reader :group,:def_proc
    def initialize(index,color=2,def_proc=ExeProc.new)
      @index=Msg.type?(index,Command)
      @group={}
      @color=color
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def add_group(gid,caption,column=2)
      gat={'caption' => caption,'column' => column,'color' => @color}
      @group[gid]=Group.new(@index,gat,@def_proc)
    end

    def init_proc(&p)
      values.each{|v|
        v.def_proc=ExeProc.new << p
      }
      self
    end

    def list
      @group.values.map{|grp| grp.list}.grep(/./).join("\n")
    end
  end

  class Group < Hash
    attr_accessor :def_proc
    def initialize(index,gat,def_proc=ExeProc.new)
      @gat=Msg.type?(gat,Hash)
      @labeldb=Msg::CmdList.new(gat)
      @index=Msg.type?(index,Command)
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def add_item(id,title=nil,parameter=nil)
      @labeldb[id]=title
      item=self[id]=Item.new(id,@index,@def_proc)
      property={:label => title}
      property[:parameter] = parameter if parameter
      item.update(property)
      @index.update(self)
      item
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(labels)
      (@gat[:list]||labels.keys).each{|id|
        @labeldb[id]=labels[id]
        self[id]=Item.new(id,@index)
      }
      @index.update(self)
      self
    end

    def init_proc(&p)
      values.each{|v|
        v.def_proc=ExeProc.new << p
      }
      self
    end

    def list
      @labeldb.to_s
    end
  end
end
require 'libcmditem'
