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
        @fdb=type?(cfg[:db],Db)
        super('frm',@fdb['site_id']||@fdb['id'],Command.new(cfg))
        @cobj.add_int
        @field=@cobj.field
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
        @cobj.svdom.set_proc{|ent|@field['time']=UnixTime.now;'OK'}
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          "Set #{ent.par[0]}"
        }
      end
    end

    class Cl < Exe
      def initialize(cfg,host=nil)
        super(cfg)
        host=type?(host||@fdb['host']||'localhost',String)
        @field.ext_http(self['id'],host).load
        @cobj.svdom.set_proc{to_s}
        ext_client(host,@fdb['port'])
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
        @field.ext_rsp(@fdb).ext_file(self['id']).load
        if type?(iocmd,Array).empty?
          @io=Stream.new(@fdb['iocmd'].split(' '),@fdb['wait'],1)
          @sqlsv=@io.ext_logging(self['id'],@fdb['version'])
        else
          @sqlsv=@io=Stream.new(iocmd,@fdb['wait'],1)
        end
        @cobj.ext_proc{|ent|
          @io.snd(ent.cfg[:frame],ent.cfg[:cid])
          @field.upd(ent){@io.rcv} && @field.save
          'OK'
        }
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1]).save
          "Set [#{ent.par[0]}]"
        }
        @cobj.item_proc('save'){|ent|
          @field.savekey(ent.par[0].split(','),ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.item_proc('load'){|ent|
          @field.load(ent.par[0]||'').save
          "Load [#{ent.par[0]}]"
        }
        ext_server(@fdb['port'].to_i)
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
