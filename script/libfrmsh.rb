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

    class Exe < Exe
      # @< cobj,output,(upd_proc*)
      # @ field*
      attr_reader :field
      def initialize(fdb,id=nil)
        type?(fdb,Db)
        @field=Field.new(fdb[:field][:struct].deep_copy)
        super('frm',id||fdb['id'],ExtCmd.new(fdb,@field))
        ext_shell(@field)
      end

      private
      def shell_input(line)
        args=line.split(/[ =]/)
        args.unshift 'set' if /^[^ ]+\=/ === line
        args
      end
    end

    class Test < Exe
      def initialize(fdb)
        super(fdb)
        @cobj['sv'].set_proc{|ent|@field['time']=UnixTime.now}
        @cobj['sv']['int']['set'].set_proc{|ent|
          @field.set(ent.par[0],ent.par[1])
        }
      end
    end

    class Cl < Exe
      def initialize(fdb,host=nil)
        super(fdb,fdb['site_id'])
        host=type?(host||fdb['host']||'localhost',String)
        @field.ext_http(self['id'],host).load
        @cobj['sv'].set_proc{to_s}
        ext_client(host,fdb['port'])
        @upd_proc << proc{@field.load}
      end
    end

    class Sv < Exe
      # @<< cobj,(output),(upd_proc*)
      # @< field*
      # @ io
      attr_reader :sqlsv
      def initialize(fdb,iocmd=[])
        super(fdb,fdb['site_id'])
        @field.ext_rsp(fdb).ext_file(self['id']).load
        if type?(iocmd,Array).empty?
          @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
          @sqlsv=@io.ext_logging(self['id'],fdb['version'])
        else
          @sqlsv=@io=Stream.new(iocmd,fdb['wait'],1)
        end
        @cobj['sv']['ext'].set_proc{|ent|
          @io.snd(ent.cfg[:frame],ent.cfg[:cid])
          @field.upd(ent){@io.rcv} && @field.save
        }
        @cobj['sv']['int']['set'].set_proc{|ent|
          @field.set(ent.par[0],ent.par[1]).save
        }
        @cobj['sv']['int']['save'].set_proc{|ent|
          @field.savekey(ent.par[0].split(','),ent.par[1])
        }
        @cobj['sv']['int']['load'].set_proc{|ent|
          @field.load(ent.par[0]||'').save
        }
        ext_server(fdb['port'].to_i)
      rescue Errno::ENOENT
        warning("FrmSv"," --- no json file")
      end
    end

    class List < ShList
      def initialize
        @ldb=Loc::Db.new
        super{|id| Frm.new(@ldb.set(id)[:frm])}
        update_items(@ldb.list)
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('cet')
    begin
      puts Frm::List.new.shell(ARGV.shift)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
