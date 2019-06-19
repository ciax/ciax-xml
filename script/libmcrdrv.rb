#!/usr/bin/env ruby
require 'libexedrv'
require 'libseq'
require 'libthreadx'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Executor
    # Local mode only
    class Exe
      # Driver module
      module Driver
        include CIAX::Exe::Driver
        attr_reader :thread, :seq
        def ext_driver(&submcr_proc)
          super
          @seq = Sequencer.new(@cfg, &submcr_proc)
          @id = @seq.id
          @int.def_proc { |ent| @seq.reply(ent.id) }
          @stat = @seq.record
          ___init_run
          self
        end

        def run
          @thread = Threadx::Fork.new('Macro', 'seq', @id) do
            @sys.valid_keys.delete('run')
            @seq.play
          end
          _set_def_proc('interrupt') { @thread.raise(Interrupt) }
          self
        end

        private

        def ___init_run
          @sys.add_form('run', 'seqence').def_proc { run }
          @valid_keys << 'run'
        end
      end
    end
  end
end
