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
        par = ___validate(type?(pary, Array).dup, pary.size)
        cid = [@id, *par].join(':')
        opt.update(par: par, cid: cid)
        verbose { "SetPAR(#{@id}): #{par}" }
        ___get_entity(opt, cid)
      end

      def valid_pars
        @cfg[:parameters].to_a.map do |e|
          e[:list] if e[:type] == 'str'
        end.flatten
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
      def ___validate(pary, psize)
        @cfg[:parameters].to_a.map do |pref|
          next ___use_default(pref, psize) unless (str = pary.shift)
          line = pref[:list]
          next method('_val_' + pref[:type]).call(str, line) if line
          pref.key?(:default) ? pref[:default] : str
        end
      end

      def _val_num(str, list)
        num = expr(str)
        verbose { "Validate: [#{num}] Match? [#{a2csv(list)}]" }
        return num.to_s if list.any? { |r| ReRange.new(r) == num }
        Msg.par_err("Out of range (#{num}) for [#{a2csv(list)}]")
      end

      def _val_reg(str, list)
        verbose { "Validate: [#{str}] Match? [#{a2csv(list)}]" }
        return str if list.any? { |r| Regexp.new(r).match(str) }
        Msg.par_err("Parameter Invalid Reg (#{str}) for [#{a2csv(list)}]")
      end

      def _val_str(str, list)
        verbose { "Validate: [#{str}] Match? [#{a2csv(list)}]" }
        return str if list.include?(str)
        Msg.par_err("Parameter Invalid Str (#{str}) for [#{a2csv(list)}]")
      end

      def ___use_default(pref, psize)
        if pref.key?(:default)
          verbose { "Validate: Using default value [#{pref[:default]}]" }
          pref[:default]
        else
          ___err_shortage(pref, psize)
        end
      end

      def ___err_shortage(pref, psize)
        frac = format('(%d/%d)', psize, @cfg[:parameters].size)
        mary = ['Parameter shortage ' + frac]
        mary << @cfg[:disp].item(@id)
        mary << ' ' * 10 + "key=(#{a2csv(pref[:list])})"
        Msg.par_err(*mary)
      end
    end
  end
end
