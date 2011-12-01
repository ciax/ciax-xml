#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libcommand"
require "libmcrsub"
require "libmcrprt"

class McrMan
  attr_reader :prompt
  # @index=0: macro mode; @index > 0 sub macro mode(accepts y or n)
  def initialize(id)
    @cobj=Command.new(McrDb.new(id))
    flg=['test','local','exe'][ENV['ACT'].to_i]
    @id="#{id}(#{flg})"
    @prompt="#@id[]>"
    @index=0
    @threads=[]
    @mcr=McrSub.new(@cobj,@threads).extend(McrPrt)
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
        @mcr.macro(cmd,true)
        Thread.pass
        @index=1
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    cl=Msg::List.new("Internal Command")
    cl.add("[0-9]"=>"Switch Mode")
    cl.add("list"=>"Thread list")
    cl.error
  end

  def to_s
    return '' unless current
    current[:obj].to_s
  end

  def current #current thread
    @threads[@index-1] if @index > 0
  end

  def commands
    @cobj.list.keys
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
      str=Msg.color(current[:cid],5)
      str << "[#@index/#{size}](#{current[:stat]})>"
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
