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

module Sh
  # @ cobj,output,intgrp,interrupt,upd_proc
  # @ prompt,shdom
  class Exe < ExHash
    attr_reader :upd_proc,:interrupt,:output,:shdom,:intgrp
    # block gives command line convert
    def initialize(output={},prompt=self)
      init_ver(self,2)
      @cobj=Command.new
      @output=output
      @intgrp=@cobj.add_domain('int',2).add_group('int',"Internal Command")
      @interrupt=@intgrp.add_item('interrupt')
      @upd_proc=UpdProc.new # Proc for Server Status Update
      # For Shell
      @prompt=prompt
      @shdom=@cobj.add_domain('sh',5)
      Readline.completion_proc=proc{|word|
        @cobj.keys.grep(/^#{word}/)
      }
      grp=@shdom.add_dummy('sh',"Shell Command")
      grp.update_items({'^D,q'=>"Quit",'^C'=>"Interrupt"})
    end

    # Sync only (Wait for other thread)
    def exe(cmd)
      if cmd.empty?
        self['msg']=''
      else
        self['msg']='OK'
        verbose{"Command #{cmd} recieved"}
        @cobj.setcmd(cmd).exe
      end
      self
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_proc.upd
    end

    # invoked many times
    # '^D' gives exit break
    # mode gives special break (loop returns mode)
    def shell
      init_ver('Shell/%s',2,self)
      verbose{"Init/Shell(#{self['id']})"}
      begin
        while line=Readline.readline(@prompt.to_s,true)
          break if /^q/ === line
          line=shell_conv(line)
          res=exe(line.split(' '))
          puts res['msg'].empty? ? @output : res['msg']
        end
      rescue SelectID
        $!.to_s
      rescue Interrupt
        puts exe(['interrupt'])['msg']
        retry
      rescue UserError
        puts $!.to_s
        retry
      end
    end

    def ext_client(host,port)
      extend(Client).ext_client(host,port)
    end

    def ext_server(port)
      extend(Server).ext_server(port)
    end

    # Overridable methods(do not set this kind of methods in modules)
    private
    def shell_conv(line)
      line
    end

    def server_input(line)
      JSON.load(line)
    rescue JSON::ParserError
      raise UserError,"NOT JSON"
    end

    def server_output
      to_j
    end
  end

  module Server
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # JSON expression of server stat will be sent.
    def ext_server(port)
      init_ver('Server/%s',2,self)
      verbose{"Init/Server(#{self['id']}):#{port}"}
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
            verbose{"Recv:#{line} is #{line.class}"}
            begin
              exe(server_input(line))
            rescue InvalidCMD
              self['msg']="INVALID"
            rescue RuntimeError
              warn($!.to_s)
              self['msg']=$!.to_s
            end
            verbose{"Send:#{self['msg']}"}
            udp.send(server_output,0,addr[2],addr[1])
          }
        }
      }
      self
    end

  end

  module Client
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    def ext_client(host,port)
      host||='localhost'
      @udp=UDPSocket.open()
      @addr=Socket.pack_sockaddr_in(port.to_i,host)
      verbose{"Init/Client(#{self['id']})#{host}:#{port}"}
      self
    end

    # For client
    def exe(cmd)
      @cobj.setcmd(cmd).exe unless cmd.empty?
      @udp.send(JSON.dump(cmd),0,@addr)
      verbose{"Send [#{cmd}]"}
      input=@udp.recv(1024)
      verbose{"Recv #{input}"}
      load(input) # ExHash#load -> Server Status
      self
    rescue
      self['msg']=$!.to_s
      raise $!
    ensure
      @upd_proc.upd
    end
  end

  class Prompt < Hash
    def initialize(stat,db={})
      @stat=Msg.type?(stat,Hash)
      update Msg.type?(db,Hash)
      @prefix="#{stat['layer']}:#{stat['id']}"
    end

    def to_s
      str=@prefix.dup
      each{|k,cmp|
        next unless v=@stat[k]
        case cmp
        when String
          str << cmp % v
        when Hash
          str << cmp[v]
        else
          str << v
        end
      }
      str << '>'
    end
  end

  class List < Hash
    def initialize(id)
      $opt||=Msg::GetOpts.new
      super(){|h,id|
        h[id]=newsh(id)
      }
      @crnt=self[id]
    rescue UserError
      $opt.usage('(opt) [id] (layer)')
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue UserError
      $opt.usage('(opt) [id] [cmd] [par....]')
    end

    def shell
      while id=@crnt.shell
        begin
          @crnt=self[id]
        rescue InvalidID
          Msg.alert($!.to_s,1)
        end
      end
    end

    def server(ary)
      ary.each{|i|
        sleep 0.3
        self[i]
      }.empty? && self[nil]
      sleep
    rescue UserError
      $opt.usage('(opt) [id] ....')
    end

    def switch_id(sh,gid,title,list)
      Msg.type?(sh,Sh::Exe)
      grp=sh.shdom.add_group(gid,title)
      grp.update_items(list).reset_proc{|item|
        raise(SelectID,item.id)
      }
      sh
    end

    def switch_layer(sh,gid,title,list)
      Msg.type?(sh,Sh::Exe)
      grp=sh.shdom.add_group(gid,title)
      grp.update_items(list).reset_proc{|item|
        raise(TransLayer,item.id)
      }
      sh
    end

    private
    def newsh(id)
    end
  end
end
