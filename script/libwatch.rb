#!/usr/bin/ruby
require 'librerange'
require 'libelapse'
class Watch < Hash
  def initialize(adb,stat)
    update(adb[:watch])
    @stat=stat
    [:block,:active,:exec,:stat].each{|i|
      self[i]||=[]
    }
    self[:last]={}
    @elapse=Elapse.new(stat)
    @v=Msg::Ver.new("WATCH",3)
  end

  public
  def to_s
    Msg.view_struct(self,Watch)
  end

  def active?
    !self[:active].empty?
  end

  def block_pattern
    str=self[:active].map{|i|
      self[:block][i]
    }.compact.join('|')
    Regexp.new(str) unless str.empty?
  end

  def issue
    self[:active].map{|i|
      self[:exec][i]
    }.compact.flatten(1).uniq
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
    self[:last].keys.each{|k|
      self[:last][k]=@stat[k]
    }
    self
  end


  private
  def check(i)
    return true unless self[:stat][i]
    self[:stat][i].all?{|h|
      case k=h['ref']
      when 'elapse'
        v=@elapse.to_i
      else
        v=@stat[k]
      end
      c=h['val']
      @v.msg{"Checking [#{c}] vs <#{v}>"}
      case h['type']
      when 'onchange'
        c=self[:last][k]
      when 'regexp'
        c=Regexp.new(c)
      when 'range'
        c=ReRange.new(c)
      end
      @v.msg{"Result #{c === v}"}
        c === v
    }
  end
end

if __FILE__ == $0
  require "json"
  require "libappdb"
  abort "Usage: #{$0} (test conditions (key=val)..) < [file]" if STDIN.tty?
  hash={}
  conds,cmds=ARGV.partition{|i| i.include?("=")}
  conds.each{|s|
    k,v=s.split("=")
    hash[k]=v
  }
  cmd=cmds.join(" ")
  ARGV.clear
  str=gets(nil) || exit
  view=JSON.load(str)
  begin
    adb=AppDb.new(view['app_type'])
  rescue SelectID
    Msg.exit
  end
  watch=Watch.new(adb,view['stat'].update(hash)).upd
  puts watch.to_s
  print "Active? : "
  p watch.active?
  print "Block Pattern : "
  p watch.block_pattern
  print "Issue Commands : "
  p watch.issue
  print "Interrupt : "
  p watch.interrupt
end
