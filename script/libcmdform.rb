#!/usr/bin/env ruby
require 'libcmdentity'
module CIAX
  # Command Module
  module CmdBase
    # Corresponds commands
    class Form < Hashx
      include CmdFunc
      # grp_cfg should have :id,'label',:parameters,:def_proc,:def_msg
      attr_reader :id
      def initialize(spcfg, atrb = Hashx.new)
        super()
        @cfg = spcfg.gen(self).update(atrb)
        @id = @cfg[:id]
      end

      # element of par could be formula
      # pary could be destroyed
      def set_par(pary, opt = {})
        # override
        pary = @cfg[:argv] if @cfg[:argv].is_a? Array
        # validate and convert pars
        par = ___validate(type?(pary, Array))
        cid = [@id, *par].join(':')
        opt.update(par: par, cid: cid)
        verbose { "SetPAR(#{@id}): #{par}" }
        ___get_entity(opt, cid)
      end

      # List All parameters
      def valid_pars
        __pars(&:valid_pars)
      end

      def view_par
        __pars do |pary|
          csv = a2csv(pary.valid_pars, ' ')
          mary = [@cfg[:disp].item(@id)]
          mary << "      #{csv}"
        end.join("\n")
      end

      private

      def ___get_entity(opt, cid)
        if @cfg[:nocache]
          ___no_cache(cid, opt)
        elsif key?(cid)
          _get_cache(cid)
        else
          ___save_cache(cid, opt)
        end
      end

      def _get_cache(cid)
        verbose { "SetPAR: Entity Cache found(#{cid})" }
        self[cid]
      end

      def ___no_cache(cid, opt)
        verbose { "SetPAR: Entity No Cache Saved (#{cid})" }
        _gen_entity(opt)
      end

      def ___save_cache(cid, opt)
        verbose { "SetPAR: Entity New Cache Saved (#{cid})" }
        self[cid] = _gen_entity(opt)
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
        __pars { |p| p.validate(pary) }
      rescue ParShortage
        frac = format('Parameter shortage (%d/%d)', psize, __pars.size)
        Msg.par_err(frac, view_par)
      end

      def __pars
        return [] unless @cfg.key?(:parameters)
        pars = type?(@cfg[:parameters], ParArray)
        defined?(yield) ? yield(pars) : pars
      end
    end
  end
end
