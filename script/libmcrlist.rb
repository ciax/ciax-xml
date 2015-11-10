#!/usr/bin/ruby
require 'libmcrexe'
module CIAX
  module Mcr
    # Sequencer List which provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < CIAX::List
      def initialize(proj, cfg)
        super(cfg)
        self['id'] = proj
        verbose { "Initialize [#{proj}]" }
      end

      def interrupt
        @data.values.each do|seq|
          seq.exe(['interrupt'])
        end
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0')
        seq = Exe.new(ent, pid).fork # start immediately
        put(seq['id'], seq)
      end

      def clean
        @data.delete_if do|_, seq|
          ! (seq.is_a?(Exe) && seq.th_mcr.status)
        end
        upd
        self
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          # Limit self level
          # :dev_list is App::List
          @cfg[:dev_list].ext_shell if @cfg.key?(:dev_list)
          @cfg[:jump_mcr] = @jumpgrp
          @jumpgrp.add_item('dmy','dummy')
          @post_upd_procs << proc do
            verbose { 'Propagate List#upd -> JumpGrp#upd' }
            @jumpgrp.number_item(@data.values.map { |seq| seq['id'] })
          end
          self
        end

        def add(ent, pid = '0')
          seq = super.ext_shell
          seq.cobj.loc.add_jump
          seq
        end

        def get_exe(num)
          n = num.to_i - 1
          par_err('Invalid ID') if n < 0 || n > @data.size
          @data[keys[n]]
        end

        def shell
          num = @data.size.to_s
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
      cfg = Config.new(jump_groups: [])
      cfg[:dev_list] = Wat::List.new(cfg).sub_list # Take App List
      begin
        mobj = Remote::Index.new(cfg, dbi: Db.new.get)
        mobj.add_rem.add_ext(Ext)
        cfg[:submcr_proc] = proc do|args, pid|
          ent = mobj.set_cmd(args)
          list.add(ent, pid)
          end
        mobj.set_cmd if ARGV.empty?
        list = List.new(PROJ, cfg).ext_shell
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
