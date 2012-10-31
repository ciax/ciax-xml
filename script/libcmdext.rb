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
      cdb=db[path]
      @list=cdb[:select].keys.each{|id|
        @index[id]=self[id]=Item.new(id,@index,@def_proc).update(db_pack(id,cdb))
      }
      add_db(cdb)
    end

    def add_db(cdb)
      if cdb
        if gdb=cdb[:group]
          gdb.each{|gid,hash|
            def_group(gid,cdb,hash)
          }
        else
          attr={"color" => @color}
          attr["caption"]='Command List'
          attr["column"]=1
          attr[:list]=@list
          def_group('main',cdb,attr)
        end
      end
      self
    end

    private
    def db_pack(id,cdb)
      property={}
      cdb.each{|sym,h|
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
    def def_group(gid,cdb,attr)
      return if @group.key?(gid)
      grp=@group[gid]=Group.new(@index,attr,@def_proc)
      attr[:list].each{|id|
        grp[id]=@index[id]
        grp.list[id]=cdb[:label][id]
      }
    end
  end
end

if __FILE__ == $0
  require 'liblocdb'
  require 'libcmditem'
  Msg.getopts("af")
  begin
    ldb=Loc::Db.new(ARGV.shift)
    cobj=Command.new
    if $opt["f"]
      cobj.add_ext(ldb[:frm],:cmdframe)
    else
      cobj.add_ext(ldb[:app],:command)
    end
    puts cobj.set(ARGV)
  rescue UserError
    Msg::usage("(opt) [id] [cmd] (par)",*$optlist)
    Msg.exit
  end
end
