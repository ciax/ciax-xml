#!/usr/bin/ruby
require 'librerange'
class Watch < Hash
  def initialize(adb,stat)
    update(adb[:watch])
    @stat=stat
    self[:last]={}
    self[:active]=[]
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
    self[:last]['int']=true
    upd
    issue
  end

  def upd
    self[:active].clear
    self[:trig].each_with_index{|t,i|
      if !t
      elsif @stat[t] != self[:last][t]
        self[:last][t]=@stat[t]
      else
        next
      end
      self[:active] << i if check(i) 
    }
  end

  private
  def check(i)
    self[:stat][i].all?{|h|
      v=@stat[h['ref']]
      c=h['val']
      case h['type']
      when 'regexp'
        Regexp.new(c) === v
      when 'range'
        ReRange.new(c) == v
      else
        c == v
      end
    }
  end
end
