#!/usr/bin/ruby
require "libmsg"
require "libstat"

# Status to Sym::Conv (String with attributes)
module Sym
  module Conv
    require "libsymdb"
    def self.extended(obj)
      Msg.type?(obj,App::Stat)
    end

    def init(adb)
      @id=adb['id']
      ads=Msg.type?(adb,App::Db)[:status]
      self.ver=adb['app_ver'].to_i
      @symbol=ads[:symbol]||{}
      @sdb=Sym::Db.pack(['all',ads['table']])
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
end

if __FILE__ == $0
  require "libinsdb"
  id=ARGV.shift
  begin
    adb=InsDb.new(id).cover_app
    stat=App::Stat.new.extend(InFile).init(id).load
    stat.extend(Sym::Conv).init(adb).upd
    print stat
  rescue UserError
    Msg.usage "[id]"
  end
end
