#!/usr/bin/ruby
require 'libsh'
require 'libfield'
require "libfrmrsp"
require "libfrmcmd"
require 'liblocdb'

module CIAX
  module Frm
    def self.new(fdb)
      if $opt['s'] or $opt['e']
        par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
        fsh=Frm::Sv.new(fdb,par)
        fsh=Frm::Cl.new(fdb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        fsh=Frm::Cl.new(fdb,host)
      else
        fsh=Frm::Test.new(fdb)
      end
      fsh
    end

    class Exe < Sh::Exe
      # @< cobj,output,(upd_proc*)
      # @ field*
      attr_reader :field
      def initialize(fdb)
        type?(fdb,Db)
        self['layer']='frm'
        self['id']=fdb['site_id']
        @field=Field.new(fdb[:structure][:select].deep_copy)
        cobj=ExtCmd.new(fdb,@field)
        prom=Sh::Prompt.new(self)
        super(cobj)
        ext_shell(@field,prom)
      end

      private
      def shell_input(line)
        cmd=line.split(/[ =]/)
        cmd.unshift 'set' if /^[^ ]+\=/ === line
        cmd
      end
    end

    class Test < Exe
      def initialize(fdb)
        super
        @cobj['sv'].def_proc=proc{|item|@field['time']=UnixTime.now}
        @cobj['sv']['int']['set'].def_proc=proc{|item|
          @field.set(item.par[0],item.par[1])
        }
      end
    end

    class Cl < Exe
      def initialize(fdb,host=nil)
        super(fdb)
        host=type?(host||fdb['host']||'localhost',String)
        @field.ext_http(self['id'],host).load
        @cobj['sv'].def_proc=proc{to_s}
        ext_client(host,fdb['port'])
        @upd_proc.add{@field.load}
      end
    end

    class Sv < Exe
      # @<< cobj,(output),(upd_proc*)
      # @< field*
      # @ io
      def initialize(fdb,iocmd=[])
        super(fdb)
        @field.ext_rsp(fdb).load
        if type?(iocmd,Array).empty?
          @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
          @io.ext_logging(fdb['site_id'],fdb['version'])
          # @field.ext_sqlog
        else
          @io=Stream.new(iocmd,fdb['wait'],1)
        end
        @cobj['sv']['ext'].def_proc=proc{|item|
          @io.snd(item.getframe,item[:cmd])
          @field.upd(item){@io.rcv} && @field.save
        }
        @cobj['sv']['int']['set'].def_proc=proc{|item|
          @field.set(item.par[0],item.par[1]).save
        }
        @cobj['sv']['int']['save'].def_proc=proc{|item|
          @field.savekey(item.par[0].split(','),item.par[1])
        }
        @cobj['sv']['int']['load'].def_proc=proc{|item|
          @field.loadkey(item.par[0]||'').save
        }
        ext_server(fdb['port'].to_i)
      rescue Errno::ENOENT
        warning("FrmSv"," --- no json file")
      end
    end

    class List < Sh::DevList
      def initialize(current=nil)
        @ldb=Loc::Db.new
        super(@ldb.list,"#{current}")
      end

      def newsh(id)
        Frm.new(@ldb.set(id)[:frm])
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('cet')
    begin
      puts Frm::List.new(ARGV.shift).shell
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
