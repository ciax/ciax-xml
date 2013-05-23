#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libcmdext"
# Cmd Methods
module Frm
  class ExtGrp < Command::ExtGrp
    def initialize(db,field=Field::Var.new)
      @field=Msg.type?(field,Field::Var)
      super(db)
    end

    private
    def extitem(id)
      ExtItem.new(@field,@db,id,@def_proc)
    end
  end

  class ExtItem < Command::ExtItem
    def initialize(field,db,id,def_proc)
      init_ver('FrmCmd',9)
      @field=Msg.type?(field,Field::Var)
      cdb=db[:command]
      super(cdb,id,def_proc)
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
      #    verbose{"Attr of Command:#{self}"}
      cmd=self[:cmd]
      verbose{"Select:#{self[:label]}(#{cmd})"}
      if frame=@cache[cmd]
        verbose{"Cmd cache found [#{cmd}]"}
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
    cobj=Command.new
    svdom=cobj.add_domain('sv')
    svdom['ext']=Frm::ExtGrp.new(fdb,field)
    field.load unless STDIN.tty?
    print cobj.setcmd(cmd).getframe
  rescue InvalidCMD
    Msg.usage("[dev] [cmd] (par) < field_file",[])
  rescue InvalidID
    Msg.usage "[dev] [cmd] (par) < field_file"
  end
end
