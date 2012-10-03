#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

module Int
  class Shell < ExHash
    attr_reader :cmdlist,:cobj
    def initialize
      @cobj=Command.new
      @pconv={} #prompt convert table (j2s)
      @port=0
    end

    # No command => UserError
    # Bad command => UserError
    # Accepted => Command
    # cmd is Array
    def exe(cmd)
      self['msg']=@cobj.set(cmd).exe
    end

    def set_switch(key,title,list)
      grp=@cobj.int.add_group(key,title)
      grp.update_items(list)
      self
    end

    # 'q' gives exit break (loop returns nil)
    # mode gives special break (loop returns mode)
    def shell
      Readline.completion_proc= proc{|word|
        @cobj.list.keys.grep(/^#{word}/)
      }
      grp=@cobj.add_domain('sh',5).add_group('sh',"Shell Command")
      grp.update_items({'q'=>"Quit",'D^'=>"Interrupt"})
      loop {
        line=Readline.readline(prompt,true)||'interrupt'
        break if /^q/ === line
        cmd=line.split(' ')
        begin
          puts cmd.empty? ? self : exe(cmd)
        rescue SelectID
          break $!.to_s
        rescue InvalidCMD
          puts $!.to_s
        rescue UserError
          puts $!.to_s
        end
      }
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
      init_ver('Server/%s',3,obj)
      Msg.type?(obj,Shell)
    end
    # JSON expression of server stat will be sent.
    # Or, block contents will be sent if block added.
    def server(json=true)
      Server.msg{"Init/Server:#{@port}"}
      Thread.new{
        Thread.pass
        UDPSocket.open{ |udp|
          udp.bind("0.0.0.0",@port.to_i)
          loop {
            IO.select([udp])
            line,addr=udp.recvfrom(4096)
            Server.msg{"Recv:#{line} is #{line.class}"}
            cmd=line.chomp.split(' ')
            begin
              exe(cmd) unless /^(strobe|stat)/ === line
            rescue RuntimeError
              warn(self['msg']="ERROR")
            end
            Server.msg{"Send:#{self['msg']}"}
            udp.send(json ? to_j : to_s,0,addr[2],addr[1]) #self.to_j
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
    end

    def exe(cmd)
      super # Check only
      send(cmd.join(' '))['msg']
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
      load(input) # ExHash#load -> Server Status
      Client.msg{"Recv #{input}"}
      self
    end
  end
end
