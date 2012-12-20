#!/usr/bin/ruby
require "libmsg"
require "libstatus"

# Status to Sym::Conv (String with attributes)
module Sym
  module Conv
    extend Msg::Ver
    require "libsymdb"
    def self.extended(obj)
      init_ver('SymConv')
      Msg.type?(obj,Status::Var,Var::Load)
    end

    def ext_conv(db)
      @db=Msg.type?(db,App::Db)
      ads=@db[:status]
      self['ver']=@db['version'].to_i
      @symbol=ads[:symbol]||{}
      @sdb=Sym::Db.pack(['all',ads['table']])
      self['class']={}
      self['msg']={}
      self
    end

    def upd
      super
      @symbol.each{|key,sid|
        unless tbl=@sdb[sid.to_sym]
          Msg.warn("Table[#{sid}] not exist")
          next
        end
        Conv.msg{"ID=#{key},table=#{sid}"}
        self['class'][key]='alarm'
        self['msg'][key]='N/A'
        val=self['val'][key]
        tbl.each{|sym|
          case sym['type']
          when 'range'
            next unless ReRange.new(sym['val']) == val
            Conv.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
            self['msg'][key]=sym['msg']+"(#{val})"
          when 'pattern'
            next unless /#{sym['val']}/ === val || val == 'default'
              Conv.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
            self['msg'][key]=sym['msg']
          end
          self['class'][key]=sym['class']
          break
        }
      }
      Conv.msg{"Sym/Update(#{self['time'].to_f})"}
      self
    end
  end
end

class Status::Var
  def ext_sym(adb)
    extend(Sym::Conv).ext_conv(adb)
  end
end

if __FILE__ == $0
  require "liblocdb"
  id=ARGV.shift
  begin
    adb=Loc::Db.new(id)[:app]
    stat=Status::Var.new.ext_file(adb['site_id']).load
    stat.ext_sym(adb).upd.ext_save.save
    print stat
  rescue UserError
    Msg.usage "[id]"
  end
end
