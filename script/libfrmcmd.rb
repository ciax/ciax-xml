#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libcmdext"

# Cmd Methods
module CIAX
  module Frm
    class Command < ExtCmd
      def initialize(fdb,field=Field::Var.new)
        @field=Msg.type?(field,Field::Var)
        super(fdb)
        any={:type =>'reg',:list => ["."]}
        ig=self['sv']['int']
        ig.add_item('save',"Save Field [key,key...] (tag)",[any,any])
        ig.add_item('load',"Load Field (tag)",[any])
        set=ig.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
        set.def_proc=proc{|item|
          field.set(*item.par)
        }
      end

      private
      def extgrp(fdb)
        ExtGrp.new(fdb,@field)
      end
    end

    class ExtGrp < ExtGrp
      def initialize(db,field=Field::Var.new)
        @field=Msg.type?(field,Field::Var)
        super(db)
      end

      private
      def extitem(id)
        ExtItem.new(@field,@db,id,@def_proc)
      end
    end

    class ExtItem < ExtItem
      def initialize(field,db,id,def_proc)
        @ver_color=0
        @field=Msg.type?(field,Field::Var)
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
            @field['val']['cc']=@frame.checkcode
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
  end

  if __FILE__ == $0
    require "libfield"
    require "libfrmdb"
    dev,*cmd=ARGV
    ARGV.clear
    begin
      fdb=Frm::Db.new.set(dev)
      field=Field::Var.new
      cobj=Frm::Command.new(fdb,field)
      cgrp=cobj['sv']['ext']
      field.load unless STDIN.tty?
      print cgrp.setcmd(cmd).getframe
    rescue InvalidCMD
      Msg.usage("[dev] [cmd] (par) < field_file",[])
    rescue InvalidID
      Msg.usage "[dev] [cmd] (par) < field_file"
    end
  end
end
