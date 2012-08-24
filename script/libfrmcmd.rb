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

    def init(field,db)
      @field=Msg.type?(field,Field::Var)
      @cache={}
      @fstr={}
      @sel=Hash[db[:cmdframe][:frame]]
      @frame=Frame.new(db['endian'],db['ccmethod'])
      self
    end

    def add_proc
      @exelist << proc{
        yield getframe,self[:cid]
        'OK'
      }
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

class Command::Domain
  def ext_frmcmd(field)
    values.each{|item|
      item.extend(Frm::Cmd).init(field,@db)
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
    fdb=Frm::Db.new(dev)
    field=Field::Var.new
    cobj=Command.new
    cobj.add_ext(fdb,:cmdframe).ext_frmcmd(field)
    field.load unless STDIN.tty?
    print cobj.set(cmd).getframe
  rescue UserError
    Msg.usage "[dev] [cmd] (par) < field_file"
  end
end
