#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcmdext"
require "libupdate"

# Provide Server,Client and Shell
# Integrate Command,Var
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)
# Add Shell Command (by Shell extention)

module Sh
  # @ cobj,output,upd_proc
  # @ prompt,lodom
  class Exe < ExHash # Having server status {id,msg,...}
    attr_reader :upd_proc,:output,:svdom,:lodom,:item
    # block gives command line convert
    def initialize(output={},prompt=self)
      init_ver(self,2)
      @cobj=Command.new
      @upd_proc=UpdProc.new # Proc for Server Status Update
      @svdom=@cobj.add_domain('sv',2) # Server Commands (service commands on Server)
      @interrupt=@svdom.add_group('hid',"Hidden Group").add_item('interrupt')
      # For Shell
      @output=output
      @prompt=prompt
      @item=nil
      @lodom=@cobj.add_domain('lo',9) # Local Commands (local handling commands on Client)
      shg=@lodom.add_dummy('sh',"Shell Command")
      shg.add_item('^D,q',"Quit")
      shg.add_item('^C',"Interrupt")
      Readline.completion_proc=proc{|word|
        @cobj.keys.grep(/^#{word}/)
      }
      Thread.abort_on_exception=true
    end

    # Sync only (Wait for other thread)
    def exe(cmd)
      if cmd.empty?
        self['msg']=''
      else
        self['msg']='OK'
        verbose{"Command #{cmd} recieved"}
        @item=@cobj.setcmd(cmd).exe
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
          exe(shell_input(line))
          puts shell_output
        end
      rescue Interrupt
        exe(['interrupt'])
        puts self['msg']
        retry
      rescue InvalidID
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
    def shell_input(line)
      line.split(' ')
    end

    def shell_output
      self['msg'].empty? ? @output : self['msg']
    end

    def server_input(line)
      JSON.load(line)
    rescue JSON::ParserError
      raise "NOT JSON"
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
      init_ver('UDPsv/%s',2,self)
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
      init_ver('UDPcl/%s',6,self)
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

  class List < ExHash
    # shdom: Domain for Shared Command Groups
    attr_accessor :shdom,:current
    def initialize(current=nil)
      $opt||=Msg::GetOpts.new
      @shdom=Command::Domain.new(5)
      @current=current||""
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue InvalidID
      $opt.usage('(opt) [id] [cmd] [par....]')
    end

    def shell
      while current=catch(:sw_site){ self[@current].shell }
        @current.replace current
      end
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end

  class DevList < List
    # shdom: Domain for Shared Command Groups
    attr_accessor :swsgrp
    def initialize(list,current=nil)
      Msg.type?(list,Msg::CmdList)
      super(current)
      @swsgrp=@shdom.add_group('sws','Switch Sites')
      @swsgrp.update_items(list).reset_proc{|item|
        throw(:sw_site,item.id)
      }
    end

    def [](key)
      if key?(key)
        super
      else
        sh=self[key]=newsh(key)
        sh.lodom.update @shdom
        sh
      end
    end

    def server(ary)
      ary.each{|i|
        sleep 0.3
        self[i]
      }.empty? && self[nil]
      sleep
    rescue InvalidID
      $opt.usage('(opt) [id] ....')
    end

    private
    def newsh(id)
    end
  end

  class Layer < Hash
    def initialize(current=nil)
      @current=current
      @shdom=Command::Domain.new(5)
      @swlgrp=@shdom.add_group('swl',"Switch Layer")
      @swlgrp.reset_proc{|item| throw(:sw_layer,item.id) }
    end

    def shell
      layer_menu
      @current||=keys.last
      while current=catch(:sw_layer){self[@current].shell}
        @current.replace current
      end
    end

    private
    def layer_menu
      each{|k,list|
        @swlgrp.add_item(k,k.capitalize+" mode")
        list.shdom.update @shdom
      }
    end
  end
end
