#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

# For External Command Domain
class Command
  class Domain
    def self.extended(obj)
      Msg.type?(obj,Domain)
    end

    def add_extgrp(db)
      self['ext']=ExtGrp.new(db)
    end

    def add_intgrp
      add_group('int','Internal Commands')
    end
  end

  class ExtGrp < Group
    def initialize(db)
      @db=Msg.type?(db,Db)
      @valid_keys=[]
      @cmdlist=[]
      @def_proc=ExeProc.new
      if @cdb=db[:command]
        if gdb=@cdb[:group]
          #For App Layer
          gdb.each{|gid,gat|
            sublist=Msg::CmdList.new(gat,@valid_keys)
            gat[:members].each{|id|
              update_sublist(sublist,id)
            }
            @cmdlist << sublist
          }
        else
          #For Frm Layer
          sublist=Msg::CmdList.new({'color' => '6','caption' => "External Commands"},@valid_keys)
          @cdb[:select].keys.each{|id|
            update_sublist(sublist,id)
          }
          @cmdlist << sublist
        end
        @cdb[:alias].each{|k,v| items[k].replace items[v]} if @cdb.key?(:alias)
      end
    end

    def list
      @cmdlist.join("\n")
    end

    private
    def update_sublist(sublist,id)
      sublist[id]=@cdb[:label][id]
      self[id]=ExtItem.new(@cdb,id,@def_proc)
      self
    end
  end

  class ExtItem < Item
    include Math
    attr_reader :select
    def initialize(cdb,id,def_proc)
      super(id,def_proc)
      # because cdb is separated by title
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
    ldb=Loc::Db.new.set(ARGV.shift)
    cobj=Command.new
    svdom=cobj.add_domain('sv')
    if $opt["f"]
      svdom.add_extgrp(ldb[:frm])
    else
      svdom.add_extgrp(ldb[:app])
    end
    puts cobj.setcmd(ARGV)
  rescue InvalidID
    $opt.usage("(opt) [id] [cmd] (par)")
  end
end
