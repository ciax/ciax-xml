#!/usr/bin/ruby
require "libfrmsh"
require "libmsg"
require "libfrmrsp"
require "libstream"
require "libsqlog"
require "libfrmcmd"

module Frm
  class Sv < Sh
    def initialize(fdb,iocmd=[])
      super(fdb)
      @field.ext_save.load
      @field.extend(Frm::Rsp).init(@cobj)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        id=fdb['id'];ver=fdb['frm_ver']
        @io.ext_logging(id,ver)
        @field.extend(SqLog::Var).extend(SqLog::Exec)
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @cobj.extend(Frm::Cmd).init(fdb,@field)
      @cobj.extend(Frm::Exe).init{|cid,frm|
        @io.snd(frm,cid)
        @field.upd{@io.rcv} && @field.save
      }
      @cobj.add_case('set'){|par|
        err?(par,"set [key(:idx)] (val)")
        @field.set(par[0],par[1]).save
      }
      @cobj.add_case('unset'){|par|
        err?(par,"unset [key(:idx)]")
        @field.unset(par.first)
      }
      @cobj.add_case('save'){|par|
        err?(par,"save [key,key..] (tag)")
        @field.savekey(par[0].split(','),par[1])
      }
      @cobj.add_case('load'){|par|
        begin
          @field.load(par.first||'')
        rescue UserError
          Msg.err("Usage: load (tag)",$!.to_s)
        end
      }
      @cobj.add_case('sleep'){|par| sleep par.first.to_i }
      extend(Int::Server)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end

    #Cmd should be array
    def exe(cmd)
      super.call
      'OK'
    end

    private
    def err?(par,str)
      Msg.err("Usage: #{str}","key=#{@field.val.keys}") if par.empty?
    end
  end
end
