#!/usr/bin/ruby
require "libframe"
require "libcmdext"
# Cmd Methods
module Frm
  module Cmd
    def self.extended(obj)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_frmcmd(field,db)
      init_ver('FrmCmd',9)
      verbose{"Extending Command by Frm::Cmd"}
      @field=Msg.type?(field,Field::Var)
      @cache={}
      @fstr={}
      cdb=db[:cmdframe]
      if cdb.key?(:noaffix) && /true|1/ === cdb[:noaffix][@id]
        @sel={:main => ["select"]}
      else
        @sel=Hash[cdb]
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

module Command::SvDom
  def ext_frmcmd(field)
    ext_item{|item|
      item.extend(Frm::Cmd).ext_frmcmd(field,@db)
    }
    self
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
    cobj.add_svdom(fdb).ext_frmcmd(field)
    field.load unless STDIN.tty?
    print cobj.setcmd(cmd).getframe
  rescue InvalidCMD
    Msg.usage("[dev] [cmd] (par) < field_file",[])
  rescue InvalidID
    Msg.usage "[dev] [cmd] (par) < field_file"
  end
end
