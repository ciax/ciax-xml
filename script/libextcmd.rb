#!/usr/bin/ruby
require 'libcommand'

module CIAX
  class Command
    attr_reader :extgrp,:intgrp
    # Add external or internal command group to the remote command domain
    # Need to give a module name as a group (Ext,Int)
    # cfg need [:db] entry
    def add_extgrp(mod)
      @extgrp=@svdom.add_group(:mod => mod)
      self
    end

    def add_intgrp(mod)
      @intgrp=@svdom.add_group(:mod => mod)
      self
    end

    def ext_proc(&def_proc)
      @extgrp.set_proc(&def_proc)
      self
    end

    def ext_sub(block)
      @extgrp.valid_sub(block)
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
    class Group < Group
      def initialize(dom_cfg,attr={})
        super
        @db=type?(@cfg[:db],Dbi)
        @cfg[:group_id]=@db['id']
        @cfg['caption']||="External Commands"
        # Set items by DB
        cdb=@db[:command]
        idx=cdb[:index]
        (cdb[:group]).each{|gid,gat|
          @current=@cmdlist.new_grp(gat['caption'])
          (gat[:members]).each{|id,label|
            if att=(cdb[:alias]||{})[id]
              item=idx[att['ref']]
              label=att['label']
            else
              item=idx[id]
              label=item['label']
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
