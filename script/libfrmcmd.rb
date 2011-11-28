#!/usr/bin/ruby
require "libframe"
require "libcommand"
# Cmd Methods
class FrmCmd
  def initialize(fdb,par,field)
    @v=Msg::Ver.new("frm/cmd",3)
    Msg.type?(fdb,FrmDb)
    @par=Msg.type?(par,Command)
    @field=Msg.type?(field,Field)
    @cache={}
    @fstr={}
    @sel=Hash[fdb[:cmdframe][:frame]]
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
  end

  def getframe # return = response select
    return unless @sel[:select]=@par[:select]
    @v.msg{"Attr of Command:#{@par}"}
    cid=@par[:cid]
    @v.msg{"Select:#{@par[:label]}(#{cid})"}
    if frame=@cache[cid]
      @v.msg{"Cmd cache found [#{cid}]"}
    else
      mk_frame(:select) && cid=nil
      if @sel.key?(:ccrange)
        @frame.mark
        mk_frame(:ccrange)
        @field['cc']=@frame.checkcode
      end
      mk_frame(:main)
      frame=@fstr[:main]
      @cache[cid]=frame if cid
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
    fdb=FrmDb.new(dev,cmd.empty?)
    par=Command.new(fdb[:cmdframe])
    field=Field.new
    fc=FrmCmd.new(fdb,par,field)
    field.load unless STDIN.tty?
    par.set(cmd)
    print fc.getframe
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [dev] [cmd] (par) < field_file"
    Msg.exit
  end
end
