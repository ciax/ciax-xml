#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

# For External Command Domain
class Command
  class Domain
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
    end

    def list
      @cmdlist.join("\n")
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
  require 'libfrmcmd'
  require 'libappcmd'

  begin
    Msg::GetOpts.new("af")
    ldb=Loc::Db.new.set(ARGV.shift)
    cobj=Command.new
    svdom=cobj.add_domain('sv')
    if $opt["f"]
      svdom['ext']=Frm::ExtGrp.new(ldb[:frm])
    else
      svdom['ext']=App::ExtGrp.new(ldb[:app])
    end
    puts cobj.setcmd(ARGV)
  rescue InvalidID
    $opt.usage("(opt) [id] [cmd] (par)")
  end
end
