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
        adbs=@dbi[:status]
        @symbol=adbs[:symbol]||{}
        @symdb=Sym::Db.pack(['share',adbs['symtbl']])
        self['class']={}
        self['msg']={}
        @post_upd_procs << proc{ #post process
          verbose("Propagate upd -> Symbol#upd")
          set_sym(adbs[:index])
          set_sym(adbs[:alias])
        }
        self
      end

      def set_sym(index)
        index.each{|key,hash|
          sid=hash['symbol']||next
          unless tbl=@symdb[sid.to_sym]
            alert("Table[#{sid}] not exist")
            next
          end
          verbose("ID=#{key},Table=#{sid}")
          self['class'][key]='alarm'
          val=@data[hash['ref']||key]
          self['msg'][key]="N/A(#{val})"
          tbl.each{|sym|
            case sym['type']
            when 'numeric'
              tol=sym['tolerance'].to_f
              next if sym['val'].split(',').all?{|cri|
                val.to_f > cri.to_f+tol or val.to_f < cri.to_f-tol
              }
              verbose("VIEW:Numeric:[#{sym['val']}+-#{tol}] and [#{val}]")
              self['msg'][key]=sym['msg'] % val
            when 'range'
              next unless ReRange.new(sym['val']) == val
              verbose("VIEW:Range:[#{sym['val']}] and [#{val}]")
              self['msg'][key]=sym['msg'] % val.to_f
            when 'pattern'
              next unless /#{sym['val']}/ === val || val == 'default'
              verbose("VIEW:Regexp:[#{sym['val']}] and [#{val}]")
              self['msg'][key]=sym['msg'] % val
            end
            self['class'][key]=sym['class']
            break
          }
        }
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
        dbi=Ins::Db.new.get(id)
        stat.set_dbi(dbi).ext_sym
        stat.ext_file if STDIN.tty?
        stat.upd
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        Msg.usage "[site] | < status_file"
      end
    end
  end
end
