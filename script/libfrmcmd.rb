#!/usr/bin/ruby
require "libframe"
require "libcommand"
# Cmd Methods
module Frm
  class Cmd
    def initialize(fdb,cobj,field)
      @v=Msg::Ver.new(self,3)
      Msg.type?(fdb,Frm::Db)
      @cobj=Msg.type?(cobj,Command)
      @field=Msg.type?(field,Field)
      @cache={}
      @fstr={}
      @sel=Hash[fdb[:cmdframe][:frame]]
      @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
    end

    def getframe # return = response select
      return unless @sel[:select]=@cobj[:select]
      #    @v.msg{"Attr of Command:#{@cobj}"}
      cid=@cobj[:cid]
      @v.msg{"Select:#{@cobj[:label]}(#{cid})"}
      if frame=@cache[cid]
        @v.msg{"Cmd cache found [#{cid}]"}
      else
        mk_frame(:select) && cid=nil
        if @sel.key?(:ccrange)
          @frame.mark
          mk_frame(:ccrange)
          @field.val['cc']=@frame.checkcode
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
end

if __FILE__ == $0
  require "libfield"
  require "libfrmdb"
  dev,*cmd=ARGV
  ARGV.clear
  begin
    fdb=Frm::Db.new(dev)
    cobj=Command.new(fdb[:cmdframe])
    field=Field.new
    fc=Frm::Cmd.new(fdb,cobj,field)
    field.load unless STDIN.tty?
    cobj.set(cmd)
    print fc.getframe
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    Msg.usage "[dev] [cmd] (par) < field_file"
  end
end
