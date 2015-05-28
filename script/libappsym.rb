#!/usr/bin/ruby
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
        @symdb=Sym::Db.pack(['share',adbs['symtbl']])
        self['class']={}
        self['msg']={}
        @post_upd_procs << proc{ #post process
          adbs[:index].each{|key,hash|
            sid=hash['symbol']||next
            unless tbl=@symdb[sid.to_sym]
              alert("Symbol","Table[#{sid}] not exist")
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
                self['msg'][key]=sym['msg'] % val
              when 'pattern'
                next unless /#{sym['val']}/ === val || val == 'default'
                verbose("Symbol","VIEW:Regexp:[#{sym['val']}] and [#{val}]")
                self['msg'][key]=sym['msg'] % val
              end
              self['class'][key]=sym['class']
              break
            }
          }
          verbose("Symbol","Propagate Status#upd -> Symbol:Update(#{self['time']})")
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
      require "libinsdb"
      GetOpts.new
      begin
        stat=Status.new
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        adb=Ins::Db.new.set(id)
        stat.set_db(adb)
        stat.ext_file if STDIN.tty?
        stat.ext_sym.upd
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        Msg.usage "[site] | < status_file"
      end
    end
  end
end
