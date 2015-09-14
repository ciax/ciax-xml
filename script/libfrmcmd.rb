#!/usr/bin/ruby
require "libremote"
require "libframe"
require "libfield"

module CIAX
  module Frm
    include Remote
    # cfg should have [:field]
    module Int
      class Group < Remote::Int::Group
        def initialize(cfg,attr={})
          super
          any={:type =>'reg',:list => ["."]}
          add_item('save',"[key,key...] [tag]",def_pars(2))
          add_item('load',"[tag]",def_pars(1))
          add_item('set',"[key(:idx)] [val(,val)]",def_pars(2))
          add_item('flush',"Stream")
        end
      end
    end

    module Ext
      include Remote::Ext
      class Group < Ext::Group;end
      class Item < Ext::Item;end
      class Entity < Ext::Entity
        def initialize(cfg,attr={})
          super
          @field=type?(@cfg[:field],Field)
          @fstr={}
          if /true|1/ === @cfg["noaffix"]
            @sel={:main => ["body"]}
          else
            @sel=Hash[@dbi[:command][:frame]]
          end
          @frame=Frame.new(@dbi['endian'],@dbi['ccmethod'])
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
      GetOpts.new('r')
      id,*args=ARGV
      ARGV.clear
      begin
        dbi=Db.new.get(id)
        cfg=Config.new
        fld=cfg[:field]=Field.new.set_db(dbi)
        cobj=Index.new(cfg,{:dbi => dbi})
        cobj.add_rem.def_proc{|ent| ent.cfg[:frame]}
        cobj.rem.add_ext(Ext)
        fld.read unless STDIN.tty?
        res=cobj.set_cmd(args).exe_cmd('test')
        puts($opt['r'] ? res : res.inspect)
      rescue InvalidCMD
        $opt.usage("#{id} [cmd] (par) < field_file")
      rescue InvalidID
        $opt.usage("[dev] [cmd] (par) < field_file")
      end
    end
  end
end
