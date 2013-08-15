#!/usr/bin/ruby
require "libsh"
require "libstatus"
require "libwatch"
require 'libfrmsh'
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "thread"

module CIAX
  module App
    def self.new(adb,fsh=nil)
      if Frm::Sv === fsh
        ash=App::Sv.new(adb,fsh,$opt['e'])
        ash=App::Cl.new(adb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        ash=App::Cl.new(adb,host)
      else
        ash=App::Test.new(adb)
      end
      ash
    end

    class Exe < Exe
      # @< cobj,output,upd_proc*
      # @ adb,fsh,watch,stat*
      attr_reader :adb,:stat
      def initialize(adb,id=nil)
        @adb=type?(adb,Db)
        super('app',id||adb['id'],ExtCmd.new(adb))
        @stat=App::Status.new(adb[:status][:struct].deep_copy)
        ext_shell(@stat,{'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        @watch=Watch::Data.new
        @cobj.int_proc=proc{
          int=@watch.interrupt
          verbose("AppSh","#{self['id']}/Interrupt:#{int}")
          self['msg']="Interrupt #{int}"
        }
        @pre_proc << proc{|args|@watch.block?(args)}
        init_view
      end

      private
      def shell_input(line)
        args=super
        args.unshift 'set' if /^[^ ]+\=/ === line
        args
      end

      def init_view
        @output=@print=View.new(@adb,@stat).extend(Print)
        @wview=Watch::View.new(@adb,@watch).ext_prt
        grp=@cobj['lo'].add_group('view',"Change View Mode",3)
        grp.add_item('pri',"Print mode").share[:def_proc]=proc{@output=@print}
        grp.add_item('wat',"Watch mode").share[:def_proc]=proc{@output=@wview} if @wview
        grp.add_item('raw',"Raw mode").share[:def_proc]=proc{@output=@stat}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(adb)
        super(adb)
        @stat.ext_sym(adb)
        @watch.ext_upd(adb,@stat).upd
        cri={:type => 'reg', :list => ['.']}
        @cobj['sv']['int'].add_item('set','[key=val,...]',[cri]).share[:def_proc]=proc{|item|
          @stat.str_update(item.par[0])
          self['msg']="Set #{item.par[0]}"
        }
        @cobj['sv']['int'].add_item('del','[key,...]',[cri]).share[:def_proc]=proc{|item|
          item.par[0].split(',').each{|key|
            @stat.unset(key)
          }
          self['msg']="Delete #{item.par[0]}"
        }
        @watch.event_proc=proc{|args,p|
          Msg.msg("#{args} is issued by event")
        }
        @upd_proc << proc{@watch.issue}
      end
    end

    class Cl < Exe
      def initialize(adb,host=nil)
        super(adb,adb['site_id'])
        host=type?(host||adb['host']||'localhost',String)
        @stat.ext_http(self['id'],host).load
        @watch.ext_http(self['id'],host).load
        ext_client(host,adb['port'])
        @upd_proc << proc{
          @stat.load
          @watch.load
        }
      end
    end

    # @<< cobj,output,upd_proc*
    # @< adb,watch,stat*
    # @ fsh,buf,log_proc
    class Sv < Exe
      def initialize(adb,fsh,logging=nil)
        super(adb,adb['site_id'])
        @fsh=type?(fsh,Frm::Exe)
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @stat.ext_rsp(@fsh.field,adb[:status]).ext_sym(adb).ext_file(self['id']).upd
        SqLog::Upd.new(@stat).ext_exec if logging and @fsh.field.key?('ver')
        @watch.ext_upd(adb,@stat).ext_file(self['id']).upd.event_proc=proc{|args,p|
          verbose("AppSv","#{self['id']}/Auto(#{p}):#{args}")
          @buf.send(p,@cobj.setcmd(args))
        }
        @buf=init_buf
        @cobj['sv']['ext'].share[:def_proc]=proc{|item|
          verbose("AppSv","#{self['id']}/Issue:#{item.args}")
          @buf.send(1,item)
          self['msg']="Issued"
        }
        # Logging if version number exists
        if logging and @adb['version']
          ext_logging(@adb['site_id'],@adb['version'])
        end
        tid_auto=auto_update
        @upd_proc << proc{
          self['auto'] = tid_auto && tid_auto.alive?
          self['watch'] = @watch.active?
          self['na'] = !@buf.alive?
        }
        @save_proc << proc{@stat.upd.save}
        ext_server(@adb['port'])
      end

      def ext_logging(id,ver=0)
        logging=Logging.new('issue',id,ver)
        @post_proc << proc{|args|
          logging.append({'cmd'=>args,'active'=>@watch['active']})
        }
        self
      end

      private
      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|item|
          cmdary=item.getcmd
          verbose("AppSv","Send FrmCmds #{cmdary}")
          cmdary
        }
        buf.recv_proc{|args|
          verbose("AppSv","Processing #{args}")
          @fsh.exe(args)
        }
        buf.flush_proc.add{
          verbose("AppSv","Flushed FrmCmds")
          @stat.upd.save
          sleep(@watch['interval']||0.1)
          # Auto issue by watch
          @watch.issue
        }
        buf
      end

      def auto_update
        Thread.new{
          tc=Thread.current
          tc[:name]="Auto"
          tc[:color]=4
          Thread.pass
          int=(@watch['period']||300).to_i
          loop{
            begin
              @buf.send(2,@cobj.setcmd(['upd']))
            rescue InvalidID
              warning("AppSv",$!)
            end
            verbose("AppSv","Auto Update(#{@stat['time']})")
            sleep int
          }
        }
      end
    end

    class List < ShList
      def initialize(fl=nil)
        super(){|id| App.new(@ldb.set(id)[:app],@fl[id])}
        @ldb=Loc::Db.new
        if Frm::List === fl
          @fl=fl
          update_items(@ldb.list)
        elsif $opt['e'] || $opt['s']
          @fl=Frm::List.new
          update_items(@ldb.list)
        else
          @fl={}
          update_items(@ldb.list)
        end
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('cet')
    begin
      App::List.new.shell(ARGV.shift)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
