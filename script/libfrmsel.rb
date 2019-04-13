#!/usr/bin/env ruby
require 'libfrmdb'
module CIAX
  # Frame Layer
  module Frm
    # Frame DB Selector
    class Select < Hashx
      # type = //response or //command
      def initialize(dbi, type)
        super()
        dbe = type?(dbi, Dbx::Item)[type]
        # Ent is needed which includes response_id and cmd_parameters
        ___mk_dic(dbe[:frame], dbe[:index])
      end

      private

      def ___mk_dic(dbe, index)
        index.each do |id, item|
          put(id, item.attrs.update(struct: ___get_struct(dbe, item)))
        end
      end

      def ___get_struct(dbe, item)
        body = item[:body] || []
        item[:noaffix] ? body : ___mk_main(dbe, body)
      end

      def ___mk_main(dbe, body)
        dbe[:main].inject([]) do |a, e|
          case e[:type]
          when 'ccrange'
            a << ___mk_ccr(dbe, body)
          when 'body'
            a + body
          else
            a << e
          end
        end
      end

      def ___mk_ccr(dbe, body)
        return unless dbe[:ccrange]
        dbe[:ccrange].inject([]) do |a, e|
          a + (e[:type] == 'body' ? body : [e])
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libconf'
      # No option -> :command, -r: :response
      ConfOpts.new('[id] [cmd]', options: 'h', r: 'response') do |cfg|
        mode = cfg.opt.delete(:r) ? :response : :command
        dbi = Db.new.get(cfg.args.shift)
        sel = Select.new(dbi, mode)
        puts sel.path(cfg.args)
      end
    end
  end
end
