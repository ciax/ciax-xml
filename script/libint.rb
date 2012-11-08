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
      extend(Client).client(port)
      self
    end

    def ext_server(port)
      extend(Server).server(port){to_j}
      self
    end

    def ext_shell(pconv={})
      extend(Shell).init(pconv)
      self
    end
  end

  # Shell has internal status for prompt
  module Shell
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    def init(pconv={})
      #prompt convert table (j2s)
      @pconv=Msg.type?(pconv,Hash)
      @shcmd=@cobj.add_domain('sh',5)
      @prompt=''
      @upd_proc << proc{
        @prompt=keys.map{|k|
          if k != 'msg' and v=self[k]
            @pconv[k]||v
          end
        }.compact.join('')+'>'
      }
      self
    end

    def set_switch(key,title,list)
      grp=@shcmd.add_group(key,title)
      grp.update_items(list).init_proc{|item| raise(SelectID,item.id)}
      self
    end

    # 'q' gives exit break (loop returns nil)
    # mode gives special break (loop returns mode)
    def shell
      Readline.completion_proc= proc{|word|
        @cobj.list.keys.grep(/^#{word}/)
      }
      grp=@shcmd.add_group('sh',"Shell Command")
      grp.update_items({'q'=>"Quit",'D^'=>"Interrupt"})
      loop {
        line=Readline.readline(@prompt,true)||'interrupt'
        break if /^q/ === line
        self['msg']='OK'
        begin
          if line.empty?
            puts self
          else
            @cobj.set(line.split(' ')).exe
            @int_proc.upd
            puts self['msg']
          end
        rescue SelectID
          break $!.to_s
        rescue InvalidCMD
          puts $!.to_s
        rescue UserError
          puts $!.to_s
        end
        @upd_proc.upd
      }
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
            Server.msg{"Recv:#{line} is #{line.class}"}
            begin
              self['msg']='OK'
              unless /^(strobe|stat)/ === line
                @cobj.set(line.chomp.split(' ')).exe
                @int_proc.upd
              end
            rescue InvalidPAR
              self['msg']=$!.to_s
            rescue InvalidCMD
              self['msg']="INVALID"
            rescue RuntimeError
              warn(self['msg']=$!.to_s)
            end
            Server.msg{"Send:#{self['msg']}"}
            @upd_proc.upd
            udp.send(yield,0,addr[2],addr[1])
          }
        }
      }
      self
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
      @cobj.def_proc << proc{|item|
        send(item.cmd.join(' '))
      }
      @upd_proc << proc{send('strobe')}
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
    def initialize
      ENV['VER']||='init/'
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        int=yield ldb
        if int.is_a? Int::Shell
          int.set_switch('dev',"Change Device",ldb.list)
        end
        h[id]=int
      }
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue UserError
      Msg.usage('(opt) [id] [cmd] [par....]',*$optlist)
    end

    def shell(id)
      true while id=self[id].shell
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
