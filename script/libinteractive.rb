#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

# Provide Server,Client and Shell
# Integrate Command,Var
# Generate Internal Command
# Add External Command to Combine Lower Layer (Stream,Frm,App)
# Add Shell Command (by Shell extention)

module Interactive
  # @ cobj,output,intgrp,interrupt,upd_proc
  class Exe < ExHash
    extend Msg::Ver
    attr_reader :upd_proc,:interrupt
    def initialize
      Exe.init_ver(self,2)
      @cobj=Command.new
      @output=''
      @intgrp=@cobj.add_domain('int',2).add_group('int',"Internal Command")
      @interrupt=@intgrp.add_item('interrupt')
      @upd_proc=UpdProc.new # Proc for Server Status Update
    end

    # Sync only (Wait for other thread)
    def exe(cmd)
      self['msg']='OK'
      return @output if cmd.empty?
      @cobj.setcmd(cmd).exe
      self['msg']
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_proc.upd
    end

    def ext_shell(pconv={},&p)
      if is_a? Shell
        Msg.warn("Multiple Initialize for Shell")
      else
        extend(Shell).ext_shell(pconv,&p)
      end
      self
    end
  end

  class Server < Exe
    # invoked once
    # JSON expression of server stat will be sent.
    def server(port)
      Exe.msg{"Init/Server(#{self['id']}):#{port}"}
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
            Exe.msg{"Recv:#{line} is #{line.class}"}
            begin
              exe(filter_in(line))
            rescue InvalidCMD
              self['msg']="INVALID"
            rescue RuntimeError
              warn($!.to_s)
              self['msg']=$!.to_s
            end
            Exe.msg{"Send:#{self['msg']}"}
            udp.send(filter_out,0,addr[2],addr[1])
          }
        }
      }
      self
    end

    private
    def filter_in(line)
      JSON.load(line)
    rescue JSON::ParserError
      raise UserError,"NOT JSON"
    end

    def filter_out
      to_j
    end
  end

  class Client < Exe
    def client(host,port)
      host||='localhost'
      udp=UDPSocket.open()
      addr=Socket.pack_sockaddr_in(port.to_i,host)
      Exe.msg{"Init/Client(#{self['id']})#{host}:#{port}"}
      @cobj.def_proc.set{|item|
        cl_exe(udp,addr,item.cmd)
      }
      @upd_proc.add{cl_exe(udp,addr,[])}
      self
    end

    private
    # For client
    def cl_exe(udp,addr,cmd)
      udp.send(JSON.dump(cmd),0,addr)
      Exe.msg{"Send [#{cmd}]"}
      input=udp.recv(1024)
      Exe.msg{"Recv #{input}"}
      load(input) # ExHash#load -> Server Status
      self
    end
  end

  # Shell has internal status for prompt
  module Shell
    extend Msg::Ver
    # @< cobj,output,(intgrp),(interrupt),upd_proc
    # @ pconv,shdom,lineconv
    attr_reader :shdom
    def self.extended(obj)
      init_ver('Shell/%s',2,obj)
      Msg.type?(obj,Exe)
    end

    # block gives command line convert
    def ext_shell(pconv={},&p)
      #prompt convert table (j2s)
      @pconv={'id'=>nil}.update(Msg.type?(pconv,Hash))
      @shdom=@cobj.add_domain('sh',5)
      @lineconv=p if p
      Readline.completion_proc=proc{|word|
        @cobj.keys.grep(/^#{word}/)
      }
      grp=@shdom.add_group('sh',"Shell Command")
      grp.update_items({'^D,q'=>"Quit",'^C'=>"Interrupt"})
      Shell.msg{"Init/Shell(#{self['id']})"}
      self
    end

    def set_switch(key,title,list)
      grp=@shdom.add_group(key,title)
      grp.update_items(list).reset_proc{|item| raise(SelectID,item.id)}
      self
    end

    # invoked many times
    # '^D' gives exit break
    # mode gives special break (loop returns mode)
    def shell
      begin
        @upd_proc.upd
        while line=Readline.readline(prompt,true)
          break if /^q/ === line
          line=@lineconv.call(line) if @lineconv
          puts exe(line.split(' '))
        end
      rescue SelectID
        $!.to_s
      rescue Interrupt
        puts exe(['interrupt'])
        retry
      rescue
        puts $!.to_s
        retry
      end
    end

    private
    def prompt
      @pconv.keys.map{|k|
        (@pconv[k]||'%s') % self[k] if self[k]
      }.compact.join('')+'>'
    end
  end

  class List < Hash
    require "liblocdb"
    attr_accessor :init_proc
    def initialize(opt=nil)
      @opt=Msg.type?(opt||Msg::GetOpts.new,Msg::GetOpts)
      @init_proc=proc{} # Execute when new key is set
      super(){|h,id|
        int=yield id
        @init_proc.call(int)
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
