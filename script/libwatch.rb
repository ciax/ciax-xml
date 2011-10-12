#!/usr/bin/ruby
require 'libmsg'
require 'libexhash'
require 'librerange'
require 'libelapse'
class Watch < ExHash
  def initialize(adb,view)
    @v=Msg::Ver.new("watch",12)
    Msg.type?(adb,AppDb)
    update(adb[:watch])
    @view=Msg.type?(view,Rview)
    [:block,:active,:exec,:stat].each{|i|
      self[i]||=[]
    }
  end

  def active?
    !self[:active].empty?
  end

  def block_pattern
    str=self[:active].map{|i|
      self[:block][i]
    }.compact.join('|')
    @v.msg{"BLOCKING:#{str}"} unless str.empty?
    Regexp.new(str) unless str.empty?
  end

  def issue
    cmds=self[:active].map{|i|
      self[:exec][i]
    }.compact.flatten(1).uniq
    @v.msg{"ISSUED:#{cmds}"}
    cmds
  end

  def interrupt
    @view.last['int']=1
    upd
    issue
  end

  def upd
    self[:active].clear
    self[:stat].size.times{|i|
      self[:active] << i if check(i)
    }
    self
  end

  private
  def check(i)
    return true unless self[:stat][i]
    @v.msg{"Check: <#{self[:label][i]}>"}
    self[:stat][i].all?{|h|
      k=h['ref']
      v=@view['stat'][k]
      c=h['val']
      case h['type']
      when 'onchange'
        res=@view.change?(k)
        @v.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'pattern'
        res=(Regexp.new(c) === v)
        @v.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'range'
        res=(ReRange.new(c) == v)
        @v.msg{"  Range(#{k}): [#{c}] vs <#{v.to_i}>(#{v.class}) =>#{res}"}
      end
      res
    }
  end
end

if __FILE__ == $0
  require "librview"
  require "libinsdb"
  abort "Usage: #{$0} (test conditions (key=val)..) < [file]" if STDIN.tty?
  hash={}
  ARGV.each{|s|
    k,v=s.split("=")
    hash[k]=v
  }
  ARGV.clear
  view=Rview.new.upd
  begin
    adb=InsDb.new(view['id']).cover_app
  rescue SelectID
    Msg.exit
  end
  watch=Watch.new(adb,view).upd
  view.upd(hash)
  puts watch.upd.to_s
  print "Active? : "
  p watch.active?
  print "Block Pattern : "
  p watch.block_pattern
  print "Issue Commands : "
  p watch.issue
  print "Interrupt : "
  p watch.interrupt
end
