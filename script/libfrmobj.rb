#!/usr/bin/ruby
require "libiocmd"
require "libfrmcmd"
require "libfrmrsp"

class FrmObj
  def initialize(fdb,field,iocmd)
    raise "Field is not Stat" unless field.is_a?(IoStat)
    @field=field
    raise "Command is not IoCmd" unless iocmd.is_a?(IoCmd)
    @ic=iocmd
    @cmd=FrmCmd.new(fdb,field)
    @rsp=FrmRsp.new(fdb,field)
    @v=Verbose.new("fdb".upcase)
    @v.add("== Internal Command ==")
    @v.add('set'=>"Set Value  [key(:idx)] (val)")
    @v.add('unset'=>"Remove Value  [key]")
    @v.add('load'=>"Load Field (tag)")
    @v.add('save'=>"Save Field [key,key...] (tag)")
  end

  def request(cmd) #Should be array
    return if cmd.empty?
    @v.msg{"Receive #{line}"}
    case cmd[0]
    when 'set'
      set(cmd[1..-1]).inspect
    when 'unset'
      @field.delete(cmd[1]).inspect
    when 'load'
      load(cmd[1])
    when 'save'
      save(cmd[1],cmd[2])
    else
      @cmd.setcmd(cmd)
      cid=cmd.join(':')
      @ic.snd(@cmd.getframe,'snd:'+cid)
      @rsp.setrsp(cmd){@ic.rcv('rcv:'+cid)}
      @field.save
      'OK'
    end
  rescue SelectID
    @v.list
  end

  private
  def set(cmd)
    if cmd.empty?
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    @v.msg{"CMD:set#{cmd}"}
    case cmd[0]
    when /:/
      @field.set(cmd[0],cmd[1])
    else
      @field[cmd[0]]=@field.subst(cmd[1])
    end
    "[#{cmd}] set\n"
  end

  def save(keys,tag=nil)
    unless keys
      raise UserError,"Usage: save [key,key..] (tag)\n key=#{@field.keys}"
    end
    tag=Time.now.strftime('%y%m%d-%H%M%S') unless tag
    @field.save(tag,keys.split(','))
    "[#{tag}] saved\n"
  end

  def load(tag)
    tag='' unless tag
    @field.load(tag)
    "[#{tag}] loaded"
  rescue SelectID
    raise UserError,"Usage: load (tag)\n #{$!}"
  end
end
