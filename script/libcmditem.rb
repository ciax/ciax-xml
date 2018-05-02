#!/usr/bin/ruby
require 'libcmdentity'
require 'librerange'
module CIAX
  # Command Module
  module CmdBase
    # Corresponds commands
    class Item < Hashx
      include CmdProc
      # grp_cfg should have :id,'label',:parameters,:def_proc,:def_msg
      attr_reader :id
      def initialize(cfg, atrb = Hashx.new)
        super()
        @cfg = cfg.gen(self).update(atrb)
        @id = @cfg[:id]
      end

      # element of par could be formula
      def set_par(pary, opt = {})
        # override
        pary = @cfg[:argv] if @cfg[:argv].is_a? Array
        # validate and convert pars
        par = ___validate(type?(pary, Array).dup)
        cid = [@id, *par].join(':')
        opt.update(par: par, cid: cid)
        verbose { "SetPAR(#{@id}): #{par}" }
        ___get_entity(opt, cid)
      end

      def valid_pars
        @cfg[:parameters].to_a.map(&:valid_pars).flatten
      end

      private

      def ___get_entity(opt, cid)
        return _get_cache(cid) if key?(cid)
        ent = _gen_entity(opt)
        return ___no_cache(cid, ent) if @cfg[:nocache]
        verbose { "SetPAR: Entity Cache Saved (#{cid})" }
        self[cid] = ent
      end

      def _get_cache(cid)
        verbose { "SetPAR: Entity Cache found(#{cid})" }
        self[cid]
      end

      def ___no_cache(cid, ent)
        verbose { "SetPAR: Entity No Cache Saved (#{cid})" }
        ent
      end

      def _gen_entity(opt)
        context_module('Entity').new(@cfg, opt)
      end

      # Parameter for validate(cfg[:parameters])
      #   structure:  [{:type,:list,:default}, ...]
      # *Empty parameter will replaced to :default
      # *Error if str doesn't match with strings listed in :list
      # *If no :list, returns :default
      # Returns converted parameter array
      def ___validate(pary)
        psize = pary.size
        @cfg[:parameters].to_a.map do |pref|
          pref.validate(pary.shift)
        end
      rescue ParShortage
        ___err_shortage($ERROR_INFO.to_s, psize)
      end

      def ___err_shortage(listcsv, psize)
        frac = format('(%d/%d)', psize, @cfg[:parameters].size)
        mary = ['Parameter shortage ' + frac]
        mary << @cfg[:disp].item(@id)
        mary << ' ' * 10 + "key=(#{listcsv})"
        Msg.par_err(*mary)
      end
    end
  end
end
