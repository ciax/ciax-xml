#!/usr/bin/env ruby
require 'libhashx'
module CIAX
  # Proc Array
  class ProcArray < Arrayx
    def initialize(obj, name = nil)
      @obj = obj
      @layer = @obj.base_class
      @name = name
      super()
    end

    def call
      compact.each { |p| p.call(@obj) }
      self
    end

    def view
      compact.map do |p|
        path, line = p.source_location
        /lib(.+).rb/ =~ path
        "#{Regexp.last_match(1)}:#{line}"
      end
    end

    # Append proc after id (base id of file) proc
    def append(id = nil, &prc)
      if (idx = ___index(id))
        insert(idx + 1, prc)
        verbose { "Insert after '#{id}' in #{@name}#{view.inspect}" }
      else
        push(prc)
        verbose { "Appended in #{@name}#{view.inspect}" }
      end
      self
    end

    # Prepend proc before id
    def prepend(id = nil, &prc)
      if (idx = ___index(id))
        insert(idx, prc)
        verbose { "Insert before '#{id}' in #{@name}#{view.inspect}" }
      else
        unshift(prc)
        verbose { "Unshifted in #{@name}#{view.inspect}" }
      end
      self
    end

    private

    def ___index(id)
      return unless id
      idx = view.index { |s| /#{id}/ =~ s }
      warning("No suci id '#{id}'") unless idx
      idx
    end
  end
end
