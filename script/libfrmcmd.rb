#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libextcmd"

# Cmd Methods
module CIAX
  module Frm
    class Command < Command
      attr_reader :field
      def initialize(upper)
        super
        @field=@cfg[:field]=Field.new(@cfg[:db][:field][:struct].deep_copy)
        self['sv'].add_group(:group_class => IntGrp)
        @extgrp=self['sv'].add_group(:group_class => ExtGrp,:item_class =>ExtItem)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end
    end

    class IntGrp < IntGrp
      def initialize(upper,crnt={})
        super
        any={:type =>'reg',:list => ["."]}
        add_item('save',{:label =>"[key,key...] [tag]",:parameter =>[any,any]})
        add_item('load',{:label =>"[tag]",:parameter =>[any]})
        set=add_item('set',{:label =>"[key(:idx)] [val(,val)]",:parameter =>[any,any]})
        set.set_proc{|ent|
          @cfg[:field].set(*ent.par)
        }
      end
    end

    class ExtItem < Item
      def initialize(upper,crnt={})
        super
        @field=type?(@cfg[:field],Field)
        db=@cfg[:db]
        @cache={}
        @fstr={}
        if /true|1/ === @cfg[:noaffix]
          @sel={:main => ["body"]}
        else
          @sel=Hash[db[:cmdframe]]
        end
        @frame=Frame.new(db['endian'],db['ccmethod'])
        @ver_color=0
      end

      def set_par(par)
        ent=super
        return unless @sel[:body]=ent.cfg[:body]
        cid=@cfg[:cid]
        verbose("FrmItem","Body:#{@cfg[:label]}(#{cid})")
        if frame=@cache[cid]
          verbose("FrmItem","Cmd cache found [#{cid}]")
        else
          nocache=mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.mark
            mk_frame(:ccrange)
            @field.set('cc',@frame.checkcode)
          end
          mk_frame(:main)
          frame=@fstr[:main]
          @cache[cid]=frame unless nocache
        end
        ent.cfg[:frame]=frame
        ent
      end

      private
      def mk_frame(domain)
        convert=nil
        @frame.set
        @sel[domain].each{|a|
          case a
          when Hash
            frame=@field.subst(a['val'])
            convert=true if frame != a['val']
            frame.split(',').each{|s|
              @frame.add(s,a)
            }
          else # ccrange,body ...
            @frame.add(@fstr[a.to_sym])
          end
        }
        @fstr[domain]=@frame.copy
        convert
      end
    end

    if __FILE__ == $0
      require "libfield"
      require "libfrmdb"
      dev,*args=ARGV
      ARGV.clear
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set(dev)
        cobj=Command.new(cfg)
        cobj.field.read unless STDIN.tty?
        print cobj.setcmd(args).cfg[:frame]
      rescue InvalidCMD
        Msg.usage("[dev] [cmd] (par) < field_file",[])
      rescue InvalidID
        Msg.usage "[dev] [cmd] (par) < field_file"
      end
    end
  end
end
