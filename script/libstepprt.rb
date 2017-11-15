#!/usr/bin/ruby
require 'libstep'
# For Macro Line (Array)
module CIAX
  module Mcr
    # Mcr Step
    class Step
      def ext_prt(base)
        extend(Prt).ext_prt(base)
      end

      # Macro Printing Mix-in module
      module Prt
        include Msg
        OPE = { equal: '==', not: '!=', match: '=~', unmatch: '!~' }.freeze
        Title_List = {
          mesg: ['Mesg', 5], bypass: ['Bypass?', 6, 'skip if satisfied'],
          wait: ['Waiting', 6], goal: ['Done?', 6, 'skip if satisfied'],
          check: ['Check', 6, 'interlock'], verify: ['Verify', 6, 'at the end']
        }.freeze

        def ext_prt(base)
          @base = type?(base, Integer)
          ___init_title_list
          self
        end

        def title
          type = self[:type]
          self[:async] = '(async)' if key?(:async)
          ___head(*@title_list[type.to_sym])
        rescue NameError
          Msg.msg("No such type #{type}")
          type
        end

        def result
          mary = [___prt_count]
          ___prt_result(self[:result], mary)
          mary.join("\n") + "\n"
        end

        def action
          key?(:action) ? __body(self[:action].capitalize, 8) + "\n" : ''
        end

        # Display section
        def to_v
          title + result + action
        end

        # returns t/f
        def set_result(tmsg, fmsg = nil, tf = true)
          tf = super
          print result if Msg.fg?
          tf
        end

        private

        def __body(msg, col = 5)
          __rindent(5) + Msg.colorize(msg, col)
        end

        def ___prt_count
          total = self[:retry] || self[:val]
          total ? "(#{self[:count].to_i}/#{total})" : ''
        end

        def ___color_result(res)
          { faild: 1, timeout: 1, query: 5 }.each do |k, v|
            /#{k}/ =~ res && (return v)
          end
          2
        end

        def ___prt_result(res, mary)
          if res
            cap = res.capitalize
            color = ___color_result(res)
            mary[0] << ' -> ' + Msg.colorize(cap, color)
          end
          ___prt_conds(mary)
        end

        def ___prt_conds(mary)
          (self[:conditions] || {}).each do |h|
            mary << ___cond_result(h) + ___cond_line(h)
          end
        end

        def ___cond_result(h)
          return __body('!', 6) if h[:skip]
          return __body('o', 2) if h[:res]
          __body('x', %w(goal bypass).include?(self[:type]) ? 4 : 1)
        end

        def ___cond_line(h)
          line = " #{h[:site]}:#{h[:var]}(#{h[:form]})"
          cri = h[:cri]
          ope = OPE[h[:cmp].to_sym]
          cri = "/#{cri}/" if ope =~ /~/
          line << " #{ope} #{cri}?"
          line << " (#{h[:real]})" if !h[:res] || ope != '='
          line
        end

        def ___head(msg, col, label = 'noname')
          elps = format('[%6.2f]', (self[:time] - @base) * 0.001) + __rindent
          elps + Msg.colorize(msg, col) + ':' +
            (self[:label] || (label.is_a?(Proc) ? "[#{label.call}]" : label))
        end

        def __rindent(add = 0)
          Msg.indent((self[:depth].to_i + add) * 2)
        end

        # Branched functions (instead of case/when semantics)
        def ___init_title_list
          @title_list = {
            upd: ['Update', 10, __sid(:site)],
            system: ['System', 13, __sid(:val)],
            mcr: ['MACRO', 3, __sid(:args, :async)],
            exec: ['EXEC', 13, __sid(:site, :args)],
            cfg: ['Config', 14, __sid(:site, :args)],
            sleep: ['Sleeping(sec)', 6, __sid(:val)],
            select: ['Select by', 11, __sid(:site, :var)]
          }.update(Title_List)
        end

        def __sid(*names)
          proc { a2cid(names.map { |n| self[n] }) }
        end
      end
    end
  end
end
