#!/usr/bin/ruby
require "libiocmd"
require "libfrmcmd"
require "libfrmrsp"

class FrmObj < String
  attr_reader :field
  def initialize(fdb,field,iocmd)
    raise "Input is not Field" unless field.is_a?(Field)
    @field=field
    raise "Command is not IoCmd" unless iocmd.is_a?(IoCmd)
    @ic=iocmd
    @cmd=FrmCmd.new(fdb,field)
    @rsp=FrmRsp.new(fdb,field)
    @v=Msg::Ver.new("fdb".upcase)
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('set'=>"Set Value  [key(:idx)] (val)")
    @cl.add('unset'=>"Remove Value  [key]")
    @cl.add('load'=>"Load Field (tag)")
    @cl.add('save'=>"Save Field [key,key...] (tag)")
  end

  def request(cmd) #Should be array
    if cmd.empty?
      replace yield.to_s
    else
      @v.msg{"Receive #{cmd}"}
      case cmd[0]
      when 'set'
        replace set(cmd[1..-1]).inspect
      when 'unset'
        replace @field.delete(cmd[1]).inspect
      when 'load'
        replace load(cmd[1])
      when 'save'
        replace save(cmd[1],cmd[2])
      else
        cid=cmd.join(':')
        @ic.snd(@cmd.getframe(cmd),'snd:'+cid)
        @rsp.setrsp(cmd){@ic.rcv('rcv:'+cid)}
        @field.save
        replace 'OK'
      end
    end
    self
  rescue SelectCMD
    raise SelectCMD,@cl.to_s
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
    hash={}
    keys.split(',').compact.each{|k|
      hash[k]=@field[k] if @field.key?(k)
    }
    if hash.empty?
      "Key Empty"
    else
      @field.save(tag,hash)
      "[#{tag}](#{hash.keys.join(',')}) saved\n"
    end
  end

  def load(tag)
    tag='' unless tag
    @field.load(tag)
    "[#{tag}] loaded"
  rescue UserError
    raise UserError,"Usage: load (tag)\n #{$!}"
  end
end
