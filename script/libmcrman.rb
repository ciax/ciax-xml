#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "libmcrobj"

class McrMan
  attr_reader :prompt
  # @current=0: macro mode; @current > 0 sub macro mode(accepts y or n)
  def initialize(id)
    @par=Param.new(McrDb.new(id))
    @id=id
    @prompt="#@id>"
    @current=0
    @threads=McrObj.threads
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add("[0-9]"=>"Switch Mode")
    @cl.add("list"=>"Thread list")
  end

  def exec(cmd)
    case cmd[0]
    when nil
    when 'list'
      raise UserError,"#{@threads}"
    when /^[0-9]+$/
      i=cmd[0].to_i
      Msg.err("No Thread") if @threads.size < i || i < 0
      @current=i
    else
      if @current > 0
        query(cmd[0]) 
      else
        McrObj.new(@par.set(cmd))
        @current=@threads.size
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    @cl.error
  end

  def to_s
    current.to_s
  end

  private
  def query(str)
    case str
    when nil
    when /^y/i
      current.run if alive?
    when /^[s|n]/i
      current.kill if alive?
    else
      raise SelectCMD,"No such cmd [#{str}]"
    end
  end

  def upd_prompt
    if @current > 0
      stat=alive? ? current.prompt : "(done)>"
      @prompt.replace("#@id[#@current]#{stat}")
    else
      @prompt.replace("#@id>")
    end
  end

  def alive?
    current && current.alive?
  end

  def current
    @threads[@current-1] if @current > 0
  end
end
