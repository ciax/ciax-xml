#!/usr/bin/ruby
require 'libconf'
require 'librerange'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
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
    NS_COLOR = 3
    include CmdProc
    # grp_cfg should have :id,'label',:parameters,:def_proc
    def initialize(cfg, attr = {})
      super()
      @cls_color = 6
      @cfg = cfg.gen(self).update(attr)
    end

    def set_par(par, opt = {})
      cid = @cfg[:id]
      par = @cfg[:argv] if @cfg[:argv].is_a? Array
      par = validate(type?(par, Array))
      cid = [cid, *par].join(':')
      opt.update(par: par, cid: cid)
      verbose { "SetPAR(#{@cfg[:id]}): #{par}" }
      if key?(cid)
        verbose { "SetPAR: Entity Cache found(#{cid})" }
        self[cid]
      else
        ent = context_constant('Entity').new(@cfg, opt)
        if @cfg[:nocache]
          verbose { "SetPAR: Entity No Cache Saved (#{cid})" }
        else
          self[cid] = ent
          verbose { "SetPAR: Entity Cache Saved (#{cid})" }
        end
        ent
      end
    end

    def valid_pars
      (@cfg[:parameters] || []).map do |e|
        e[:list] if e[:type] == 'str'
      end.flatten
    end

    private

    # Parameter for validate(cfg[:paremeters])
    #   structure:  [{:type,:list,:default}, ...]
    # *Empty parameter will replaced to :default
    # *Error if str doesn't match with strings listed in :list
    # *If no :list, returns :default
    # Returns converted parameter array
    def validate(pary)
      pary = type?(pary.dup, Array)
      return [] unless @cfg[:parameters]
      @cfg[:parameters].map do|par|
        list = par[:list] || []
        disp = list.join(',')
        str = pary.shift
        unless str
          if par.key?(:default)
            verbose { "Validate: Using default value [#{par[:default]}]" }
            next par[:default]
          end
          mary = []
          mary << "Parameter shortage (#{pary.size}/#{@cfg[:parameters].size})"
          mary << @cfg[:disp].item(@cfg[:id])
          mary << ' ' * 10 + "key=(#{disp})"
          Msg.par_err(*mary)
        end
        if list.empty?
          next par[:default] if par.key?(:default)
        else
          case par[:type]
          when 'num'
            begin
              num = expr(str)
            rescue NameError, SyntaxError
              Msg.par_err('Parameter is not number')
            end
            verbose { "Validate: [#{num}] Match? [#{disp}]" }
            unless list.any? { |r| ReRange.new(r) == num }
              Msg.par_err("Out of range (#{num}) for [#{disp}]")
            end
            next num.to_s
          when 'reg'
            verbose { "Validate: [#{str}] Match? [#{disp}]" }
            unless list.any? { |r| Regexp.new(r).match(str) }
              Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
            end
          else
            verbose { "Validate: [#{str}] Match? [#{disp}]" }
            unless list.include?(str)
              Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
            end
          end
        end
        str
      end
    end
  end

  # Command db with parameter derived from Item
  class Entity < Config
    NS_COLOR = 9
    attr_reader :id, :par
    # set should have :def_proc
    def initialize(cfg, attr = {})
      super(cfg).update(attr)
      @cls_color = 14
      @par = self[:par]
      @id = self[:cid]
      verbose { "Config\n" + path }
    end

    # returns result of def_proc block (String)
    def exe_cmd(src, pri = 1)
      verbose { "Execute [#{@id}] from #{src}" }
      self[:def_proc].call(self, src, pri)
    end
  end
end
