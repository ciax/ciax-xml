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
      Msg.type?(obj,Status::Var,Var::Load).init
    end

    def init
      ads=@db[:status]
      self['ver']=@db['version'].to_i
      @symbol=ads[:symbol]||{}
      @sdb=Sym::Db.pack(['all',ads['table']])
      self['class']={'time' => 'normal'}
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
        val=@val[key]
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
      stime=@val['time'].to_f
      self['msg']['time']=Time.at(stime).to_s
      Conv.msg{"Sym/Update(#{stime})"}
      self
    end
  end
end

class Status::Var
  def ext_sym
    extend Sym::Conv
  end
end

if __FILE__ == $0
  require "liblocdb"
  id=ARGV.shift
  begin
    adb=Loc::Db.new(id)[:app]
    stat=Status::Var.new.ext_file(adb).load
    stat.ext_sym.upd.ext_save.save
    print stat
  rescue UserError
    Msg.usage "[id]"
  end
end
