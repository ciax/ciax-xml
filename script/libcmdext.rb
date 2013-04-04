#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

# For External Command Domain
class Command
  def add_extdom(db,path)
    @domain['ext']=ExtDom.new(self,db,path,@def_proc)
  end

  class ExtDom < Domain
    def initialize(index,db,path,def_proc=ExeProc.new)
      super(index,6,def_proc)
      Msg.type?(db,Db)
      cdb=db[path]
      cdb[:select].keys.each{|id|
        self[id]=Item.new(id,@index,@def_proc).ext_item(cdb)
      }
      add_db(cdb)
      @index.update(self)
    end

    def add_db(cdb)
      if cdb
        labels=cdb[:label]
        if gdb=cdb[:group]
          #For App Layer
          gdb.each{|gid,gat|
            def_group(gid,labels,gat)
          }
        else
          #For Frm Layer
          gat={'color' => @color,'caption' => "Command List"}
          gat[:list]=cdb[:select].keys
          def_group('main',labels,gat)
        end
      end
      self
    end

    private
    # Make Default groups (generated from Db)
    def def_group(gid,labels,gat)
      return if @group.key?(gid)
      @group[gid]=Group.new(@index,gat,@def_proc).update_items(labels)
    end
  end

  module ExtItem
    include Math
    attr_reader :select
    def self.extended(obj)
      Msg.type?(obj,Command::Item)
    end

    def ext_item(cdb)
      cdb.each{|k,v|
        if a=v[@id]
          self[k]=a
        end
      }
      self
    end

    def set_par(par)
      super
      @select=deep_subst(self[:select])
      self
    end

    # Substitute string($+number) with parameters
    # par={ val,range,format } or String
    # str could include Math functions
    def subst(str)
      return str unless /\$([\d]+)/ === str
      verbose(1){"Substitute from [#{str}]"}
      begin
        num=true
        res=str.gsub(/\$([\d]+)/){
          i=$1.to_i
          num=false if self[:parameter][i-1][:type] != 'num'
          verbose{"Parameter No.#{i} = [#{@par[i-1]}]"}
          @par[i-1] || Msg.cfg_err(" No substitute data ($#{i})")
        }
        if num && /\$/ !~ res
          res=eval(res).to_s
        end
        Msg.cfg_err("Nil string") if res == ''
        res
      ensure
        verbose(-1){"Substitute to [#{res}]"}
      end
    end

    private
    def deep_subst(data)
      case data
      when Array
        res=[]
        data.each{|v|
          res << deep_subst(v)
        }
      when Hash
        res={}
        data.each{|k,v|
          res[k]=deep_subst(v)
        }
      else
        res=subst(data)
      end
      res
    end
  end

  class Item
    def ext_item(cdb)
      extend ExtItem
      ext_item(cdb)
      self
    end
  end
end

if __FILE__ == $0
  require 'liblocdb'

  begin
    Msg::GetOpts.new("af")
    ldb=Loc::Db.new(ARGV.shift)
    cobj=Command.new
    if $opt["f"]
      cobj.add_extdom(ldb[:frm],:cmdframe)
    else
      cobj.add_extdom(ldb[:app],:command)
    end
    puts cobj.setcmd(ARGV)
  rescue UserError
    $opt.usage("(opt) [id] [cmd] (par)")
  end
end
