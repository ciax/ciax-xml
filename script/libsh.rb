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
  # @ prompt,shdom
  class Exe < ExHash
    attr_reader :upd_proc,:output,:svdom,:shdom
    # block gives command line convert
    def initialize(output={},prompt=self)
      init_ver(self,2)
      @cobj=Command.new
      @output=output
      @upd_proc=UpdProc.new # Proc for Server Status Update
      # For Shell
      @prompt=prompt
      @svdom=@cobj.add_domain('sv',6) # Server Command
      @shdom=@cobj.add_domain('sh',9) # Shared Command
      Readline.completion_proc=proc{|word|
        @cobj.keys.grep(/^#{word}/)
      }
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
    def shell_conv(line)
      line
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
    attr_accessor :shdom,:current
    def initialize(list,current=nil)
      $opt||=Msg::GetOpts.new
      @shdom=Command::Domain.new(9)
      id_menu(list)
      quit_menu
      @current=current||""
      super(){|h,key|
        sh=h[key]=newsh(key)
        sh.shdom.replace @shdom
        sh
      }
    end

    def exe(stm)
      self[stm.shift].exe(stm)
    rescue InvalidID
      $opt.usage('(opt) [id] [cmd] [par....]')
    end

    def shell
      while current=self[@current].shell
        @current.replace current
      end
    rescue TransLayer
      raise(TransLayer,$!.to_s)
    rescue InvalidID
      $opt.usage('(opt) [id]')
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

    def quit_menu
      grp=@shdom.add_dummy('sh',"Shell Command")
      grp.update_items({'^D,q'=>"Quit",'^C'=>"Interrupt"})
    end

    def id_menu(list)
      grp=@shdom.add_group('id','Switch ID')
      grp.update_items(list).reset_proc{|item|
        raise(SelectID,item.id)
      }
    end
  end

  class Layer < Hash
    def initialize(current=nil)
      @current=current
    end

    def shell
      layer_menu
      @current||=keys.last
      begin
        self[@current].shell
      rescue TransLayer
        @current=$!.to_s
        retry
      end
    end

    private
    def layer_menu
      list={}
      keys.each{|k|
        list[k]=k.capitalize+" mode"
      }
      values.each{|v|
        grp=v.shdom.add_group('lay',"Change Layer")
        grp.update_items(list)
        grp.reset_proc{|item| raise(TransLayer,item.id)}
      }
    end
  end
end
