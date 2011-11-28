#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libcommand"
require "libmcrobj"

class McrMan
  attr_reader :prompt
  # @index=0: macro mode; @index > 0 sub macro mode(accepts y or n)
  def initialize(id)
    @par=Command.new(McrDb.new(id))
    @id=id
    @prompt="#@id[]>"
    @index=0
    @threads=McrObj.threads
    cl=Msg::List.new("Internal Command")
    cl.add("[0-9]"=>"Switch Mode")
    cl.add("list"=>"Thread list")
    @par.list.push(cl)
  end

  def upd(cmd)
    case cmd[0]
    when nil
    when 'list'
      list=@threads.map{|t| t[:cid]+'('+t[:stat]+')' }
      raise UserError,"#{list}"
    when /^[0-9]+$/
      i=cmd[0].to_i
      Msg.err("No Thread") if @threads.size < i || i < 0
      @index=i
    when /^\./
      @index=0
    else
      if @index > 0
        query(cmd[0])
      elsif Thread.list.size > 1
        Msg.err("  Another mcr is still running")
      else
        @threads.clear
        McrObj.new(@par.set(cmd))
        @index=@threads.size
      end
    end
    upd_prompt
    self
  end

  def to_s
    return '' unless current
    current[:line].map{|h|
      msg='  '*h['depth']
      case h['type']
      when 'break'
        msg << Msg.color('Proceed?',6)+":#{h['label']} ->"
        msg << Msg.color(h['result'] ? "SKIP" : "OK",2)
      when 'check'
        msg << Msg.color('Check',6)+":#{h['label']} ->"
        msg << (h['result'] ? Msg.color("OK",2) : Msg.color("NG",1))
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{h['label']} ->"
        if h['result'].nil?
          ret=h['retry'].to_i
          msg << '*'*(ret/10)+'.'*(ret % 10)
        else
          msg << (h['result'] ? Msg.color("OK",2) : Msg.color("Timeout(#{h['retry']})",1))
        end
      when 'mcr'
        msg << Msg.color("MACRO",3)+":#{h['cmd'].join(' ')}"
        msg << "(async)" if h['async']
      when 'exec'
        msg << Msg.color("EXEC",13)+":#{h['cmd'].join(' ')}(#{h['ins']})"
      end
      msg
    }.join("\n")
  end

  def current #current thread
    @threads[@index-1] if @index > 0
  end

  def commands
    @par.list.keys
  end
  private
  def query(str)
    case str
    when nil
    when /^y/i
      current.run if alive?
    when /^[s|n]/i
      current.raise(Broken) if alive?
    else
      raise SelectCMD,"Can't accept [#{str}]"
    end
  end

  def upd_prompt
    size=@threads.size
    if @index > 0
      str=Msg.color(current[:cid],5)+"[#@index/#{size}](#{current[:stat]})>"
      case current[:stat]
      when /wait/
        str << Msg.color("Proceed?(y/n)",9)
      when /run/
        str << Msg.color("('s' for stop)",9)
      end
      @prompt.replace(str)
    else
      flg=@threads.map{|t|
        case t[:stat]
        when /wait/
          '?'
        when /run/
          '&'
        when /error/
          '!'
        else
          '.'
        end
      }.join('')
      @prompt.replace("#@id[#{flg}]>")
    end
  end

  def alive?
    @index > 0 && current.alive?
  end
end
