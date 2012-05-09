#!/usr/bin/ruby
require "libmsg"
require "libvar"
require "libiofile"

class Status < Var
  def initialize
    super('stat')
    @last={}
  end

  def set(hash) #For Watch test
    @val.update(hash)
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{@val[id]}] vs last=[#{@last[id]}]"}
    @val[id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    @v.msg{"Status Updated"}
    @last.update(@val)
  end

  def ext_iofile
    extend IoFile
    init(@id)
    @lastsave=0
    def self.save
      time=@val['time'].to_f
      @v.msg{"Data time #{time} for Save"}
      if time > @lastsave
        super
        @lastsave=time
        true
      end
    end
    self
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
        puts stat.extend(InUrl).init(id,host).load
      else
        puts stat.extend(InFile).init(id).load
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
