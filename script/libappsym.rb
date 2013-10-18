#!/usr/bin/ruby
require "libmsg"
require "libstatus"
require "libsymdb"

# Status to App::Sym (String with attributes)
module CIAX
  module App
    module Symbol
      def self.extended(obj)
        Msg.type?(obj,Status)
      end

      def ext_sym(db)
        type?(db,App::Db)
        ads=db[:status]
        self['ver']=db['version'].to_i
        @symbol=ads[:symbol]||{}
        @sdb=Sym::Db.pack(['all',ads['table']])
        self['class']={}
        self['msg']={}
        @upd_procs << proc{
          @symbol.each{|key,sid|
            unless tbl=@sdb[sid.to_sym]
              warning("Symbol","Table[#{sid}] not exist")
              next
            end
            verbose("Symbol","ID=#{key},table=#{sid}")
            self['class'][key]='alarm'
            self['msg'][key]='N/A'
            val=@data[key]
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
          verbose("Symbol","Update(#{self['time']})")
        }
        self
      end
    end

    class Status
      def ext_sym(adb)
        extend(Symbol).ext_sym(adb)
      end
    end

    if __FILE__ == $0
      require "liblocdb"
      GetOpts.new
      id=ARGV.shift
      begin
        adb=Loc::Db.new.set(id)[:app]
        stat=Status.new.ext_file(adb['site_id']).load
        stat.ext_sym(adb).upd.save
        print stat
      rescue InvalidID
        Msg.usage "[id]"
      end
    end
  end
end
