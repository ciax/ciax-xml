#!/usr/bin/env ruby
require 'libfrmdb'
require 'libdic'
module CIAX
  # Frame Layer
  module Frm
    # Frame DB Selector
    class Select < Upd
      include Dic
      def initialize(dbi)
        super()
        ext_dic(:sel) { Hashx.new }
        # Ent is needed which includes response_id and cmd_parameters
        dbi = type?(dbi, Dbi)
        res = dbi[:response]
        frm = res[:frame]
        tmp = [dbi, res, frm].inject(Hashx.new) { |h, e| h.update(e.attributes) }
        ___make_sel(frm, res[:index], tmp)
      end

      def get(ent)
        rid = ent[:response]
        sel = super(rid) || Msg.cfg_err("No such response id [#{rid}]")
        # SelDB applied with Entity (set par)
        ent.deep_subst(sel.deep_copy)
      end

      private

      # @sel structure:
      #   { terminator, :main{}, ccrange{}, :body{} <- changes on every upd }
      def ___make_sel(dbe, index, tmp)
        index.each do |id, val|
          body = val[:body].map {|e| tmp.merge(e) } # Array
          put(id, ___mk_main(dbe, body, tmp))
        end
      end

      def ___mk_ccr(dbe, body, tmp)
        return unless dbe[:ccrange]
        dbe[:ccrange].inject([]) do |a, e|
          e[:type] == 'body' ? a.concat(body) : a << tmp.merge(e)
        end
      end
          
      def ___mk_main(dbe, body, tmp)
        dbe[:main].inject([]) do |a, e|
          case e[:type]
          when 'body'
            a.concat(body)
          when 'ccrange'
            a << ___mk_ccr(dbe, body, tmp)
          else
            a << tmp.merge(e)
          end
        end
      end


      def ___make_data
        @cache = _dic.deep_copy
        if @sel.key?(:noaffix)
          __getfield_rec(['body'])
        else
          __getfield_rec(@sel[:main])
          @rspfrm.cc_check(@cache.delete('cc'))
        end
        _dic.replace(@cache)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      ConfOpts.new('[id] [cmd]', options: 'h') do |cfg|
        dbi = Db.new.get(cfg.args.shift)
        sel = Select.new(dbi)
        puts sel.path(cfg.args)
      end
    end
  end
end
