#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "libmcrobj"

class McrMan
  attr_reader :prompt
  # @index=0: macro mode; @index > 0 sub macro mode(accepts y or n)
  def initialize(id)
    @par=Param.new(McrDb.new(id))
    @id=id
    @prompt="#@id[0]>"
    @index=0
    @threads=McrObj.threads
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add("[0-9]"=>"Switch Mode")
    @cl.add("list"=>"Thread list")
  end

  def exec(cmd)
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
        McrObj.new(@par.set(cmd))
        @index=@threads.size
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    @cl.error
  end

  def to_s
    cth.to_s
  end

  private
  def query(str)
    case str
    when nil
    when /^y/i
      cth.run if alive?
    when /^[s|n]/i
      cth.raise(Broken) if alive?
    else
      raise SelectCMD,"Can't accept [#{str}]"
    end
  end

  def upd_prompt
    size=@threads.size
    if @index > 0
      str="#{cth[:cid]}[#@index/#{size}](#{cth[:stat]})>"
      str << Msg.color("Proceed?(y/n)",9) if /wait/ === cth[:stat]
      @prompt.replace(str)
    else
      @prompt.replace("#@id[#{size}]>")
    end
  end

  def alive?
    @index > 0 && cth.alive?
  end

  def cth #current thread
    @threads[@index-1] if @index > 0
  end
end
