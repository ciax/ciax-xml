#!/usr/bin/env ruby
require 'libhashx'
module CIAX
  # Proc Array
  class ProcArray < Arrayx
    def initialize(obj)
      @obj = obj
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

    # Append proc after name (base name of file) proc
    def append(name = nil, &prc)
      if (idx = ___index(name))
        insert(idx + 1, prc)
        verbose { "Appended after '#{name}' -> #{view.inspect}" }
      else
        push(prc)
        verbose { "Appended -> #{view.inspect}" }
      end
      self
    end

    private

    def ___index(name)
      return unless name
      idx = view.index { |s| /#{name}/ =~ s }
      warning("No suci id '#{name}'") unless idx
      idx
    end
  end
end
