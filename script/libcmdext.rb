#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

# For External Command Domain
class Command
  class ExtGrp < Group
    def initialize(db)
      @db=Msg.type?(db,Db)
      super('color' => '6','caption' => "External Commands")
      @cmdary=[]
      cdb=db[:command]
      (cdb[:group]||{'main'=>@attr}).each{|gid,gat|
        subgrp=Msg::CmdList.new(gat,@valid_keys)
        (gat[:members]||cdb[:select].keys).each{|id|
          subgrp[id]=cdb[:label][id]
          self[id]=extitem(id)
        }
        @cmdary << subgrp
      }
      cdb[:alias].each{|k,v| self[k].replace self[v]} if cdb.key?(:alias)
    end

    def list
      @cmdary.join("\n")
    end

    private
    def extitem(id)
      ExtItem.new(@db,id,@def_proc)
    end
  end

  class ExtItem < Item
    include Math
    attr_reader :select
    def initialize(db,id,def_proc)
      Msg.type?(db,Db)
      super(id,def_proc)
      # because cdb is separated by title
      db[:command].each{|k,v|
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
