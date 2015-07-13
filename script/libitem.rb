#!/usr/bin/ruby
require 'libenumx'
require 'librerange'

# @cfg[:def_proc] should be Proc which is given |Entity| as param, returns String as message.
module CIAX
  module Command;Color=2
    # Corresponds commands
    class Item < Hashx
      include Msg
      attr_reader :cfg
      #grp_cfg should have :id,'label',:parameters,:def_proc
      def initialize(cfg,attr={})
        super()
        @cls_color=6
        @cfg=cfg.gen(self).update(attr)
      end

      def set_par(par,opt={})
        par=opt[:par]=validate(type?(par,Array))
        verbose("SetPAR(#{@cfg[:id]}): #{par}")
        cid=opt[:cid]=[@cfg[:id],*par].join(':')
        if key?(cid)
          verbose("SetPAR: Entity Cache found(#{cid})")
          self[cid]
        else
          ent=context_constant('Entity').new(@cfg,opt)
          if @cfg["nocache"]
            verbose("SetPAR: Entity No Cache Created (#{cid})")
          else
            self[cid]=ent
            verbose("SetPAR: Entity Cache Created (#{cid})")
          end
          ent
        end
      end

      def valid_pars
        (@cfg[:parameters]||[]).map{|e| e[:list] if e[:type] == 'str'}.flatten
      end

      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc]=type?(def_proc,Proc)
        self
      end

      private
      # Parameter for validate(cfg[:paremeters]) structure:  [{:type,:list,:default}, ...]
      # *Empty parameter will replaced to :default
      # *Error if str doesn't match with strings listed in :list
      # *If no :list, returns :default
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
              verbose("Validate: [#{num}] Match? [#{disp}]")
              unless list.any?{|r| ReRange.new(r) == num }
                Msg.par_err("Out of range (#{num}) for [#{disp}]")
              end
              next num.to_s
            when 'reg'
              verbose("Validate: [#{str}] Match? [#{disp}]")
              unless list.any?{|r| Regexp.new(r) === str}
                Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
              end
            else
              verbose("Validate: [#{str}] Match? [#{disp}]")
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
      attr_reader :id,:par,:cfg
      #set should have :def_proc
      def initialize(cfg,attr={})
        @cls_color=14
        @cfg=cfg.gen(self).update(attr)
        @par=@cfg[:par]
        @id=@cfg[:cid]
        verbose("Config",@cfg.path)
      end

      # returns result of def_proc block (String)
      def exe_cmd(src,pri=1)
        verbose("Execute [#{@id}] from #{src}")
        @cfg[:def_proc].call(self,src,pri)
      end
    end
  end
end
