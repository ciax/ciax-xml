#!/usr/bin/ruby
require "libframe"
require "libparam"
# Cmd Methods
class FrmCmd
  def initialize(fdb,par,field)
    @v=Msg::Ver.new("frm/cmd",3)
    @field=field
    @par=par
    @cache={}
    @fstr={}
    @sel=Hash[fdb[:command][:frame]]
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
  end

  def getframe # return = response select
    return unless @sel[:select]=@par[:select]
    @v.msg{"Attr of Param:#{@par}"}
    cid=@par[:command]
    cid+=':*' if /true|1/ === @par[:nocache]
    @v.msg{"Select:#{@par[:label]}(#{cid})"}
    if frame=@cache[cid]
      @v.msg{"Cmd cache found [#{cid}]"}
    else
      mk_frame(:select)
      if @sel.key?(:ccrange)
        @frame.mark
        mk_frame(:ccrange)
        @field['cc']=@frame.checkcode
      end
      frame=mk_frame(:main)
      @cache[cid]=frame unless /\*/ === cid
    end
    frame
  end

  private
  def mk_frame(domain)
    @frame.set
    @sel[domain].each{|a|
      case a
      when Hash
        @field.subst(@par.subst(a['val'])).split(',').each{|s|
          @frame.add(s,a)
        }
      else # ccrange,select,..
        @frame.add(@fstr[a.to_sym])
      end
    }
    @fstr[domain]=@frame.copy
  end
end

if __FILE__ == $0
  require "libfield"
  require "libfrmdb"
  dev,*cmd=ARGV
  begin
    fdb=FrmDb.new(dev,cmd.empty?)
    par=Param.new(fdb[:command],:select)
    field=Field.new
    fc=FrmCmd.new(fdb,par,field)
    if ! STDIN.tty? && str=STDIN.gets(nil)
      field.update_j(str)
    end
    par.set(cmd)
    print fc.getframe
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [dev] [cmd] (par) < field_file"
    Msg.exit
  end
end
