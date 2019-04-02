#!/usr/bin/env ruby
require 'libfrmdb'
module CIAX
  # Frame Layer
  module Frm
    # Frame DB Selector
    class Select < Hashx
      # dbe = //response or //command
      def initialize(dbi, type)
        super()
        @idtype = { command: :id, response: :response }[type]
        dbe = type?(dbi, Dbi)[type]
        # Ent is needed which includes response_id and cmd_parameters
        ___mk_sel(dbe[:frame], dbe[:index])
      end

      # type could be :response or :id(command)
      def get(ent)
        id = ent[@idtype]
        sel = super(id) || Msg.cfg_err("No such response id [#{id}]")
        # SelDB applied with Entity (set par)
        ent.deep_subst(sel.freeze)
      end

      private

      def ___mk_sel(dbe, index)
        index.each do |id, item|
          put(id, ___mk_body(dbe, item, dbe.attrs.merge(item.attrs)))
        end
      end

      def ___mk_body(dbe, item, tmp)
        body = (item[:body] || []).map { |e| tmp.merge(e) } # Array
        tmp[:noaffix] ? body : ___mk_main(dbe, body, tmp)
      end

      def ___mk_main(dbe, body, tmp)
        dbe[:main].inject([]) do |a, e|
          case e[:type]
          when 'ccrange'
            a << ___mk_ccr(dbe, body, tmp)
          when 'body'
            a + body
          else
            a << tmp.merge(e)
          end
        end
      end

      def ___mk_ccr(dbe, body, tmp)
        return unless dbe[:ccrange]
        dbe[:ccrange].inject([]) do |a, e|
          a + (e[:type] == 'body' ? body : [tmp.merge(e)])
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      require 'libdevdb'
      ConfOpts.new('[id] [cmd]', options: 'h') do |cfg|
        dbi = Dev::Db.new.get(cfg.args.shift)
        atrb = { dbi: dbi, stream: dbi[:stream], field: Field.new(dbi[:id]) }
        cobj = Index.new(cfg, atrb)
        cobj.add_rem.add_ext
        ent = cobj.set_cmd(cfg.args)
        sel = Select.new(dbi, :response)
        puts sel.get(ent).path(cfg.args)
      end
    end
  end
end
