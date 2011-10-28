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
  end

  def exec(cmd)
    case cmd[0]
    when nil
    when 'list'
      raise UserError,"#{@threads}"
    when /^[0-9]+$/
      i=cmd[0].to_i
      raise(UserError,"No Thread") if @threads.size < i || i < 0
      @current=i
    else
      if @current > 0
        query(cmd[0]) if alive?
      else
        McrObj.new(@par.set(cmd))
        @current=@threads.size
      end
    end
    if @current > 0
      stat=alive? ? current.prompt : "(done)>"
      @prompt.replace("#@id[#@current]#{stat}")
    else
      @prompt.replace("#@id>")
    end
    self
  end

  def query(str)
    case str
    when /^y/i
      current.run
    when /^n/i
      current.kill
    end
  end

  def alive?
    current && current.alive?
  end

  def current
    @threads[@current-1] if @current > 0
  end

  def to_s
    current.to_s
  end
end
