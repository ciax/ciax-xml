#!/usr/bin/ruby
require 'libseqexe'
module CIAX
  module Mcr
    class View < Upd
      def initialize(valid_keys)
        @valid_keys = valid_keys
        self['id'] = proj
      end

      def to_v
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{self['id']}]", 2) + ' >>>']
        @data.each do|id, seq|
          title = "[#{idx}] (#{id})(by #{get_cid(seq['pid'])})"
          msg = "#{seq['cid']} [#{seq['step']}/#{seq['total_steps']}]"
          msg << "(#{seq['stat']})"
          msg << optlist(seq['option'])
          page << Msg.item(title, msg)
          idx += 1
        end
        page.join("\n")
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          # Limit self level
          # :dev_list is App::List
          @cfg[:dev_list].ext_shell if @cfg.key?(:dev_list)
          @post_upd_procs << proc do
            verbose { 'Propagate List#upd -> JumpGrp#upd' }
            @jumpgrp.number_item(@data.values.map { |seq| seq['id'] })
          end
          self
        end

        def add(ent, pid = '0')
          super.ext_shell
        end

        def get_exe(num)
          n = num.to_i - 1
          par_err('Invalid ID') if n < 0 || n > @data.size
          @data[keys[n]]
        end

        def shell
          num = size.to_s
          begin
            get_exe(num).shell
          rescue Jump
            num = $ERROR_INFO.to_s
            retry
          rescue InvalidID
            OPT.usage('(opt) [site]')
          end
        end
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
