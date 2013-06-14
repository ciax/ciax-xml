#!/usr/bin/ruby
require "libmsg"
require "libstatus"
require "libsymdb"

# Status to Sym::Upd (String with attributes)
module CIAX
  module Sym
    module Upd
      def self.extended(obj)
        Msg.type?(obj,Status::Var)
      end

      def ext_upd(db)
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
        super # Status#upd
        @symbol.each{|key,sid|
          unless tbl=@sdb[sid.to_sym]
            warning("Symbol","Table[#{sid}] not exist")
            next
          end
          verbose("Symbol","ID=#{key},table=#{sid}")
          self['class'][key]='alarm'
          self['msg'][key]='N/A'
          val=self['val'][key]
          tbl.each{|sym|
            case sym['type']
            when 'range'
              next unless ReRange.new(sym['val']) == val
              verbose("Symbol","VIEW:Range:[#{sym['val']}] and [#{val}]")
              self['msg'][key]=sym['msg']+"(#{val})"
            when 'pattern'
              next unless /#{sym['val']}/ === val || val == 'default'
              verbose("Symbol","VIEW:Regexp:[#{sym['val']}] and [#{val}]")
              self['msg'][key]=sym['msg']
            end
            self['class'][key]=sym['class']
            break
          }
        }
        verbose("Symbol","Update(#{self['time'].to_f})")
      end
    end
  end

  class Status::Var
    def ext_sym(adb)
      extend(Sym::Upd).ext_upd(adb)
    end
  end

  if __FILE__ == $0
    require "liblocdb"
    Msg::GetOpts.new
    id=ARGV.shift
    begin
      adb=Loc::Db.new.set(id)[:app]
      stat=Status::Var.new.ext_file(adb['site_id']).load
      stat.ext_sym(adb).upd.ext_save.save
      print stat
    rescue InvalidID
      Msg.usage "[id]"
    end
  end
end
