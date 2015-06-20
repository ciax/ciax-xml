#!/usr/bin/ruby
require 'libcmdlist'
require 'librerange'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
# @cfg
module CIAX
  module Group
    class Index < Hashx
      attr_reader :cfg,:valid_keys
      #dom_cfg keys: caption,color,column
      def initialize(cfg,attr={})
        super()
        @cfg=cfg.gen('group').update(attr)
        @valid_keys=@cfg[:valid_keys]||[]
        @cls_color=@cfg[:cls_color]
        @pfx_color=@cfg[:pfx_color]
        @cmdlist=CmdList.new(@cfg,@valid_keys)
        @cfg['color']||=2
        @cfg['column']||=2
      end

      def add_item(id,title=nil,crnt={})
        crnt['label']=current[id]=title
        new_item(id,crnt)
      end

      def del_item(id)
        @valid_keys.delete(id)
        current.delete(id)
        delete(id)
      end

      def merge_items(cmdlist)
        type?(cmdlist,CmdList).each{|cg|
          cg.each{|id,title|
            new_item(id,{'label'=> title})
          }
        }
        @current=@cmdlist.merge!(cmdlist).last
        self
      end

      def add_dummy(id,title)
        current.dummy(id,title) #never put into valid_key
        self
      end

      def valid_reset
        @valid_keys.concat(keys).uniq!
        self
      end

      def valid_sub(ary)
        @valid_keys.replace(keys-type?(ary,Array))
        self
      end

      def view_list
        @cmdlist.to_s
      end

      def valid_pars
        values.map{|e| e.valid_pars}.flatten
      end

      def get_item(id)
        self[id]
      end

      def set_cmd(args,opt={})
        id,*par=type?(args,Array)
        @valid_keys.include?(id) || raise(InvalidCMD,view_list)
        get_item(id).set_par(par,opt)
      end

      private
      def new_item(id,crnt={})
        crnt[:id]=id
        self[id]=context_constant('Item').new(@cfg,crnt)
      end

      def current
        @current||=@cmdlist.new_grp
      end
    end

    # Corresponds commands
    class Item
      include Msg
      attr_reader :cfg
      #grp_cfg should have :id,'label',:parameters,:def_proc
      def initialize(cfg,attr={})
        @cfg=cfg.gen(self).update(attr)
        @cls_color=@cfg[:cls_color]
        @pfx_color=@cfg[:pfx_color]
      end

      def set_par(par,opt={})
        opt[:par]=validate(type?(par,Array))
        verbose("Cmd","SetPAR(#{@cfg[:id]}): #{par}")
        context_constant('Entity').new(@cfg,opt)
      end

      def valid_pars
        (@cfg[:parameters]||[]).map{|e| e[:list] if e[:type] == 'str'}.flatten
      end

      private
      # Parameter for validate(cfg[:paremeters]) structure:  [{:type,:list,:default}, ...]
      # Returns converted parameter array
      def validate(pary)
        pary=type?(pary.dup,Array)
        return [] unless @cfg[:parameters]
        @cfg[:parameters].map{|par|
          list=par[:list]||[]
          disp=list.join(',')
          unless str=pary.shift
            next par[:default] if par.key?(:default)
            mary=[]
            mary << "Parameter shortage (#{pary.size}/#{@cfg[:parameters].size})"
            mary << Msg.item(@cfg[:id],@cfg['label'])
            mary << " "*10+"key=(#{disp})"
            Msg.par_err(*mary)
          end
          if list.empty?
            next par[:default] if par.key?(:default)
          else
            case par[:type]
            when 'num'
              begin
                num=eval(str)
              rescue Exception
                Msg.par_err("Parameter is not number")
              end
              verbose("Cmd","Validate: [#{num}] Match? [#{disp}]")
              unless list.any?{|r| ReRange.new(r) == num }
                Msg.par_err("Out of range (#{num}) for [#{disp}]")
              end
              next num.to_s
            when 'reg'
              verbose("Cmd","Validate: [#{str}] Match? [#{disp}]")
              unless list.any?{|r| Regexp.new(r) === str}
                Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
              end
            else
              verbose("Cmd","Validate: [#{str}] Match? [#{disp}]")
              unless list.include?(str)
                Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
              end
            end
          end
          str
        }
      end
    end

    # Command db with parameter derived from Item
    class Entity
      include Msg
      attr_reader :id,:par,:cfg,:layer
      #set should have :def_proc
      def initialize(cfg,attr={})
        @cfg=cfg.gen(self).update(attr)
        @par=@cfg[:par]
        @id=[@cfg[:id],*@par].join(':')
        @cfg[:cid]=@id
        @cls_color=@cfg[:cls_color]
        @pfx_color=@cfg[:pfx_color]
        @layer=@cfg['layer']
        verbose("Cmd","Config",@cfg.path)
        verbose("self",inspect)
      end

      # returns result of def_proc block (String)
      def exe_cmd(src,pri=1)
        verbose("Cmd","Execute [#{@id}] from #{src}")
        @cfg[:def_proc].call(self,src,pri)
      end
    end
  end
end
