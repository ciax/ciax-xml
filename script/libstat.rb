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
  include IoFile
  def init(adb)
    super(adb['id'])
    ads=Msg.type?(adb,AppDb)[:status]
    self['ver']=adb['app_ver'].to_i
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.pack(['all',ads['table']])
    self['class']={'time' => 'normal'}
    self['msg']={}
    @lastsave=0
    self
  end

  def upd
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid]
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
    Msg.type?(obj,Stat::SymConv).init
  end

  def init
    # Logging if version number exists
    @sql=SqLog::Logging.new('value',self['id'],self['ver'],@val)
    self
  end

  def upd
    super
    @sql.upd
    self
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
    if STDIN.tty?
      if host
        puts Stat.new.extend(InUrl).init(id,host).load
      else
        puts Stat.new.extend(InFile).init(id).load
      end
    else
      stat=Stat.new.extend(Stat::SymConv).init(idb)
      field=Field.new.load
      stat.val=AppVal.new(idb,field)
      print stat.upd.to_j
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
end
