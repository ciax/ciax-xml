#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

module Int
  class Exe < ExHash
    attr_reader :int_proc
    def initialize
      @cobj=Command.new
      @intcmd=@cobj.add_domain('int',2)
      @int_proc=Update.new # Proc for Interactive Operation
      @upd_proc=Update.new # Proc for Server Status Update
    end

    # Sync only (Wait for other thread)
    def exe(cmd)
      @cobj.set(cmd).exe
      self
    end

    def ext_client(port)
      if is_a? Client
        Msg.warn("Multiple Initialize for Client")
      else
        extend(Client).client(port)
      end
      self
    end

    def ext_server(port)
      if is_a? Server
        Msg.warn("Multiple Initialize for Server")
      else
        extend(Server).server(port){to_j}
      end
      self
    end

    def ext_shell(pconv={})
      if is_a? Shell
        Msg.warn("Multiple Initialize for Shell")
      else
        extend(Shell).init(pconv)
      end
      self
    end
  end

  # Shell has internal status for prompt
  module Shell
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Shell/%s',2,obj)
      Msg.type?(obj,Exe)
    end

    def init(pconv={})
      #prompt convert table (j2s)
      @pconv=Msg.type?(pconv,Hash)
      @shcmd=@cobj.add_domain('sh',5)
      @upd_proc.add{
        @prompt=keys.map{|k|
          if k != 'msg' and v=self[k]
            @pconv[k]||v
          end
        }.compact.join('')+'>'
      }.upd
      Shell.msg{"Init/Shell"}
      self
    end

    def set_switch(key,title,list)
      grp=@shcmd.add_group(key,title)
      grp.update_items(list).init_proc{|item| raise(SelectID,item.id)}
      self
    end

    # '^D' gives exit break
    # mode gives special break (loop returns mode)
    def shell
      Readline.completion_proc=proc{|word|
        @cobj.keys.grep(/^#{word}/)
      }
      grp=@shcmd.add_group('sh',"Shell Command")
      grp.update_items({'^D,q'=>"Quit",'^C'=>"Interrupt"})
      begin
        while line=Readline.readline(@prompt,true)
          case line
          when /^q/
            break
          when ''
            puts self
          else
            sh_exe(line)
          end
          @upd_proc.upd
        end
      rescue SelectID
        $!.to_s
      rescue Interrupt
        sh_exe('interrupt')
        retry
      end
    end

    private
    def sh_exe(line)
      self['msg']='OK'
      exe(line.split(' '))
      @int_proc.upd
      puts self['msg']
    rescue InvalidCMD
      puts $!.to_s
    rescue UserError
      puts $!.to_s
    end
  end

  module Server
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Server/%s',5,obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def server(port)
      Server.msg{"Init/Server:#{port}"}
      Thread.new{
        tc=Thread.current
        tc[:name]="Server"
        tc[:color]=9
        Thread.pass
        UDPSocket.open{ |udp|
          udp.bind("0.0.0.0",port.to_i)
          loop {
            IO.select([udp])
            line,addr=udp.recvfrom(4096)
            line.chomp!
            Server.msg{"Recv:#{line} is #{line.class}"}
            sv_exe(line)
            Server.msg{"Send:#{self['msg']}"}
            @upd_proc.upd
            udp.send(yield,0,addr[2],addr[1])
          }
        }
      }
      self
    end

    private
    def sv_exe(line)
      self['msg']='OK'
      return if /^(strobe|stat)/ === line
      exe(line.split(' '))
      @int_proc.upd
    rescue InvalidPAR
      self['msg']=$!.to_s
    rescue InvalidCMD
      self['msg']="INVALID"
    rescue RuntimeError
      warn(self['msg']=$!.to_s)
    end
  end

  module Client
    extend Msg::Ver
    def self.extended(obj)
      init_ver("Client/%s",3,obj)
      Msg.type?(obj,Exe)
    end

    def client(port)
      @udp=UDPSocket.open()
      @host||='localhost'
      @addr=Socket.pack_sockaddr_in(port.to_i,@host)
      Client.msg{"Init/Client #{@host}:#{port}"}
      @cobj.def_proc.add{|item|
        send(item.cmd.join(' '))
      }
      @upd_proc.add{send('strobe')}
    end

    def send(str)
      @udp.send(str,0,@addr)
      Client.msg{"Send [#{str}]"}
      input=@udp.recv(1024)
      Client.msg{"Recv #{input}"}
      load(input) # ExHash#load -> Server Status
      self
    end
  end

  class List < Hash
    require "liblocdb"
    attr_reader :share_proc
    def initialize
      ENV['VER']||='init/'
      $opt||={}
      @share_proc=Update.new
      super(){|h,id|
        ldb=Loc::Db.new(id)
        int=yield ldb
        @share_proc.exe([ldb,int])
        h[id]=int
      }
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue UserError
      Msg.usage('(opt) [id] [cmd] [par....]',*$optlist)
    end

    def shell(id)
      @share_proc.add{|ldb,int|
        int.set_switch('dev',"Change Device",ldb.list)
      }
      begin
        int=(defined? yield) ? yield(id) : self[id]
      end while id=int.shell
    rescue UserError
      Msg.usage('(opt) [id]',*$optlist)
    end

    def server(ary)
      ary.each{|i|
        sleep 0.3
        self[i]
      }.empty? && self[nil]
      sleep
    rescue UserError
      Msg.usage('(opt) [id] ....',*$optlist)
    end
  end
end
