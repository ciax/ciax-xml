#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    # Macro Printing Mix-in module
    module PrtShare
      def body(msg, col = 5)
        _rindent_(1) + Msg.colorize(msg, col)
      end

      def title
        args = self[:args].join(':') if key?(:args)
        case self[:type]
        when 'mesg'
          msg = _head_('Mesg', 5)
        when 'goal'
          msg = _head_('Done?', 6, 'skip if satisfied')
        when 'check'
          msg = _head_('Check', 6, 'interlock')
        when 'verify'
          msg = _head_('Verify', 6, 'at the end')
        when 'wait'
          msg = _head_('Waiting', 6)
        when 'mcr'
          msg = _head_('MACRO', 3, "#{self[:label]}(#{args})")
          msg << '(async)' if self[:async]
        when 'exec'
          msg = _head_('EXEC', 13, "[#{self[:site]}:#{args}]")
        when 'cfg'
          msg = _head_('Config', 14, "[#{self[:site]}:#{args}]")
        when 'upd'
          msg = _head_('Update', 10, "[#{self[:site]}]")
        end
        msg
      end

      def result
        mary = ['']
        total = self[:retry] || self[:sleep]
        mary[0] << "(#{self[:count]}/#{total})" if total
        res = self[:result]
        if res
          cap = res.capitalize
          color = (/failed|timeout/ =~ res) ? 1 : 2
          mary[0] << ' -> ' + Msg.colorize(cap, color)
          (self[:conditions] || {}).each do|h|
            res = h[:res] ? body('o', 2) : body('x', _fail_color_)
            cri = h[:cri]
            case h[:cmp]
            when 'equal'
              ope = '='
            when 'not'
              ope = '!='
            when 'match'
              ope = '=~'
              cri = "/#{cri}/"
            when 'unmatch'
              ope = '!~'
              cri = "/#{cri}/"
            end
            line = res + " #{h[:site]}:#{h[:var]}(#{h[:form]})"
            line << " #{ope} #{cri}?"
            line << " (#{h[:real]})" if !h[:res] || ope != '='
            mary << line
          end
        end
        mary << body(self[:action].capitalize, 8) if key?(:action)
        mary.join("\n") + "\n"
      end

      private

      def _head_(msg, col, label = 'noname')
        _rindent_ + Msg.colorize(msg, col) + ':' + (self[:label] || label)
      end

      def _fail_color_
        self[:type] == 'goal' ? 4 : 1
      end

      def _rindent_(add = 0)
        Msg.indent((self[:depth].to_i + add) * 2)
      end
    end
  end
end
