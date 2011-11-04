#!/usr/bin/ruby
require 'libmsg'
require 'librerange'
require 'libelapse'
class Watch < Hash
  def initialize(adb,view)
    @v=Msg::Ver.new("watch",12)
    Msg.type?(adb,AppDb)
    update(adb[:watch])
    @view=Msg.type?(view,Rview)
    [:block,:active,:exec,:stat].each{|i|
      self[i]||=[]
    }
    @conds=[]
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
    @v.msg{"ISSUED:#{cmds}"} unless cmds.empty?
    cmds
  end

  def interrupt
    @view.last['int']=1
    upd
    issue
  end

  def upd
    @conds.clear
    self[:active].clear
    self[:stat].size.times{|i|
      self[:active] << i if check(i)
    }
    self
  end

  def to_s
    str=''
    @conds.size.times{|i|
      res=self[:active].include?(i)
      str << Msg.color(self[:label][i],6)
      str << ":#{self[:active][i]}"
      str << show_res(res)+"\n"
      if res
        str << "   Block:/#{self[:block][i]}/\n" if self[:block][i]
        self[:exec][i].each{|k|
          str << "   Cmd:#{k}\n"
        }
      else
        @conds[i].each{|n|
          str << "    "+show_res(n['res'],'o','x')+' '
          str << Msg.color(n['ref'],3)
          str << "(#{n['type']}"
          str << "/#{n['val']}" if n['type'] != 'onchange'
          str << ")\n"
        }
      end
    }
    str
  end

  private
  def show_res(res,t=nil,f=nil)
    res ? Msg.color(t||res,2) : Msg.color(f||res,1)
  end

  def check(i)
    return true unless self[:stat][i]
    @v.msg{"Check: <#{self[:label][i]}>"}
    @conds << []
    self[:stat][i].all?{|h|
      k=h['ref']
      v=@view.stat(k)
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
      @conds.last << {'act'=>v,'res'=>res}.update(h)
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
  view=Rview.new.load
  begin
    adb=InsDb.new(view['id']).cover_app
  rescue SelectID
    Msg.exit
  end
  watch=Watch.new(adb,view).upd
  # For on change
  view.set(hash)
  # Print Wdb
  puts watch.upd
end
