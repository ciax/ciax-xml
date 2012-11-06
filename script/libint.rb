#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

module Int
  # Shell has internal status for prompt
  class Shell < ExHash
    attr_reader :cobj,:int_proc
    def initialize
      @cobj=Command.new
      @shcmd=@cobj.add_domain('sh',5)
      @intcmd=@cobj.add_domain('int',2)
      @int_proc=Update.new # Proc for Interactive Operation
      @pconv={} #prompt convert table (j2s)
      @port=0
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
        line=Readline.readline(prompt,true)||'interrupt'
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
      }
    end

    def ext_server(port)
      extend(Server).server(port){to_j}
    end

    private
    def prompt
      str=''
      each{|k,v|
        next if /msg/ === k
        str << (@pconv[k]||v) if v
      }
      str+'>'
    end
  end

  module Server
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Server/%s',5,obj)
      Msg.type?(obj,Shell)
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
            prompt
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
      Msg.type?(obj,Shell).init
    end

    def init
      @udp=UDPSocket.open()
      @host||='localhost'
      @addr=Socket.pack_sockaddr_in(@port,@host)
      Client.msg{"Init/Client #{@host}:#{@port}"}
      @cobj.def_proc << proc{|item|
        send(item.cmd.join(' '))
      }
    end

    private
    def prompt
      send('strobe')
      super
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

    def shell(id)
      true while id=self[id].shell
    rescue UserError
      Msg.usage('(opt) [id] ....',*$optlist)
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
