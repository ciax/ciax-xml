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
    (self[:active] - self[:interrupt]).map{|i|
      self[:exec][i]
    }.compact.flatten(1).uniq
  end

  def interrupt
    (self[:active] & self[:interrupt]).map{|i|
      self[:exec][i]
    }.compact.flatten(1).uniq
  end

  def upd
    self[:active].clear
    self[:onchange].each_with_index{|c,i|
      next if c && @stat[c] == self[:last][c]
      self[:active] << i if check(i)
    }
    self[:onchange].compact.each{|c|
      self[:last][c]=@stat[c]
    }
    self
  end


  private
  def check(i)
    return true unless self[:stat][i]
    self[:stat][i].all?{|h|
      v=@stat[h['ref']]
      c=h['val']
      @v.msg{"Checking [#{c}] vs <#{v}>"}
      case h['type']
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
