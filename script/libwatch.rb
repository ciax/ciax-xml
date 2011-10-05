#!/usr/bin/ruby
require 'libmsg'
require 'libexhash'
require 'librerange'
require 'libelapse'
class Watch < ExHash
  def initialize(adb,stat)
    @v=Msg::Ver.new("watch",12)
    update(adb[:watch])
    @stat=stat
    [:block,:active,:exec,:stat].each{|i|
      self[i]||=[]
    }
    self[:last]={}
    @elapse=Elapse.new(stat)
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
    self[:last]['int']=1
    upd
    issue
  end

  def upd
    self[:active].clear
    self[:stat].size.times{|i|
      self[:active] << i if check(i)
    }
    self[:last].replace(@stat)
    self
  end


  private
  def check(i)
    return true unless self[:stat][i]
    @v.msg{"Check: <#{self[:label][i]}>"}
    self[:stat][i].all?{|h|
      case k=h['ref']
      when 'elapse'
        v=@elapse.to_i
      else
        v=@stat[k]
      end
      c=h['val']
      case h['type']
      when 'onchange'
        c=self[:last][k]
        res=(c != v)
        @v.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'pattern'
        res=(Regexp.new(c) === v)
        @v.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'range'
        res=(ReRange.new(c) == v)
        @v.msg{"  Range(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      end
      res
    }
  end
end

if __FILE__ == $0
  require "json"
  require "libinsdb"
  abort "Usage: #{$0} (test conditions (key=val)..) < [file]" if STDIN.tty?
  hash={}
  ARGV.each{|s|
    k,v=s.split("=")
    hash[k]=v
  }
  ARGV.clear
  str=gets(nil) || exit
  view=JSON.load(str)
  begin
    idb=InsDb.new(view['id']).cover_app
  rescue SelectID
    Msg.exit
  end
  stat=view['stat']
  watch=Watch.new(idb,stat).upd
  stat.update(hash)
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
