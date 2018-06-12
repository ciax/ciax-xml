#!/usr/bin/ruby
require 'libmcrcmd'
require 'librecrsp'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sub Class
    class Sequencer
      private

      # Sub for for cmd_mcr()
      def ___mcr_fg(e, step, mstat)
        @count = step[:count] = 1 if step[:retry]
        _show step.result
        begin
          res = _sub_macro(_get_ment(e)[:sequence], step)
          return res if res
          mstat.result = step[:result]
          raise Interlock
        rescue Verification
          ___mcr_retry(e, step, mstat) && retry
        end
      end

      # Sub for _mcr_fg()
      def ___mcr_retry(e, step, mstat)
        return true if step[:retry] && ___count_up(e, step)
        mstat.result = 'failed'
        false
      end

      # Sub for _mcr_retry()
      def ___count_up(e, step)
        @count += 1
        step[:action] = 'retry'
        return false if @count > step[:retry].to_i # exit
        newstep = @record.add_step(e, @depth)
        newstep[:count] = @count
        newstep.cmt # continue
        sleep step[:wait].to_i
        true
      end

      # Sub for cmd_select()
      def ___get_stat(e)
        _get_site(e).stat[e[:form].to_sym][e[:var]]
      end

      ## Shared Methods
      def _get_site(e)
        @cfg[:dev_list].get(e[:site]).sub
      end

      def _exe_site(e)
        _get_site(e).exe(e[:args], 'macro')
      end

      # Mcr::Entity
      def _get_ment(e)
        @cfg[:index].set_cmd(e[:args])
      end

      def _giveup?(step)
        @qry.query(%w(drop force retry), step)
      end

      # Print section
      def _show(str = "\n")
        return unless Msg.fg?
        if defined? yield
          puts indent(@depth) + yield.to_s
        else
          print str
        end
      end
    end
  end
end
