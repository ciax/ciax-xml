#!/usr/bin/env ruby
module CIAX
  # Proc Array
  class ProcArray < Array
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
      if name
        idx = view.index { |s| /#{name}/ =~ s }
        insert(idx + 1, prc)
      else
        push(prc)
      end
      self
    end
  end
end
