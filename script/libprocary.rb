#!/usr/bin/env ruby
require 'libmsg'
module CIAX
  # Proc Dic
  class ProcArray
    include Msg
    def initialize(obj, name = nil)
      super()
      @obj = obj
      @name = __mk_id(@obj, name)
      @list = []
      @dic = {}
    end

    def call
      view.each do |k|
        @dic[k].call(@obj)
        verbose { "Calling #{k} in (#{@name})" }
      end
      self
    end

    def view
      dic = @dic.keys
      return @list.dup if dic.sort == @list.sort
      a = [@list, dic].map(&:inspect).join(' vs. ')
      cfg_err('Keys and Order List are inconsistent ' + a)
    end

    def clear
      @list.clear
      @dic.clear
      self
    end

    # Append proc after id (base id of file) proc
    def append(obj, id, ref = nil, &prc)
      return self unless (id = __chk_id(obj, id))
      @dic[id] = prc
      if (idx = __find_idx(ref))
        @list.insert(idx + 1, id)
        verbose { "Insert '#{id}' after '#{ref}' in #{@name}#{view.inspect}" }
      else
        @list.push(id)
        verbose { "Appended in #{@name}#{view.inspect}" }
      end
      self
    end

    # Prepend proc before id
    def prepend(obj, id, ref = nil, &prc)
      return self unless (id = __chk_id(obj, id))
      @dic[id] = prc
      if (idx = __find_idx(ref))
        @list.insert(idx, id)
        verbose { "Insert '#{id}' before '#{ref}' in #{@name}#{view.inspect}" }
      else
        @list.unshift(id)
        verbose { "Prepended in #{@name}#{view.inspect}" }
      end
      self
    end

    private

    def __mk_id(obj, name)
      ary = obj.class.to_s.downcase.split('::')
      ary.shift
      ary << name.to_s
      ary.join(':')
    end

    def __chk_id(obj, name)
      id = __mk_id(obj, name)
      return id unless @list.include?(id)
      cfg_err("Duplicated id [#{id}]")
    end

    def __find_idx(ref)
      return unless ref
      @list.index { |e| e =~ /#{ref}/ }
    end
  end
end
