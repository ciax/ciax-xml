#!/usr/bin/env ruby
# CIAX-XML
module CIAX
  class Exe
    # Driver module
    module Driver
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # type of usage: shell/command line
      # type of semantics: execution/test
      def ext_local_driver
        ___init_log_mode
        ___init_processor_save
        ___init_processor_load
        self
      end

      private

      def ___init_log_mode
        return unless @opt.drv?
        @stat.ext_log
        @cobj.rem.ext_input_log
      end

      def ___init_processor_save
        @cobj.get('save').def_proc do |ent|
          @stat.save_partial(ent.par[0].split(','), ent.par[1])
          verbose { "Saving [#{ent.par[0]}]" }
        end
      end

      def ___init_processor_load
        item = @cobj.get('load')
        item.pars.first.list = @stat.tag_list
        item.def_proc do |ent|
          @stat.load_partial(ent.par[0] || '')
          verbose { "Loading [#{ent.par[0]}]" }
        end
      end
    end
  end
end
