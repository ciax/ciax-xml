#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libstat"
require "libdevcmd"
require "libdevrsp"

# Main
class Dev < Stat
  def initialize(id)
    super()
    begin
      @fd=IoFile.new("field_#{id}")
      @stat=@fd.load_stat
    rescue
      warn "----- Create field_#{id}.mar"
    end
    @stat['id']=id
  end

  def load(tag='default')
    @stat.update(@fd.load_stat(tag))
  end

  def save_all
    @fd.save_stat(@stat)
  end

  def save(stat,tag='default')
    @fd.save_stat(stat,tag)
  end
end

class DevCom
  attr_reader :field

  def initialize(dev,id,iocmd)
    @ddb=XmlDoc.new('ddb',dev)
  rescue RuntimeError
    abort $!.to_s
  else
    @dvar=Dev.new(id)
    @cmd=DevCmd.new(@ddb,@dvar)
    @rsp=DevRsp.new(@ddb,@dvar)
    @v=Verbose.new("ddb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
    @field=@dvar.stat
  end

  def devcom(stm)
    @cmd.setcmd(stm)
    @rsp.setrsp(stm)
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm)
    when 'load'
      @dvar.load(stm.shift)
    when 'save'
      save(stm.shift,stm.shift)
    else
      msg=[$!.to_s]
      msg << "== Data Handling =="
      msg << " set       : Set Value  [key(:idx)(=val)]"
      msg << " load      : Load Field (tag)"
      msg << " save      : Save Field [key,key...] (tag)"
      raise SelectID,msg.join("\n")
    end
  else
    cid=stm.join(':')
    @ic.snd(@cmd.getframe,'snd:'+cid)
    @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
    @dvar.save_all
  end

  def set(stm)
    if stm.empty?
      msg=["== Option list =="]
      msg << " key(:idx)  : Show Value"
      msg << " key(:idx)= : Set Value"
      msg << " key=#{@field.keys}"
      raise SelectID,msg.join("\n")
    end
    @v.msg{"CMD:set#{stm}"}
    stat={}
    stm.each{|e|
      key,val=e.split('=')
      h=@dvar.acc_stat(key)
      h.replace(eval(@dvar.sub_stat(val)).to_s) if val
      stat[key]=@field[key]
    }
    stat
  end
 
  def save(keys=nil,tag='default')
    raise("key=#{@field.keys}") unless keys
    stat={}
    keys.split(',').each{|k|
      s=@field[k] || raise("No such key[#{k}]")
      stat[k]=s
    }
    @dvar.save(stat,tag)
  end
end
