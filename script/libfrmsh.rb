#!/usr/bin/ruby
require 'libsh'
require 'libfield'
require "libfrmrsp"
require "libfrmcmd"
require 'libsitelist'

module CIAX
  module Frm
    # cfg should have :db(Frm::Db)
    def self.new(cfg)
      if $opt['s'] or $opt['e']
        cfg['iocmd']=['device-simulator',cfg[:db]['site_id']] if $opt['s']
        fsh=Frm::Sv.new(cfg)
        cfg['host']='localhost'
      end
      fsh=Frm::Cl.new(cfg) if $opt['c'] || (cfg['host']=$opt['h'])
      fsh||Frm::Test.new(cfg)
    end

    class Exe < Exe
      attr_reader :field,:sqlsv
      def initialize(cfg)
        @fdb=type?(cfg[:db],Db)
        @field=cfg[:field]=Field.new.skeleton(@fdb)
        super('frm',@field['id'],Command.new(cfg))
        @cobj.add_int
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
        @mode='TEST'
        @cobj.svdom.set_proc{|ent|@field['time']=now_msec;''}
        @cobj.ext_proc{|ent| "#{ent.cfg[:frame].inspect} => #{ent.cfg['response']}"}
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          "Set #{ent.par[0]}"
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.svdom.set_proc{to_s}
        ext_client(host,@fdb['port'])
        @pre_exe_procs << proc{@field.upd}
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super(cfg)
        @field.ext_rsp.ext_file
        timeout=5
        if sim=cfg['iocmd']
          @mode='SIM'
          timeout=20
        end
        iocmd= sim ? type?(sim,Array) : @fdb['iocmd'].split(' ')
        @stream=Stream.new(iocmd,@fdb['wait'],timeout)
        @sqlsv=@stream.ext_logging(@id,@fdb['version']) unless sim || ENV['NOSQLOG']
        @cobj.ext_proc{|ent|
          @stream.snd(ent.cfg[:frame],ent.id)
          @field.upd(ent){@stream.rcv}
          'OK'
        }
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        @cobj.item_proc('save'){|ent|
          @field.save_key(ent.par[0].split(','),ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.item_proc('load'){|ent|
          @field.load(ent.par[0]||'').save
          "Load [#{ent.par[0]}]"
        }
        ext_server(@fdb['port'].to_i)
      end
    end

    class List < Site::List
      def initialize(upper=nil)
        super(upper)
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:fdb]
        jumpgrp(Frm.new(@cfg))
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
