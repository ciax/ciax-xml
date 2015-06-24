#!/usr/bin/ruby
require 'libcommand'

module CIAX
  module Remote
    class Domain < Domain
      attr_reader :hid
      def initialize(cfg,attr={})
        super
        @cfg[:domain_id]='remote'
        @hid=add(Hid::Index)
      end
    end

    module Hid
      include Group
      class Index < Index
        def initialize(dom_cfg,attr={})
          super
          @cfg['caption']="Hidden Commands"
          @cfg[:group_id]='hidden'
          add_item('interrupt')
        end

        def add_nil
          # Accept empty command
          add_item(nil)
          self
        end
      end
    end

    module Int
      include Group
      class Index < Index
        def initialize(dom_cfg,attr={})
          super
          @cfg[:group_id]='internal'
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
    # @cfg must contain [:db]
    module Ext
      include Group
      class Index < Index
        def initialize(dom_cfg,attr={})
          super
          @db=type?(@cfg[:db],Dbi)
          @cfg[:group_id]=@db['id']
          @cfg['caption']||="External Commands"
          # Set items by DB
          cdb=@db[:command]
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
          @cfg['label']=subst(@cfg['label'])
          @body=deep_subst(@cfg[:body])
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
end
