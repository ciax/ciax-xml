#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

class Interact
  attr_reader :updlist,:cmdlist
  def initialize(cobj,host=nil)
    @v=Msg::Ver.new(self,1)
    @cobj=Msg::type?(cobj,Command)
    @cmdlist=@cobj.list
    @prompt=Prompt.new
    @updlist=Update.new
    @port=0
    @host=host
    @cmdlist['internal']=Msg::CmdList.new("Internal Command",2)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
    'OK'
  end

  # 'q' gives exit break (loop returns nil)
  # mode gives special break (loop returns mode)
  def shell
    cmds=@cmdlist.all
    Readline.completion_proc= proc{|word|
      cmds.grep(/^#{word}/)
    } unless cmds.empty?
    cl=Msg::CmdList.new("Shell Command",2)
    @cmdlist['shell']=cl.update({'q'=>"Quit",'D^'=>"Interrupt"})
    loop {
      line=Readline.readline(@prompt.to_s,true)||'interrupt'
      break if /^q/ === line
      begin
        cmd=line.split(' ')
        # exe() includes status update when being Client
        # need to be executed even if cmd is empty or being Server
        msg=exe(cmd)
        if msg.empty?
          msg=to_s
        else
          @updlist.upd
        end
        puts msg
      rescue SelectID
        ['mode','layer','dev'].each{|i|
          next unless @cmdlist.key?(i)
          return line if @cmdlist[i].key?(line)
        }
        puts $!.to_s
      rescue UserError
        puts $!.to_s
      end
    }
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
            @updlist.upd unless msg.empty?
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
  def exe(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    input=@udp.recv(1024)
    @prompt.load(input)
    @v.msg{"Recv #{input}"}
    # Error message
    @cobj.set(cmd) if /ERROR/ =~ @prompt['msg']
    @updlist.upd
    @prompt['msg']
  end

  private
  def init_client
    @udp=UDPSocket.open()
    @host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
    self
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
