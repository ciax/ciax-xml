#!/usr/bin/ruby
require 'libmsg'
require 'libmodexh'
require 'librerange'
require 'libelapse'
require 'yaml'

class Watch < Hash
  include ModExh
  def initialize(adb,view)
    @v=Msg::Ver.new("watch",12)
    Msg.type?(adb,AppDb)
    deep_update(adb[:watch])
    @view=Msg.type?(view,Rview)
    [:block,:active,:exec,:stat].each{|i|
      self[i]||=[]
    }
    self['time']=Time.now.to_i
    @elapse=Elapse.new(self)
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
    @view.last['int']=nil
    issue
  end

  def upd
    self['time']=Time.now.to_f
    self[:active].clear
    self[:stat].size.times{|i|
      self[:active] << i if check(i)
    }
    @view.refresh
    self
  end

  def to_s
    str="  "+Msg.color("Last update",5)+":#{@elapse}\n"
    self[:stat].size.times{|i|
      res=self[:active].include?(i)
      str << "  "+Msg.color(self[:label][i],6)+': '
      str << show_res(res)+"\n"
      if res
        if self[:block][i]
          str << "    "+Msg.color("Block",3)
          str << ": /#{self[:block][i]}/\n"
        end
        self[:exec][i].each{|k|
          str << "    "+Msg.color("Issued",3)+": #{k}\n"
        }
      else
        self[:stat][i].each{|n|
          str << "    "+show_res(n['res'],'o','x')+' '
          str << Msg.color(n['ref'],3)
          str << " (#{n['type']}"
          if n['type'] != 'onchange'
            str << "=#{n['val'].inspect},actual=#{n['act'].inspect}"
          end
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
    self[:stat][i].all?{|h|
      k=h['ref']
      c=h['val']
      v=h['act']=@view.stat(k)
      case h['type']
      when 'onchange'
        res=@view.change?(k)
        @v.msg{"  onChange(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'pattern'
        res=(Regexp.new(c) === v)
        @v.msg{"  Pattrn(#{k}): [#{c}] vs <#{v}> =>#{res}"}
      when 'range'
        f=h['act']="%.3f" % v.to_f
        res=(ReRange.new(c) == f)
        @v.msg{"  Range(#{k}): [#{c}] vs <#{f}>(#{v.class}) =>#{res}"}
      end
      h['res']=res
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
  puts YAML.dump(watch[:stat])
  puts watch.upd
end
