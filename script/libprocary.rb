#!/usr/bin/env ruby
require 'libmsg'
module CIAX
  # Proc Dic
  class ProcArray
    include Msg
    def initialize(obj, name = nil)
      super()
      @obj = obj
      @layer = @obj.base_class
      @name = name
      @list = []
      @dic = {}
    end

    def call
      view.each { |k| @dic[k].call(@obj) }
      self
    end

    def view
      return @list.dup if @list.sort == @dic.keys.sort
      cfg_err('Keys and Order List are inconsistent')
    end

    def clear
      @list.clear
      @dic.clear
      self
    end

    # Append proc after id (base id of file) proc
    def append(id, ref = nil, &prc)
      @dic[id] = prc
      if ref && (idx = @list.index(ref))
        @list.insert(idx + 1, id)
        verbose { "Insert after '#{ref}' in #{@name}#{view.inspect}" }
      else
        @list.push(id)
        verbose { "Appended in #{@name}#{view.inspect}" }
      end
      self
    end

    # Prepend proc before id
    def prepend(id, ref = nil, &prc)
      @dic[id] = prc
      if ref && (idx = @list.index(ref))
        @list.insert(idx, id)
        verbose { "Insert before '#{ref}' in #{@name}#{view.inspect}" }
      else
        @list.unshift(id)
        verbose { "Unshifted in #{@name}#{view.inspect}" }
      end
      self
    end
  end
end
