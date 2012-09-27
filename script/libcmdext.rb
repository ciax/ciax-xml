#!/usr/bin/ruby
require 'libcommand'

class Command
  attr_reader :ext
  def add_ext(db,path)
    @ext=@domain['ext']=ExtDom.new(self,db,path)
  end

  class ExtDom < Domain
    def initialize(index,db,path)
      super(index,6)
      @db=Msg.type?(db,Db)
      @cdb=db[path]
      @index.alias.update(@cdb[:alias]||{})
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
