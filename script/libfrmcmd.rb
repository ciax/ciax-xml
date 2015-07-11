#!/usr/bin/ruby
require "libremote"
require "libframe"
require "libfield"

module CIAX
  module Frm
    include Remote
    # Command Index
    # cfg should have [:field]
    class Index < Index;end

    class Domain < Domain;end

    module Int
      include Remote::Int
      class Group < Group
        def initialize(cfg,attr={})
          super
          any={:type =>'reg',:list => ["."]}
          add_item('save',"[key,key...] [tag]",def_pars(2))
          add_item('load',"[tag]",def_pars(1))
          cmd=add_item('set',"[key(:idx)] [val(,val)]",def_pars(2))
          cmd.def_proc{|ent|
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
      class Group < Group;end
      class Item < Item;end
      class Entity < Entity
        def initialize(cfg,attr={})
          super
          @field=type?(@cfg[:field],Field)
          dbi=@cfg[:dbi]
          @fstr={}
          if /true|1/ === @cfg["noaffix"]
            @sel={:main => ["body"]}
          else
            @sel=Hash[dbi[:command][:frame]]
          end
          @frame=Frame.new(dbi['endian'],dbi['ccmethod'])
          return unless @sel[:body]=@body
          verbose("Body:#{@cfg['label']}(#@id)")
          mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.cc_mark
            mk_frame(:ccrange)
            @frame.cc_set
          end
          mk_frame(:main)
          frame=@fstr[:main]
          verbose("Cmd Generated [#@id]")
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
        dbi=Db.new.get(id)
        cfg=Config.new
        cfg[:field]=Field.new.set_db(dbi)
        cobj=Index.new(cfg)
        cobj.add_rem
        cobj.rem.def_proc{|ent| ent.cfg.path }
        cobj.rem.add_ext(dbi)
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
