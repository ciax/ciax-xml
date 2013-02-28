#!/usr/bin/ruby
require "libmsg"
require "libstatus"

# Status to Sym::Conv (String with attributes)
module Sym
  module Conv
    require "libsymdb"
    def self.extended(obj)
      Msg.type?(obj,Status::Var,Var::Upd)
    end

    def ext_conv(db)
      init_ver('SymConv')
      Msg.type?(db,App::Db)
      ads=db[:status]
      self['ver']=db['version'].to_i
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
        verbose{"ID=#{key},table=#{sid}"}
        self['class'][key]='alarm'
        self['msg'][key]='N/A'
        val=self['val'][key]
        tbl.each{|sym|
          case sym['type']
          when 'range'
            next unless ReRange.new(sym['val']) == val
            verbose{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
            self['msg'][key]=sym['msg']+"(#{val})"
          when 'pattern'
            next unless /#{sym['val']}/ === val || val == 'default'
              verbose{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
            self['msg'][key]=sym['msg']
          end
          self['class'][key]=sym['class']
          break
        }
      }
      verbose{"Sym/Update(#{self['time'].to_f})"}
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
