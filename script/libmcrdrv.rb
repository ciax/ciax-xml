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
          self
        end

        def batch
          @seq.play
          self
        end

        def run
          @thread = Threadx::Fork.new('Macro', 'seq', @id) { batch }
          _set_def_proc('interrupt') { @thread.raise(Interrupt) }
          super
        end

        private

        def _ext_shell
          run
          super
        end
      end
    end
  end
end
