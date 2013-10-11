#!/usr/bin/ruby
require 'libcommand'
require 'librerange'

module CIAX
  class IntGrp < Group
    def initialize(upper)
      super
      @cfg['caption']='Internal Commands'
    end
  end

  # For External Command Domain
  # @cfg must contain [:db]
  class ExtGrp < Group # upper needs [:db]
    def initialize(upper,crnt={})
      super
      @cfg[:entity_class]||=ExtEntity
      @cfg['caption']||="External Commands"
      @cfg['color']||=6
      @cmdary=[]
      set_items(type?(@cfg[:db],Db)[:command])
    end

    def set_items(cdb)
      (cdb[:group]||{'main'=>@cfg}).each{|gid,gat|
        subgrp=CmdList.new(gat,@valid_keys)
        (gat[:members]||cdb[:body].keys).each{|id|
          subgrp[id]=cdb[:label][id]
          # because cdb is separated by title
          cfg={}
          cdb.each{|k,v|
            if a=v[id]
              cfg[k]=a
            end
          }
          add_item(id,cfg)
        }
        @cmdary << subgrp
      }
      cdb[:alias].each{|k,v| self[k].replace self[v]} if cdb.key?(:alias)
    end
  end

  class ExtEntity < Entity
    # Substitute string($+number) with parameters
    # par={ val,range,format } or String
    # str could include Math functions
    def initialize(upper,crnt={})
      super
      @cfg[:body]=deep_subst(@cfg[:body])
    end

    def subst(str)
      return str unless /\$([\d]+)/ === str
      enclose("ExtEntity","Substitute from [#{str}]","Substitute to [%s]"){
        num=true
        res=str.gsub(/\$([\d]+)/){
          i=$1.to_i
          num=false if @cfg[:parameter][i-1][:type] != 'num'
          verbose("ExtEntity","Parameter No.#{i} = [#{@par[i-1]}]")
          @par[i-1] || Msg.cfg_err(" No substitute data ($#{i})")
        }
        if num && /\$/ !~ res
          res=eval(res).to_s
        end
        Msg.cfg_err("Nil string") if res == ''
        res
      }
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
