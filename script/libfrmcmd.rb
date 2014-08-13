#!/usr/bin/ruby
require "libextcmd"
require "libframe"
require "libfield"

module CIAX
  module Frm
    class Command < Command
      # upper must include [:field]
      def initialize(upper)
        super
        @extgrp=@svdom.add_group(:group_class => ExtGrp,:item_class =>ExtItem)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
        self
      end

      def add_int
        @svdom.add_group(:group_class =>IntGrp)
        self
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg[:group_id]='internal'
        @cfg['caption']='Internal Commands'
        any={:type =>'reg',:list => ["."]}
        add_item('save',"[key,key...] [tag]",{:parameters =>[any,any]})
        add_item('load',"[tag]",{:parameters =>[any]})
        set=add_item('set',"[key(:idx)] [val(,val)]",{:parameters =>[any,any]})
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
        if /true|1/ === @cfg["noaffix"]
          @sel={:main => ["body"]}
        else
          @sel=Hash[db[:command][:frame]]
        end
        @frame=Frame.new(db['endian'],db['ccmethod'])
      end

      def set_par(par,opt={})
        ent=super
        return ent unless @sel[:body]=ent.cfg[:body]
        cid=ent.id
        verbose("FrmItem","Body:#{@cfg[:label]}(#{cid})")
        if frame=@cache[cid]
          verbose("FrmItem","Cmd cache found [#{cid}]")
        else
          nocache=mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.cc_mark
            mk_frame(:ccrange)
            @frame.cc_set
          end
          mk_frame(:main)
          frame=@fstr[:main]
          @cache[cid]=frame unless nocache
          verbose("FrmItem","Cmd Generated [#{cid}]")
        end
        ent.cfg[:frame]=frame
        @field.echo=frame
        ent
      end

      private
      def mk_frame(domain)
        convert=nil
        @frame.reset
        @sel[domain].each{|a|
          case a
          when Hash
            frame=a['val'].gsub(/\$\{cc\}/){@frame.cc}
            frame=@field.subst(frame)
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
      require "libfrmrsp"
      require "libfrmdb"
      id,*args=ARGV
      ARGV.clear
      begin
        cfg=Config.new('frm_top')
        db=cfg[:db]=Db.new.set(id)
        fld=cfg[:field]=Field.new.set_db(db)
        cobj=Command.new(cfg)
        fld.read unless STDIN.tty?
        print cobj.set_cmd(args).cfg[:frame]
      rescue InvalidCMD
        Msg.usage("#{id} [cmd] (par) < field_file",2)
      rescue InvalidID
        Msg.usage("[dev] [cmd] (par) < field_file")
      end
    end
  end
end
