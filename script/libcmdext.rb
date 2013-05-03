#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

# For External Command Domain
class Command
  def add_extdom(db,path)
    self['ext']=ExtDom.new(db,path,@def_proc)
  end

  class ExtDom < Domain
    def initialize(db,path,def_proc=ExeProc.new)
      super(6,def_proc)
      Msg.type?(db,Db)
      if @cdb=db[path]
        items={}
        labels=@cdb[:label]
        if gdb=@cdb[:group]
          #For App Layer
          gdb.each{|gid,gat|
            items.update def_group(gid,labels,gat)
          }
        else
          #For Frm Layer
          gat={'color' => @color,'caption' => "Command List"}
          # If no group, use :select for grouplist
          gat[:members]=@cdb[:select].keys
          items.update def_group('main',labels,gat)
        end
        @cdb[:alias].each{|k,v| items[k].replace items[v]} if @cdb.key?(:alias)
      end
    end

    private
    # Make Default groups (generated from Db)
    def def_group(gid,labels,gat)
      return {} if key?(gid)
      self[gid]=ExtGrp.new(gat,@def_proc).update_items(@cdb)
    end
  end

  class ExtGrp < Group
    def update_items(cdb)
      @attr[:members].each{|id|
        @cmdlist[id]=cdb[:label][id]
        self[id]=ExtItem.new(cdb,id,@def_proc)
      }
      self
    end
  end

  class ExtItem < Item
    include Math
    attr_reader :select
    def initialize(cdb,id,def_proc)
      super(id,def_proc)
      cdb.each{|k,v|
        if a=v[@id]
          self[k]=a
        end
      }
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
end

if __FILE__ == $0
  require 'liblocdb'

  begin
    Msg::GetOpts.new("af")
    ldb=Loc::Db.new(ARGV.shift)
    cobj=Command.new
    if $opt["f"]
      cobj.add_extdom(ldb[:frm],:command)
    else
      cobj.add_extdom(ldb[:app],:command)
    end
    puts cobj.setcmd(ARGV)
  rescue UserError
    $opt.usage("(opt) [id] [cmd] (par)")
  end
end
