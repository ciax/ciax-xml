#!/usr/bin/ruby
require "libmsg"
require "libvar"

class Status < Var
  extend Msg::Ver
  def initialize
    Status.init_ver('Status',6)
    super('stat')
    @last={}
  end

  def set(hash) #For Watch test
    @val.update(hash)
    self
  end

  def change?(id)
    Status.msg{"Compare(#{id}) current=[#{@val[id]}] vs last=[#{@last[id]}]"}
    @val[id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    Status.msg{"Status Updated"}
    @last.update(@val)
    self
  end

  def ext_save(id)
    super
    @lastsave=0
    extend Save
    self
  end

  module Save
    extend Msg::Ver
    def self.extended(obj)
      init_ver(obj,6)
    end

    def save
      time=@val['time'].to_f
      Save.msg{"Try Save for #{time}"}
      if time > @lastsave
        super
        @lastsave=time
        true
      end
    end
  end
end

if __FILE__ == $0
  require "libinsdb"
  begin
    id=ARGV.shift
    host=ARGV.shift
    ARGV.clear
    idb=Ins::Db.new(id).cover_app
    stat=Status.new
    if STDIN.tty?
      if host
        puts stat.ext_url(id,host).load
      else
        puts stat.ext_load(id).load
      end
    else
      require "libfield"
      require "libapprsp"
      field=Field.new.load
      stat.extend(App::Rsp).init(idb,field).upd
      print stat
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
  exit
end
