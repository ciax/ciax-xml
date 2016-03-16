#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    # Macro Printing Mix-in module
    module PrtShare
      OPE = { equal: '==', not: '!=', match: '=~', unmatch: '!~' }
      def body(msg, col = 5)
        _rindent_(1) + Msg.colorize(msg, col)
      end

      def title
        args = self[:args].join(':') if key?(:args)
        method('prt_' + self[:type]).call(args)
      rescue NameError
        Msg.msg("No such type #{self[:type]}")
        self[:type]
      end

      def result
        mary = ['']
        total = self[:retry] || self[:sleep]
        mary[0] << "(#{self[:count]}/#{total})" if total
        res = self[:result]
        _prt_result(res, mary)
        mary << body(self[:action].capitalize, 8) if key?(:action)
        mary.join("\n") + "\n"
      end

      private

      def _prt_result(res, mary)
        return unless res
        cap = res.capitalize
        color = (/failed|timeout/ =~ res) ? 1 : 2
        mary[0] << ' -> ' + Msg.colorize(cap, color)
        _prt_conds(mary)
      end

      def _prt_conds(mary)
        (self[:conditions] || {}).each do|h|
          res = h[:res] ? body('o', 2) : body('x', _fail_color_)
          mary << res + _cond_line(h)
        end
      end

      def _cond_line(h)
        line = " #{h[:site]}:#{h[:var]}(#{h[:form]})"
        cri = h[:cri]
        ope = OPE[h[:cmp].to_sym]
        cri = "/#{cri}/" if ope =~ /~/
        line << " #{ope} #{cri}?"
        line << " (#{h[:real]})" if !h[:res] || ope != '='
      end

      def _head_(msg, col, label = 'noname')
        _rindent_ + Msg.colorize(msg, col) + ':' + (self[:label] || label)
      end

      def _fail_color_
        self[:type] == 'goal' ? 4 : 1
      end

      def _rindent_(add = 0)
        Msg.indent((self[:depth].to_i + add) * 2)
      end

      # Branched functions (instead of case/when semantics)
      def prt_mesg(_)
        _head_('Mesg', 5)
      end

      def prt_goal(_)
        _head_('Done?', 6, 'skip if satisfied')
      end

      def prt_check(_)
        _head_('Check', 6, 'interlock')
      end

      def prt_verify(_)
        _head_('Verify', 6, 'at the end')
      end

      def prt_wait(_)
        _head_('Waiting', 6)
      end

      def prt_mcr(args)
        async = self[:async] ? '(async)' : ''
        _head_('MACRO', 3, "#{self[:label]}(#{args})#{async}")
      end

      def prt_exec(args)
        _head_('EXEC', 13, "[#{self[:site]}:#{args}]")
      end

      def prt_cfg(args)
        _head_('Config', 14, "[#{self[:site]}:#{args}]")
      end

      def prt_upd(_)
        _head_('Update', 10, "[#{self[:site]}]")
      end

      def prt_select(_)
        _head_('Select by', 11, "[#{self[:site]}:#{self[:var]}]")
      end
    end
  end
end
