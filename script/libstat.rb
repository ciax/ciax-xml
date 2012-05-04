#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libvar"

class Stat < Var
  def initialize
    super('stat')
    @last={}
  end

  def set(hash) #For Watch test
    @val.update(hash)
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{@val[id]}] vs last=[#{@last[id]}]"}
    @val[id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    @v.msg{"Status Updated"}
    @last.update(@val)
  end
end

# Status to Stat::SymConv (String with attributes)
module Stat::SymConv
  require "libsymdb"
  def self.extended(obj)
    Msg.type?(obj,Stat)
  end

  def init(adb,val)
    @id=adb['id']
    ads=Msg.type?(adb,App::Db)[:status]
    self.ver=adb['app_ver'].to_i
    self.val=Msg.type?(val,App::Val)
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.pack(['all',ads['table']])
    self['class']={'time' => 'normal'}
    self['msg']={}
    self
  end

  def upd
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid.to_sym]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      self['class'][key]='alarm'
      self['msg'][key]='N/A'
      val=@val[key]
      tbl.each{|sym|
        case sym['type']
        when 'range'
          next unless ReRange.new(sym['val']) == val
          @v.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
          self['msg'][key]=sym['msg']+"(#{val})"
        when 'pattern'
          next unless /#{sym['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
          self['msg'][key]=sym['msg']
        end
        self['class'][key]=sym['class']
        break
      }
    }
    stime=@val['time'].to_f
    self['msg']['time']=Time.at(stime).to_s
    @v.msg{"Update(#{stime})"}
    super
  end
end

module Stat::IoFile
  include IoFile
  def self.extended(obj)
    Msg.type?(obj,Stat::SymConv).init
  end

  def init
    super(@id)
    @lastsave=0
    self
  end

  def save
    time=@val['time'].to_f
    if time > @lastsave
      super
      @lastsave=time
      true
    end
  end
end

module Stat::SqLog
  require "libsqlog"
  def self.extended(obj)
    Msg.type?(obj,Stat::IoFile).init
  end

  def init
    # Logging if version number exists
    @sql=SqLog.new('value',@id,@ver,@val).extend(SqLog::Exec)
    @post_upd << proc {@sql.upd}
  end

  def save
    super && @sql.save
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libfield"
  begin
    id=ARGV.shift
    host=ARGV.shift
    ARGV.clear
    idb=InsDb.new(id).cover_app
    stat=Stat.new
    if STDIN.tty?
      if host
        puts stat.extend(InUrl).init(id,host).load
      else
        puts stat.extend(InFile).init(id).load
      end
    else
      field=Field.new.load
      val=App::Val.new(idb,field)
      stat.extend(Stat::SymConv).init(idb,val)
      print stat.upd.to_j
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
end
