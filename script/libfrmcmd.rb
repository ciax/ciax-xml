#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libextcmd"

# Cmd Methods
module CIAX
  module Frm
    class ExtCmd < Command
      def initialize(fdb,field=Field.new)
        type?(field,Field)
        super()
        any={:type =>'reg',:list => ["."]}
        ig=self['sv']['int']
        ig.add_item('save',"Save Field [key,key...] (tag)",[any,any])
        ig.add_item('load',"Load Field (tag)",[any])
        set=ig.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
        set.def_proc=proc{|item|
          field.set(*item.par)
        }
        self['sv']['ext']=ExtGrp.new(fdb){|id,def_proc|
          ExtItem.new(field,fdb,id,def_proc)
        }
      end
    end

    class ExtItem < ExtItem
      def initialize(field,db,id,def_proc)
        @ver_color=0
        @field=type?(field,Field)
        super(db,id,def_proc)
        cdb=db[:command]
        @cache={}
        @fstr={}
        if cdb.key?(:noaffix) && /true|1/ === cdb[:noaffix][@id]
          @sel={:main => ["select"]}
        else
          @sel=Hash[db[:cmdframe]]
        end
        @frame=Frame.new(db['endian'],db['ccmethod'])
        self
      end

      def getframe # return = response select
        return unless @sel[:select]=@select
        cmd=self[:cmd]
        verbose("FrmItem","Select:#{self[:label]}(#{cmd})")
        if frame=@cache[cmd]
          verbose("FrmItem","Cmd cache found [#{cmd}]")
        else
          nocache=mk_frame(:select)
          if @sel.key?(:ccrange)
            @frame.mark
            mk_frame(:ccrange)
            @field.set('cc',@frame.checkcode)
          end
          mk_frame(:main)
          frame=@fstr[:main]
          @cache[cmd]=frame unless nocache
        end
        frame
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
          else # ccrange,select,..
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
      dev,*cmd=ARGV
      ARGV.clear
      begin
        fdb=Db.new.set(dev)
        field=Field.new
        cobj=ExtCmd.new(fdb,field)
        cgrp=cobj['sv']['ext']
        field.read unless STDIN.tty?
        print cgrp.setcmd(cmd).getframe
      rescue InvalidCMD
        Msg.usage("[dev] [cmd] (par) < field_file",[])
      rescue InvalidID
        Msg.usage "[dev] [cmd] (par) < field_file"
      end
    end
  end
end
