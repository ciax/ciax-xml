#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

module Int
  class Exe < ExHash
    # @ cobj,output,intcmd,upd_proc,int_proc*
    # # exe,ext_client,ext_server,ext_shell
    attr_reader :int_proc
    def initialize
      @cobj=Command.new
      @output=''
      @intcmd=@cobj.add_domain('int',2)
      @upd_proc=Update.new # Proc for Server Status Update
      @int_proc=Update.new # Proc for Interactive Operation
    end

    # Sync only (Wait for other thread)
    def exe(cmd)
      @cobj.set(cmd).exe
      self
    end

    def ext_client(host,port)
      if is_a? Client
        Msg.warn("Multiple Initialize for Client")
      else
        extend(Client).client(host,port)
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

    def ext_shell(pconv={},&p)
      if is_a? Shell
        Msg.warn("Multiple Initialize for Shell")
      else
        extend(Shell).init(pconv,&p)
      end
      self
    end

    private
    # Async for interactive interface
    def int_exe(cmd)
      @cobj.set(cmd).exe
      self
    end
  end


  module Server
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Server/%s',5,obj)
      Msg.type?(obj,Exe)
    end

    # invoked once
    # JSON expression of server stat will be sent.
    def server(port)
      Server.msg{"Init/Server(#{self['id']}):#{port}"}
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
    # For server
    def sv_exe(line)
      self['msg']='OK'
      return if /^(strobe|stat)/ === line
      int_exe(line.split(' '))
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

    def client(host,port)
      host||='localhost'
      udp=UDPSocket.open()
      addr=Socket.pack_sockaddr_in(port.to_i,host)
      Client.msg{"Init/Client(#{self['id']})#{host}:#{port}"}
      @cobj.def_proc.add{|item|
        cl_exe(udp,addr,item.cmd.join(' '))
      }
      @upd_proc.add{cl_exe(udp,addr,'strobe')}
    end

    private
    # For client
    def cl_exe(udp,addr,str)
      udp.send(str,0,addr)
      Client.msg{"Send [#{str}]"}
      input=udp.recv(1024)
      Client.msg{"Recv #{input}"}
      load(input) # ExHash#load -> Server Status
      self
    end
  end

  # Shell has internal status for prompt
  module Shell
    extend Msg::Ver
    # @< cobj,output,intcmd,upd_proc,int_proc*
    # #< exe,ext_client,ext_server,ext_shell
    # @ pconv,shcmd,prompt,lineconv
    # # set_switch,shell
    def self.extended(obj)
      init_ver('Shell/%s',2,obj)
      Msg.type?(obj,Exe)
    end

    def init(pconv={},&p)
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
      @lineconv=p if p
      Shell.msg{"Init/Shell(#{self['id']})"}
      self
    end

    def set_switch(key,title,list)
      grp=@shcmd.add_group(key,title)
      grp.update_items(list).init_proc{|item| raise(SelectID,item.id)}
      self
    end

    # invoked many times
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
            puts @output
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
    # For shell
    def sh_exe(line)
      line=@lineconv.call(line) if @lineconv
      self['msg']='OK'
      int_exe(line.split(' '))
      @int_proc.upd
      puts self['msg']
    rescue InvalidCMD
      puts $!.to_s
    rescue UserError
      puts $!.to_s
    end

    def compset(cmd)
      return cmd unless /\=/ === cmd[0]
      cmd.unshift('set')
    end
  end

  class List < Hash
    require "liblocdb"
    attr_reader :share_proc
    def initialize(opt=nil)
      @opt=Msg.type?(opt||Msg::GetOpts.new,Msg::GetOpts)
      @share_proc=Update.new
      super(){|h,id|
        int=yield id
        @share_proc.exe(int)
        h[id]=int
      }
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue UserError
     @opt.usage('(opt) [id] [cmd] [par....]')
    end

    def shell(id)
      begin
        int=(defined? yield) ? yield(id) : self[id]
      end while id=int.shell
    rescue UserError
      @opt.usage('(opt) [id]')
    end

    def server(ary)
      ary.each{|i|
        sleep 0.3
        self[i]
      }.empty? && self[nil]
      sleep
    rescue UserError
      @opt.usage('(opt) [id] ....')
    end
  end
end
