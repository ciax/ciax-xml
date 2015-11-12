#!/usr/bin/ruby
require 'libupd'
module CIAX
  module Mcr
    class View < Upd
      def initialize(id,valid_keys)
        @valid_keys = valid_keys
        @id = id
      end

      def to_v
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        each do|id, rec|
          title = "[#{idx}] (#{id})(by #{get_cid(rec['pid'])})"
          msg = "#{rec['cid']} [#{rec['step']}/#{rec['total_steps']}]"
          msg << "(#{rec['stat']})"
          msg << optlist(rec['option'])
          page << Msg.item(title, msg)
          idx += 1
        end
        page.join("\n")
      end

      def core_upd
        @valid_keys.each do |id|
          put(id,get_rec(id)) unless key?(id)
        end
        each{ |rec| rec.upd }
        self
      end

      def get_rec(id)
        Record.new(id).ext_save.ext_load
      end

      if __FILE__ == $PROGRAM_NAME
        OPT.parse('tenr')
        cfg = Config.new
        cfg[:dev_list] = Wat::List.new(cfg).sub_list # Take App List
        begin
          mobj = Remote::Index.new(cfg, dbi: Db.new.get)
          mobj.add_rem.add_ext(Ext)
          cfg[:submcr_proc] = proc do|args, pid|
            ent = mobj.set_cmd(args)
            list.add(ent, pid)
          end
          mobj.set_cmd if ARGV.empty?
          list = List.new(PROJ, cfg).ext_drv.ext_shell
          ARGV.each do|cid|
            ent = mobj.set_cmd(cid.split(':'))
            list.add(ent)
          end
          list.shell
        rescue InvalidCMD
          OPT.usage('[cmd(:par)] ...')
        rescue InvalidID
          OPT.usage('[proj] [cmd] (par)')
        end
      end
    end
  end
end
