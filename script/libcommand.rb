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
#
# Command::Domain => {id => Command::Item}
#  Command::Domain#add_group(key,title) -> Command::Group
#  Command::Domain#group[key] -> Command::Group
#  Command::Domain#def_proc{|par,id|}
#
# Command#new(db) => {id => Command::Item}
#  Command#add_domain(key,title) -> Command::Domain
#  Command#domain[key] -> Command::Domain
#   Command#int -> Command::Domain['int']
#  Command#current -> Command::Item
#  Command#pre_exe -> Update
#  Command#set(cmd=alias+par):{
#    Command[alias->id]#set_par(par)
#    Command#current -> Command[id]
#  } -> Command::Item
# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :current,:alias,:domain,:pre_exe,:int,:ext
  # CDB: mandatory (:select)
  # optional (:alias,:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize
    Command.init_ver(self)
    @current=nil
    @domain={}
    @alias={}
    @pre_exe=Update.new
    @int=add_domain('int')
  end

  def add_domain(did,color=2)
    @domain[did]=Domain.new(self,color)
  end

  def set(cmd)
    id,*par=cmd
    id=@alias[id] || id
    key?(id) || error
    @current=self[id].set_par(par)
  end

  def to_s
    @domain.values.map{|dom| dom.to_s}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+to_s)
  end

  def add_ext(db,path)
    @ext=add_domain('ext',4).ext_setdb(db,path)
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
  end

  class Domain < Hash
    attr_reader :group
    def initialize(index,color=6)
      @index=Msg.type?(index,Command)
      @group={}
      @color=color
    end

    def add_group(gid,title)
      @group[gid]=Group.new(@index,title,2,@color)
    end

    def def_proc
      @group.values.each{|grp|
        grp.values.each{|item|
          item.add_proc{|par,id| yield par,id}
        }
      }
      self
    end

    def to_s
      @group.values.map{|grp| grp.to_s}.grep(/./).join("\n")
    end

    def ext_setdb(db,path)
      extend SetDb
      init(db,path)
      self
    end
  end

  class Group < Hash
    attr_reader :list
    def initialize(index,title,col=2,color=6)
      @list=Msg::CmdList.new(title,col,color)
      @index=Msg.type?(index,Command)
    end

    def add_item(id,title=nil,parameter=nil)
      @list[id]=title
      @index[id]=self[id]=Item.new(@index,id)
      property={:label => title}
      property[:parameter] = parameter if parameter
      self[id].update(property)
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(list)
      @list.update(list)
      list.each{|id,title|
        @index[id]=self[id]=Item.new(@index,id).add_jump
      }
      self
    end

    def to_s
      @list.to_s
    end
  end

  module SetDb
    def self.extended(obj)
      Msg.type?(obj,Domain)
    end

    def init(db,path)
      @db=Msg.type?(db,Db)
      @cdb=db[path]
      @index.alias.update(@cdb[:alias]||{})
      all=@cdb[:select].keys.each{|id|
        @index[id]=self[id]=Item.new(@index,id).update(db_pack(id))
      }
      if gdb=@cdb[:group]
        gdb[:items].each{|gid,member|
          cap=(gdb[:caption]||{})[gid]
          col=(gdb[:column]||{})[gid]
          def_group(gid,member,cap,col)
        }
      else
        def_group('main',all,"Command List",1)
      end
      self
    end

    private
    def db_pack(id)
      property={}
      @cdb.each{|sym,h|
        case sym
        when :group,:alias
          next
        else
          property[sym]=h[id].dup if h.key?(id)
        end
      }
      property
    end

    # Make Default groups (generated from Db)
    def def_group(gid,items,cap,col)
      @group[gid]=Group.new(@index,cap,col,2)
      items.each{|id|
        @group[gid][id]=@index[id]
      }
      add_list(@group[gid].list,items)
    end

    # make alias list
    def add_list(list,ary)
      lh=@cdb[:label]
      if alary=@cdb[:alias]
        alary.each{|a,r|
          list[a]=lh[r] if ary.include?(r)
        }
      else
        ary.each{|i| list[i]=lh[i] }
      end
      list
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

if __FILE__ == $0
  require 'libinsdb'
  Msg.getopts("af")
  begin
    adb=Ins::Db.new(ARGV.shift).cover_app
    cobj=Command.new
    if $opt["f"]
      cobj.add_ext(adb.cover_frm,:cmdframe)
    else
      cobj.add_ext(adb,:command)
    end
    puts cobj.set(ARGV)
  rescue UserError
    Msg::usage("(opt) [id] [cmd] (par)",*$optlist)
    Msg.exit
  end
end
