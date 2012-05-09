#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

module Int
  class Shell
    attr_reader :post_exe,:cmdlist
    def initialize(cobj)
      @v=Msg::Ver.new(self,3)
      @cobj=Msg::type?(cobj,Command)
      @prompt=Prompt.new
      @post_exe=Update.new
      @port=0
      @cmdlist=Msg::GroupList.new
    end

    def exe(cmd)
      @cobj.set(cmd) unless cmd.empty?
      'OK'
    end

    # 'q' gives exit break (loop returns nil)
    # mode gives special break (loop returns mode)
    def shell
      sl={'q'=>"Quit",'D^'=>"Interrupt"}
      @cmdlist.add_group('sh',"Shell Command",sl,2)
      Readline.completion_proc= proc{|word|
        (@cobj.list.keys+@cmdlist.keys).grep(/^#{word}/)
      }
      loop {
        line=Readline.readline(@prompt.to_s,true)||'interrupt'
        break if /^q/ === line
        cmd=line.split(' ')
        begin
          # exe() includes status update when being Client
          # need to be executed even if cmd is empty or being Server
          msg=exe(cmd)
          if msg.empty?
            msg=to_s
          else
            @post_exe.upd
          end
          puts msg
        rescue SelectCMD
          return line if @cmdlist.include?(line)
          puts @cmdlist
        rescue UserError
          puts $!.to_s
        end
      }
    end
  end

  module Server
    def self.extended(obj)
      Msg.type?(obj,Shell)
    end
    # JSON expression of @prompt will be sent.
    # Or, block contents will be sent if block added.
    def socket(type,json=true)
      @v.msg{"Init/Server:#{@port}(#{type})"}
      Thread.new{
        Thread.pass
        UDPSocket.open{ |udp|
          udp.bind("0.0.0.0",@port.to_i)
          loop {
            select([udp])
            line,addr=udp.recvfrom(4096)
            @v.msg{"Recv:#{line} is #{line.class}"}
            line='' if /^(strobe|stat)/ === line
            cmd=line.chomp.split(' ')
            begin
              msg=exe(cmd)
              @post_exe.upd unless msg.empty?
            rescue RuntimeError
              msg="ERROR"
              warn msg
            end
            @v.msg{"Send:#{msg}"}
            @prompt['msg']=msg
            udp.send(json ? @prompt.to_j : to_s,0,addr[2],addr[1])
          }
        }
      }
      self
    end
  end

  module Client
    def self.extended(obj)
      Msg.type?(obj,Shell).init
    end

    def init
      @udp=UDPSocket.open()
      @host||='localhost'
      @addr=Socket.pack_sockaddr_in(@port,@host)
      @v.msg{"Init/Client #{@host}:#{@port}"}
      self
    end

    def exe(cmd)
      line=cmd.empty? ? 'strobe' : cmd.join(' ')
      @udp.send(line,0,@addr)
      @v.msg{"Send [#{line}]"}
      input=@udp.recv(1024)
      @prompt.load(input)
      @v.msg{"Recv #{input}"}
      # Error message
      super if /ERROR/ =~ @prompt['msg']
      @post_exe.upd
      @prompt['msg']
    end
  end

  class Prompt < ExHash
    attr_reader :table
    def initialize
      @table={}
    end

    def to_s
      str=''
      each{|k,v|
        next if /msg/ === k
        str << (@table[k]||v) if v
      }
      str+'>'
    end
  end
end
