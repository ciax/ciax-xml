#!/usr/bin/ruby
require 'libcommand'

module CIAX
  class SwSiteGrp < Group
    def initialize(upper,crnt={})
      super
      @cfg['caption']='Switch Sites'
      @cfg['color']=5
      @cfg['column']=2
      update_items(@cfg[:ldb].list)
      set_proc{|ent| raise(SiteJump,ent.id)}
    end
  end

  class SwLayerGrp < Group
    def initialize(upper=Config.new,crnt={})
      super
      @cfg['caption']='Switch Layer'
      @cfg['color']=5
      @cfg['column']=5
      set_proc{|ent| raise(LayerJump,ent.id) }
    end
  end

  # For External Command Domain
  # @cfg must contain [:db]
  class ExtGrp < Group # upper needs [:db]
    def initialize(upper,crnt={})
      crnt[:group_id]=upper[:db]['id']
      super
      @cfg[:entity_class]||=ExtEntity
      @cfg['caption']||="External Commands"
      @cfg['color']||=6
      set_items(@cfg[:db])
    end

    def set_items(db)
      cdb=type?(db,Db)[:command]
      idx=cdb[:index]
      (cdb[:group]).each{|gid,gat|
        @cmdary << CmdList.new(gat,@valid_keys)
        (gat[:members]).each{|id,label|
          if ref=(cdb[:alias]||{})[id]
            item=idx[ref]
          else
            item=idx[id]
          end
          add_item(id,label,item)
        }
      }
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

    def subst(str) #subst by parameters ($1,$2...)
      return str unless /\$([\d]+)/ === str
      enclose("ExtEntity","Substitute from [#{str}]","Substitute to [%s]"){
        num=true
        res=str.gsub(/\$([\d]+)/){
          i=$1.to_i
          num=false if @cfg[:parameters][i-1][:type] != 'num'
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
