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
        dbe = type?(dbi, Dbx::Item)[type].freeze
        # Ent is needed which includes response_id and cmd_parameters
        ___mk_dic(dbe[:frame], dbe[:index]) if dbe
      end

      private

      def ___mk_dic(dbe, index)
        index.each do |id, item|
          put(id, item.attrs.update(struct: ___get_struct(dbe, item)))
        end
      end

      def ___get_struct(dbe, item)
        selb = item[:body] || []
        item[:noaffix] ? selb : ___mk_main(dbe, selb)
      end

      def ___mk_main(dbe, selb)
        dbe[:main].inject([]) do |a, e|
          case e[:type]
          when 'ccrange'
            a << ___mk_ccr(dbe, selb)
          else
            a + __mk_body(e.dup, selb)
          end
        end
      end

      def ___mk_ccr(dbe, selb)
        return unless dbe[:ccrange]
        dbe[:ccrange].inject([]) do |a, e|
          a + __mk_body(e.dup, selb)
        end
      end

      def __mk_body(e, selb)
        return [e] if e[:type] != 'body'
        e.delete(:type)
        selb.map { |h| h.update(e) }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libconf'
      # No option -> :command, -r: :response
      Opt::Conf.new('[id] [cmd]', options: 'h', r: 'response') do |cfg|
        mode = cfg.opt.delete(:r) ? :response : :command
        dbi = Db.new.get(cfg.args.shift)
        sel = Select.new(dbi, mode)
        puts sel.path(cfg.args)
      end
    end
  end
end
