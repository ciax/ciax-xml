#!/usr/bin/ruby
require 'libcommand'

module CIAX
  class Command
    def ext_proc(&def_proc)
      @extgrp.set_proc(&def_proc)
      self
    end
  end

  module Int
    class Group < Group
      def initialize(dom_cfg,attr={})
        super
        @cfg[:group_id]='internal'
      end

      def pars(n=1)
        any={:type => 'reg', :list => ['.']}
        ary=[]
        n.times{ary << any}
        {:parameters =>ary}
      end
    end
  end

  # For External Command Domain
  # @cfg must contain [:db]
  module Ext
    class Group < Group # dom_cfg needs [:db]
      def initialize(dom_cfg,attr={})
        super
        @cfg[:group_id]=@cfg[:db]['id']
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

    class Entity < Entity
      # Substitute string($+number) with parameters
      # par={ val,range,format } or String
      # str could include Math functions
      def initialize(grp_cfg,attr={})
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
            res=res.split(':').map{|n| eval(n).to_s}.join(':')
          end
          Msg.cfg_err("Nil string") if res == ''
          res
        }
      end

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
end
