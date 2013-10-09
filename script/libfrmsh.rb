#!/usr/bin/ruby
require 'libsh'
require 'libfield'
require "libfrmrsp"
require "libfrmcmd"
require 'liblocdb'

module CIAX
  module Frm
    def self.new(cfg)
      if $opt['s'] or $opt['e']
        par=$opt['s'] ? ['frmsim',cfg[:db]['site_id']] : []
        fsh=Frm::Sv.new(cfg,par)
        fsh=Frm::Cl.new(cfg,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        fsh=Frm::Cl.new(cfg,host)
      else
        fsh=Frm::Test.new(cfg)
      end
      fsh
    end

    class Exe < Exe
      # @< cobj,output,(upd_procs*)
      # @ field*
      attr_reader :field
      def initialize(cfg)
        fdb=type?(cfg[:db],Db)
        @field=Field.new(fdb[:field][:struct].deep_copy)
        super('frm',fdb['site_id']||fdb['id'],ExtCmd.new(cfg,@field))
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
      def initialize(cfg)
        super
        @cobj['sv'].set_proc{|ent|@field['time']=UnixTime.now}
        @cobj['sv']['int']['set'].set_proc{|ent|
          @field.set(ent.par[0],ent.par[1])
        }
      end
    end

    class Cl < Exe
      def initialize(cfg,host=nil)
        super(cfg)
        host=type?(host||cfg[:db]['host']||'localhost',String)
        @field.ext_http(self['id'],host).load
        @cobj['sv'].set_proc{to_s}
        ext_client(host,cfg[:db]['port'])
        @upd_procs << proc{@field.load}
      end
    end

    class Sv < Exe
      # @<< cobj,(output),(upd_procs*)
      # @< field*
      # @ io
      attr_reader :sqlsv
      def initialize(cfg,iocmd=[])
        super(cfg)
        @field.ext_rsp(cfg[:db]).ext_file(self['id']).load
        if type?(iocmd,Array).empty?
          @io=Stream.new(cfg[:db]['iocmd'].split(' '),cfg[:db]['wait'],1)
          @sqlsv=@io.ext_logging(self['id'],cfg[:db]['version'])
        else
          @sqlsv=@io=Stream.new(iocmd,cfg[:db]['wait'],1)
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
        ext_server(cfg[:db]['port'].to_i)
      rescue Errno::ENOENT
        warning("FrmSv"," --- no json file")
      end
    end

    class List < ShList
      def new_val(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:frm]
        Frm.new(@cfg)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('cet')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
