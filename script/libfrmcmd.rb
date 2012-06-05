#!/usr/bin/ruby
require "libframe"
require "libcommand"
# Cmd Methods
module Frm
  module Cmd
    extend Msg::Ver
    def self.extended(obj)
      init_ver('FrmCmd',9)
      Msg.type?(obj,Command::Item)
    end

    def init(fdb,field)
      Msg.type?(fdb,Frm::Db)
      @field=Msg.type?(field,Field::Var)
      @cache={}
      @fstr={}
      @sel=Hash[fdb[:cmdframe][:frame]]
      @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
      @exelist << proc{
        yield self[:cid],getframe
        'OK'
      }
      self
    end

    def getframe # return = response select
      return unless @sel[:select]=@select
      #    Cmd.msg{"Attr of Command:#{self}"}
      cid=self[:cid]
      Cmd.msg{"Select:#{self[:label]}(#{cid})"}
      if frame=@cache[cid]
        Cmd.msg{"Cmd cache found [#{cid}]"}
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
    cobj=Command.new(fdb[:cmdframe]).set(cmd)
    field=Field::Var.new
    cobj.extend(Frm::Cmd).init(fdb,field)
    field.load unless STDIN.tty?
    print cobj.getframe
  rescue UserError
    Msg.usage "[dev] [cmd] (par) < field_file"
  end
end
