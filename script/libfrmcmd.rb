#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libextcmd"

# Cmd Methods
module CIAX
  module Frm
    class ExtCmd < ExtCmd
      def initialize(db,field=Field.new)
        super(db)
        self['sv'].cfg[:field]=type?(field,Field)
        add_svgrp('int',IntGrp)
        add_svgrp('ext',ExtGrp)
      end
    end

    class IntGrp < Group
      def initialize(upper)
        super
        @cfg['caption']='Internal Commands'
        any={:type =>'reg',:list => ["."]}
        add_item('save',"Save Field [key,key...] (tag)",[any,any])
        add_item('load',"Load Field (tag)",[any])
        add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any]).set_proc{|item|
          @cfg[:field].set(*item.par)
        }
      end
    end

    class ExtGrp < ExtGrp
      def new_item(crnt)
        ExtItem.new(@cfg,crnt)
      end
    end

    class ExtItem < ExtItem
      def initialize(upper,crnt)
        @ver_color=0
        super(upper,crnt)
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
        self
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
        fdb=Db.new.set(dev)
        field=Field.new
        cobj=ExtCmd.new(fdb,field)
        cgrp=cobj['sv']['ext']
        field.read unless STDIN.tty?
        print cgrp.setcmd(args).cfg[:frame]
      rescue InvalidCMD
        Msg.usage("[dev] [cmd] (par) < field_file",[])
      rescue InvalidID
        Msg.usage "[dev] [cmd] (par) < field_file"
      end
    end
  end
end
