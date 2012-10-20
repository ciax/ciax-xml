#!/usr/bin/ruby
require 'libcommand'

# For External Command Domain
class Command
  attr_reader :extcmd
  def add_ext(db,path)
    @extcmd=@domain['ext']=ExtDom.new(self,db,path)
  end

  class ExtDom < Domain
    def initialize(index,db,path)
      super(index,6)
      @db=Msg.type?(db,Db)
      @cdb=db[path]
      all=@cdb[:select].keys.each{|id|
        @index[id]=self[id]=Item.new(id,@index,@def_proc).update(db_pack(id))
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
      @group[gid]=Group.new(@index,cap,col,@color,@def_proc)
      items.each{|id|
        @group[gid][id]=@index[id]
      }
      items.each{|i|
        @group[gid].list[i]=@cdb[:label][i]
      }
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
