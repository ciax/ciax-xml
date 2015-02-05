#!/usr/bin/ruby
require "libextcmd"
require "libframe"
require "libfield"

module CIAX
  module Frm
    class Command < Command
      # exe_cfg or attr should have [:id] and [:field]
      def initialize(exe_cfg,attr={})
        attr.update(:cls_color => 6)
        super
        add_extgrp(Ext)
      end
    end

    module Int
      class Group < CIAX::Int::Group
        def initialize(dom_cfg,attr={})
          super
          @cfg[:group_id]='internal'
          @cfg['caption']='Internal Commands'
          any={:type =>'reg',:list => ["."]}
          add_item('save',"[key,key...] [tag]",pars(2))
          add_item('load',"[tag]",pars(1))
          set=add_item('set',"[key(:idx)] [val(,val)]",pars(2))
          set.set_proc{|ent|
            @cfg[:field].set(*ent.par)
            'OK'
          }
        end
      end
    end

    module Ext
      include CIAX::Ext
      class Item < Item
        def initialize(grp_cfg,attr={})
          super
          @cls_color=6
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
          conv=nil
          @frame.reset
          @sel[domain].each{|a|
            case a
            when Hash
              frame=a['val'].gsub(/\$\{cc\}/){@frame.cc}
              frame=@field.subst(frame)
              conv=true if frame != a['val']
              frame.split(',').each{|s|
                @frame.add(s,a)
              }
            else # ccrange,body ...
              @frame.add(@fstr[a.to_sym])
            end
          }
          @fstr[domain]=@frame.copy
          conv
        end
      end
    end

    if __FILE__ == $0
      require "libfrmrsp"
      require "libfrmdb"
      id,*args=ARGV
      ARGV.clear
      begin
        db=Db.new.set(id)
        fld=Field.new.set_db(db)
        cobj=Command.new(:db => db,:field => fld)
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
