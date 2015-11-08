#!/usr/bin/ruby
require 'libseqexe'
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

      def get_exe(num)
        n = num.to_i - 1
        par_err('Invalid ID') if n < 0 || n > @data.size
        @data[keys[n]]
      end

      # Getting command ID (ex. run:1)
      def get_cid(id)
        return 'user' if id == '0'
        get(id)['cid']
      end
    end
  end
end
