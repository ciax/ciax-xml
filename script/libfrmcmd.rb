#!/usr/bin/ruby
require "libextcmd"
require "libfield"
require "libframe"

module CIAX
  module Frm
    class Command < Command
      attr_reader :field
      def initialize(upper)
        super
        @field=@cfg[:field]=Field.new
        @cfg[:db][:field].each{|id,hash| @field[id]=Arrayx.new.skeleton(hash[:struct])}
        @extgrp=@svdom.add_group(:group_class => ExtGrp,:item_class =>ExtItem)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end

      def add_int
        @svdom.add_group(:group_class =>IntGrp)
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Internal Commands'
        any={:type =>'reg',:list => ["."]}
        add_item('save',"[key,key...] [tag]",{:parameter =>[any,any]})
        add_item('load',"[tag]",{:parameter =>[any]})
        set=add_item('set',"[key(:idx)] [val(,val)]",{:parameter =>[any,any]})
        set.set_proc{|ent|
          @cfg[:field].set(*ent.par)
          'OK'
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
          @sel=Hash[db[:command][:frame]]
        end
        @frame=Frame.new(db['endian'],db['ccmethod'])
        @ver_color=0
      end

      def set_par(par)
        ent=super
        return unless @sel[:body]=ent.cfg[:body]
        cid=ent.id
        verbose("FrmItem","Body:#{@cfg[:label]}(#{cid})")
        if frame=@cache[cid]
          verbose("FrmItem","Cmd cache found [#{cid}]")
        else
          nocache=mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.mark
            mk_frame(:ccrange)
            @field.set('cc',@frame.check_code)
          end
          mk_frame(:main)
          frame=@fstr[:main]
          @cache[cid]=frame unless nocache
          verbose("FrmItem","Cmd Generated [#{cid}]")
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
      id,*args=ARGV
      ARGV.clear
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set(id)
        cobj=Command.new(cfg)
        cobj.field.read unless STDIN.tty?
        print cobj.set_cmd(args).cfg[:frame]
      rescue InvalidCMD
        Msg.usage("[dev] [cmd] (par) < field_file",[])
      rescue InvalidID
        Msg.usage "[dev] [cmd] (par) < field_file"
      end
    end
  end
end
