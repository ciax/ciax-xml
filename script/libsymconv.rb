#!/usr/bin/ruby
require "libmsg"
require "libstat"

# Status to SymConv (String with attributes)
module SymConv
  require "libsymdb"
  def self.extended(obj)
    Msg.type?(obj,Stat)
  end

  def init(adb,val)
    @id=adb['id']
    ads=Msg.type?(adb,App::Db)[:status]
    self.ver=adb['app_ver'].to_i
    self.val=Msg.type?(val,App::Rsp)
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

if __FILE__ == $0
  require "libinsdb"
  require "libstat"
  require "libfield"
  require "libapprsp"
  begin
    id=ARGV.shift
    ARGV.clear
    idb=InsDb.new(id).cover_app
    raise UserError if STDIN.tty?
    field=Field.new.load
    val=App::Rsp.new(idb,field)
    stat=Stat.new.extend(SymConv).init(idb,val)
    print stat.upd
  rescue UserError
    Msg.usage "[id] < field_file"
  end
end
