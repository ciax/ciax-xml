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
        ext_dic(:sel){ Hashx.new }
        # Ent is needed which includes response_id and cmd_parameters
        @dbi = type?(dbi, Dbi)
        @fdbr = @dbi[:response]
        @fds = @fdbr[:index]
        @body = Hashx.new
        @ccrange = Hashx.new
        ___make_sel
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
      def ___make_sel
        @fds.each do |id, val|
          body = val[:body]
          all = Hashx[@fdbr[:frame]]
          if all[:ccrange]
            ccrange = []
            all[:ccrange].each do |e|
              e[:type] == "body" ? ccrange.concat(body) : ccrange << e
            end
            @ccrange[id] = ccrange
          else
            main = []
            all[:main].each do |e|
              case e[:type]
              when "body"
                main.concat(body)
              when "ccrange"
                main.concat(ccrange)
              else
                main << e
              end
            end
          end
          put(id, main)
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
