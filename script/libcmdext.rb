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
      dgdb={:color => @color}
      if gdb=@cdb[:group]
        gdb.each{|gid,hash|
          dgdb.update(hash)
          def_group(gid,dgdb)
        }
      else
        dgdb[:caption]='Command List'
        dgdb[:column]=1
        dgdb[:list]=all
        def_group('main',dgdb)
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
    def def_group(gid,gdb)
      @group[gid]=Group.new(@index,gdb,@def_proc)
      gdb[:list].each{|id|
        @group[gid][id]=@index[id]
      }
      gdb[:list].each{|i|
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
    idb=Ins::Db.new(ARGV.shift).cover_loc
    cobj=Command.new
    if $opt["f"]
      cobj.add_ext(idb[:frm],:cmdframe)
    else
      cobj.add_ext(idb[:app],:command)
    end
    puts cobj.set(ARGV)
  rescue UserError
    Msg::usage("(opt) [id] [cmd] (par)",*$optlist)
    Msg.exit
  end
end
