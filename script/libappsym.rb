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

      def ext_sym
        adbs=@db[:status]
        @symbol=adbs[:symbol]||{}
        @symdb=Sym::Db.pack(['all',adbs['symtbl']])
        self['class']={}
        self['msg']={}
        @post_upd_procs << proc{ #post process
          adbs[:index].each{|key,hash|
            sid=hash['symbol']||next
            unless tbl=@symdb[sid.to_sym]
              warning("Symbol","Table[#{sid}] not exist")
              next
            end
            verbose("Symbol","ID=#{key},Table=#{sid}")
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
      def ext_sym
        extend(Symbol).ext_sym
      end
    end

    if __FILE__ == $0
      require "liblocdb"
      GetOpts.new
      id=ARGV.shift
      begin
        adb=Site::Db.new.set(id)[:app]
        stat=Status.new.skeleton(adb).ext_file
        stat.ext_sym.upd
        print stat
      rescue InvalidID
        Msg.usage "[id]"
      end
    end
  end
end
