#!/usr/bin/ruby
require 'libconf'
require 'librerange'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
  # Command Module
  module Cmd
    # Default Proc Setting method
    module CmdProc
      include Msg
      attr_reader :cfg
      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc] = type?(def_proc, Proc)
        self
      end
    end

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

      def set_par(par, opt = {})
        par = @cfg[:argv] if @cfg[:argv].is_a? Array
        par = validate(type?(par, Array))
        cid = [@id, *par].join(':')
        opt.update(par: par, cid: cid)
        verbose { "SetPAR(#{@id}): #{par}" }
        _get_entity(opt, cid)
      end

      def valid_pars
        (@cfg[:parameters] || []).map do |e|
          e[:list] if e[:type] == 'str'
        end.flatten
      end

      private

      def _get_entity(opt, cid)
        return _get_cache(cid) if key?(cid)
        ent = gen_entity(opt)
        return _no_cache(cid, ent) if @cfg[:nocache]
        verbose { "SetPAR: Entity Cache Saved (#{cid})" }
        self[cid] = ent
      end

      def _get_cache(cid)
        verbose { "SetPAR: Entity Cache found(#{cid})" }
        self[cid]
      end

      def _no_cache(cid, ent)
        verbose { "SetPAR: Entity No Cache Saved (#{cid})" }
        ent
      end

      def gen_entity(opt)
        context_constant('Entity').new(@cfg, opt)
      end

      # Parameter for validate(cfg[:parameters])
      #   structure:  [{:type,:list,:default}, ...]
      # *Empty parameter will replaced to :default
      # *Error if str doesn't match with strings listed in :list
      # *If no :list, returns :default
      # Returns converted parameter array
      def validate(pary)
        pary = type?(pary.dup, Array)
        pref = @cfg[:parameters]
        return [] unless pref
        _par_array(pary, pref)
      end

      def _par_array(pary, pref)
        pref.map do |par|
          list = par[:list] || []
          disp = list.join(',')
          str = pary.shift
          if str
            _validate_element(par, str, list, disp)
          else
            _use_default(par, pary, pref, disp)
          end
        end
      end

      def _validate_element(par, str, list, disp)
        if list.empty?
          par.key?(:default) ? par[:default] : str
        else
          _validate_by_type(par, str, list, disp)
        end
      end

      def _validate_by_type(par, str, list, disp)
        case par[:type]
        when 'num'
          _validate_num(str, list, disp)
        when 'reg'
          _validate_reg(str, list, disp)
        else
          _validate_str(str, list, disp)
        end
      end

      def _use_default(par, pary, pref, disp)
        if par.key?(:default)
          verbose { "Validate: Using default value [#{par[:default]}]" }
          return par[:default]
        else
          _err_shortage(pary, pref, disp)
        end
      end

      def _err_shortage(pary, pref, disp)
        mary = []
        mary << format('Parameter shortage (%d/%d)', pary.size, pref.size)
        mary << @cfg[:disp].item(@id)
        mary << ' ' * 10 + "key=(#{disp})"
        Msg.par_err(*mary)
      end

      def _validate_num(str, list, disp)
        num = expr(str)
        verbose { "Validate: [#{num}] Match? [#{disp}]" }
        return num.to_s if list.any? { |r| ReRange.new(r) == num }
        Msg.par_err("Out of range (#{num}) for [#{disp}]")
      end

      def _validate_reg(str, list, disp)
        verbose { "Validate: [#{str}] Match? [#{disp}]" }
        return str if list.any? { |r| Regexp.new(r).match(str) }
        Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
      end

      def _validate_str(str, list, disp)
        verbose { "Validate: [#{str}] Match? [#{disp}]" }
        return str if list.include?(str)
        Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
      end
    end

    # Command db with parameter derived from Item
    class Entity < Config
      attr_reader :id, :par
      attr_accessor :msg
      # set should have :def_proc
      def initialize(cfg, atrb = Hashx.new)
        super(cfg).update(atrb)
        @par = self[:par]
        @id = self[:cid]
        verbose { "Config\n" + path }
      end

      # returns result of def_proc block (String)
      def exe_cmd(src, pri = 1)
        verbose { "Execute [#{@id}] from #{src}" }
        _input_log(src, pri)
        @msg = self[:def_msg] || ''
        self[:def_proc].call(self, src, pri)
        self
      end

      private

      # For input logging (returns String)
      def _input_log(src, pri)
        input = self[:input]
        return unless input && !@id.empty?
        verbose { "Input [#{@id}] from #{src}" }
        input.update(cid: self[:cid], src: src)
        input[:pri] = pri if pri
        input.cmt
      end
    end
  end
end
