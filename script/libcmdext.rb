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
        gdb.each{|gid,hash|
          def_group(gid,hash)
        }
      else
        attr={"color" => @color}
        attr["caption"]='Command List'
        attr["column"]=1
        attr[:list]=all
        def_group('main',attr)
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
    def def_group(gid,attr)
      grp=@group[gid]=Group.new(@index,attr,@def_proc)
      attr[:list].each{|id|
        grp[id]=@index[id]
        grp.list[id]=@cdb[:label][id]
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
