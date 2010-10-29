#!/usr/bin/ruby
require "libdev"
require "thread"

class DevBg < Dev
  attr_reader :issue,:errmsg

  def initialize(dev,id,iocmd)
    super(dev,id,iocmd)
    @errmsg=[]
    @issue=''
    @q=Queue.new
    Thread.new {
      loop {
        stm=@q.shift
        @issue='*'
        begin
          devcom(stm)
          yield(field)
        rescue
          @errmsg << $!.to_s
        ensure
          @issue=''
        end
      }
    }
  end

  def push(stm)
    @q.push(stm)
  end

  def empty?
    @q.empty?
  end
end
