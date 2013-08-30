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
        @cobj['sv'].share[:def_proc]=proc{|item|@field['time']=UnixTime.now}
        @cobj['sv']['int']['set'].share[:def_proc]=proc{|item|
          @field.set(item.par[0],item.par[1])
        }
      end
    end

    class Cl < Exe
      def initialize(fdb,host=nil)
        super(fdb,fdb['site_id'])
        host=type?(host||fdb['host']||'localhost',String)
        @field.ext_http(self['id'],host).load
        @cobj['sv'].share[:def_proc]=proc{to_s}
        ext_client(host,fdb['port'])
        @upd_proc << proc{@field.load}
      end
    end

    class Sv < Exe
      # @<< cobj,(output),(upd_proc*)
      # @< field*
      # @ io
      def initialize(fdb,iocmd=[])
        super(fdb,fdb['site_id'])
        @field.ext_rsp(fdb).ext_file(self['id']).load
        if type?(iocmd,Array).empty?
          @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
          @io.ext_logging(self['id'],fdb['version'])
        else
          @io=Stream.new(iocmd,fdb['wait'],1)
        end
        @cobj['sv']['ext'].share[:def_proc]=proc{|item|
          @io.snd(item.getframe,item[:cid])
          @field.upd(item){@io.rcv} && @field.save
        }
        @cobj['sv']['int']['set'].share[:def_proc]=proc{|item|
          @field.set(item.par[0],item.par[1]).save
        }
        @cobj['sv']['int']['save'].share[:def_proc]=proc{|item|
          @field.savekey(item.par[0].split(','),item.par[1])
        }
        @cobj['sv']['int']['load'].share[:def_proc]=proc{|item|
          @field.load(item.par[0]||'').save
        }
        ext_server(fdb['port'].to_i)
      rescue Errno::ENOENT
        warning("FrmSv"," --- no json file")
      end
    end

    class List < ShList
      def initialize
        super{|id| Frm.new(@ldb.set(id)[:frm])}
        @ldb=Loc::Db.new
        update_items(@ldb.list)
        @layers['frm']=self
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
