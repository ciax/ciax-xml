#!/usr/bin/ruby
require "libremote"
require "libframe"
require "libfield"

module CIAX
  module Frm
    class Command < Command
      # cfg or attr should have [:db] and [:field]
      attr_reader :rem
      def initialize(cfg,attr={})
        super
        @cfg[:cls_color]=6
        @rem=add(Domain)
      end
    end

    class Domain < Remote::Domain
      attr_reader :ext,:int
      def initialize(cfg,attr={})
        super
        @ext=add(Ext::Index,{:group_id => 'external'})
      end

      def add_int
        @int=add(Int::Index,{:group_id => 'internal'})
      end
    end

    module Int
      include Remote::Int
      class Index < Index
        def initialize(cfg,attr={})
          super
          @cfg['caption']='Internal Commands'
          any={:type =>'reg',:list => ["."]}
          add_item('save',"[key,key...] [tag]",def_pars(2))
          add_item('load',"[tag]",def_pars(1))
          cmd=add_item('set',"[key(:idx)] [val(,val)]",def_pars(2))
          cmd.cfg.proc{|ent|
            if @cfg[:field].key?(ent.par[0])
              @cfg[:field].put(*ent.par)
              'OK'
            else
              "No such value #{ent.par[0]}"
            end
          }
        end
      end
      class Item < Item;end
      class Entity < Entity;end
    end

    module Ext
      include Remote::Ext
      class Index < Index;end
      class Item < Item;end
      class Entity < Entity
        def initialize(cfg,attr={})
          super
          @field=type?(@cfg[:field],Field)
          db=@cfg[:db]
          @fstr={}
          if /true|1/ === @cfg["noaffix"]
            @sel={:main => ["body"]}
          else
            @sel=Hash[db[:command][:frame]]
          end
          @frame=Frame.new(db['endian'],db['ccmethod'])
          return unless @sel[:body]=@cfg[:body]
          verbose("FrmItem","Body:#{@cfg['label']}(#@id)")
          mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.cc_mark
            mk_frame(:ccrange)
            @frame.cc_set
          end
          mk_frame(:main)
          frame=@fstr[:main]
          verbose("FrmItem","Cmd Generated [#@id]")
          @cfg[:frame]=frame
          @field.echo=frame # For send back
        end

        private
        # instance var frame,sel,field,fstr
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
        db=Db.new.get(id)
        fld=Field.new.set_db(db)
        cfg=Config.new('test',{:db => db,:field => fld})
        cfg.proc{|ent| ent.cfg.path }
        cobj=Command.new(cfg)
        cobj.rem.add_int
        fld.read unless STDIN.tty?
        ent=cobj.set_cmd(args)
        puts ent.exe_cmd('test')
      rescue InvalidCMD
        Msg.usage("#{id} [cmd] (par) < field_file",2)
      rescue InvalidID
        Msg.usage("[dev] [cmd] (par) < field_file")
      end
    end
  end
end
