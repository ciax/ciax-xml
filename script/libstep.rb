#!/usr/bin/ruby
require 'libupd'
require 'libinterlock'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      include PrtShare
      def initialize(db, dev_list)
        super()
        update db
        # [:stat_proc,:exec_proc,:submcr_proc,:query]
        @interlock=Interlock.new(delete('cond'),dev_list,self)
        @break = nil
      end

      # Conditional judgment section
      def timeout?
        itv = (OPT['e'] || OPT['s']) ? 0.1 : 0
        itv *= 10 if OPT['m']
        show title
        max = self['max'] = self['retry']
        res = max.to_i.times do|n| # gives number or nil(if break)
          self['retry'] = n
          break if @interlock.ok?
          sleep itv
          yield
          post_upd
        end
        self['result'] = res ? 'timeout' : 'pass'
        upd
        res
      end

      def ok?
        show title
        upd
        'ok'
      end

      def skip?
        show title
        res = @interlock.ok?('skip', 'pass')
        upd
        res
      end

      def fail?
        show title
        res = !@interlock.ok?('pass', 'failed')
        upd
        res
      end

      # Interactive section
      def exec?
        show title
        res = !dryrun?
        self['result'] = res ? 'exec' : 'skip'
        upd
        res
      end

      # Execution section
      def async?
        show title
        res = (/true|1/ =~ self['async'])
        self['result'] = res ? 'forked' : 'entering'
        upd
        res
      end

      # Display section
      def to_v
        title + result
      end

      private

      def upd_core
        show result
        self
      end

      def show(msg)
        print msg if Msg.fg?
      end

      def dryrun?
        !OPT['m'] && self['action'] = 'dryrun'
      end
    end
  end
end
