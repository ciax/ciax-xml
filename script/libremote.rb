#!/usr/bin/ruby
require 'liblocal'

module CIAX
  module Remote
    include Command
    # Instance var is @rem in Index
    class Index < Local::Index
      attr_reader :rem
      def add_rem
        @rem=add('Domain')
      end
    end

    class Domain < GrpAry
      attr_reader :hid,:ext,:int
      def initialize(cfg,attr={})
        super
        @cfg[:def_proc]=Proc.new{""} # proc is re-defined
      end

      def add_hid
        @hid=add('Hid::Group')
      end

      def add_ext(dbi)
        @ext=add('Ext::Group',{:dbi => type?(dbi,Dbi)})
      end

      def add_int(valid_keys=[])
        @int=add('Int::Group',{:valid_keys => valid_keys})
      end
    end

    module Hid
      include Command
      class Group < Group
        def initialize(dom_cfg,attr={})
          super
          @cfg['caption']="Hidden Commands"
          add_item('interrupt')
          # Accept empty command
          add_item(nil)
        end
      end
    end

    module Int
      include Command
      class Group < Group
        def initialize(dom_cfg,attr={})
          super
          @cfg['caption']='Internal Commands'
        end

        def def_pars(n=1)
          any={:type => 'reg', :list => ['.']}
          ary=[]
          n.times{ary << any}
          {:parameters =>ary}
        end
      end
      class Item < Item;end
      class Entity < Entity;end
    end

    # For External Command Domain
    # @cfg must contain [:dbi]
    module Ext
      include Command
      class Group < Group
        def initialize(cfg,attr={})
          super
          @dbi=type?(@cfg[:dbi],Dbi)
          @cfg['caption']||="External Commands"
          @cfg['ver']||=@dbi['version']
          # Set items by DB
          cdb=@dbi[:command]
          idx=cdb[:index]
          (cdb[:group]).each{|gid,gat|
            @current=@displist.new_grp(gat['caption'])
            (gat[:members]).each{|id|
              if att=(cdb[:alias]||{})[id]
                item=idx[att['ref']]
                label=att['label']
              else
                item=idx[id]
                label=item['label']
              end
              if Array === item[:parameters]
                label=label.gsub(/\$([\d]+)/,'%s') % item[:parameters].map{|e| e['label']}
              end
              add_item(id,label,item)
            }
          }
        end
      end

      class Item < Item;end
      class Entity < Entity
        # Substitute string($+number) with parameters
        # par={ val,range,format } or String
        # str could include Math functions
        def initialize(grp_cfg,attr={})
          super
          @body=deep_subst(@cfg[:body])
        end

        def subst(str) #subst by parameters ($1,$2...)
          return str unless /\$([\d]+)/ === str
          enclose("Substitute from [#{str}]","Substitute to [%s]"){
            num=true
            res=str.gsub(/\$([\d]+)/){
              i=$1.to_i
              num=false if @cfg[:parameters][i-1][:type] != 'num'
              verbose("Parameter No.#{i} = [#{@par[i-1]}]")
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
end
