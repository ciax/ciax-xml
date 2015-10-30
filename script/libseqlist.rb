#!/usr/bin/ruby
require 'libseqexe'
module CIAX
  module Mcr
    # Sequencer Layer List
    module Seq
      # @cfg[:db] associated site/layer should be set
      class List < CIAX::List
        def initialize(proj, cfg)
          super(cfg)
          self['id'] = proj
          verbose { "Initialize [#{proj}]" }
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

        def ext_drv
          extend(Drv).ext_drv
        end

        def ext_shell
          extend(Shell).ext_shell
        end

        private

        # Getting command ID (ex. run:1)
        def get_cid(id)
          return 'user' if id == '0'
          get(id)['cid']
        end

        ### Server methods
        module Drv
          def ext_drv
            ext_save.ext_load
            clean
            self
          end

          def interrupt
            @data.values.each do|seq|
              seq.exe(['interrupt'])
            end
          end

          # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
          def add(ent, pid = '0')
            seq = Exe.new(ent, pid).fork
            seq.post_stat_procs << proc { upd }
            put(seq['id'], seq)
          end

          def clean
            @data.delete_if do|_, seq|
              ! (seq.is_a?(Exe) && seq.th_mcr.status)
            end
            upd
            self
          end
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
      end

      if __FILE__ == $PROGRAM_NAME
        OPT.parse('tenr')
        cfg = Config.new
        cfg[:dev_list] = Wat::List.new(cfg).sub_list # Take App List
        list = List.new(PROJ, cfg).ext_drv.ext_shell
        mobj = Remote::Index.new(cfg,  dbi: Db.new.get(PROJ))
        mobj.add_rem.add_ext(Ext)
        cfg[:submcr_proc] = proc do|args, pid|
          ent = mobj.set_cmd(args)
          list.add(ent, pid)
        end
        begin
          mobj.set_cmd if ARGV.empty?
          ARGV.each do|cid|
            ent = mobj.set_cmd(cid.split(':'))
            list.add(ent)
          end
          list.shell
        rescue InvalidCMD
          OPT.usage('[cmd(:par)] ...')
        end
      end
    end
  end
end
