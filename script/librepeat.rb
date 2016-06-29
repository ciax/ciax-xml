#!/usr/bin/ruby
require 'libmsg'

module CIAX
  # XML Repeated Data Handling Class
  class Repeat
    include Msg
    def initialize
      @counter = {}
      @format = {}
    end

    def each(e0)
      e0.each do |e1|
        if /repeat.*/ =~ e1.name
          repeat(e1) do
            each(e1) { |e2| yield e2 }
          end
        else
          yield e1
        end
      end if e0
    end

    def subst(str) # Sub $key => @counter[key]
      return str unless Regexp.new('\$([_a-z])').match(str)
      res = str.gsub(/\$([_a-z])/) { @counter[Regexp.last_match(1)] }
      res = res.split(':').map do |i|
        # i could be expression
        Regexp.new('\$').match(i) ? i : expr(i)
      end.join(':')
      Msg.cfg_err('Empty String') if res == ''
      verbose { "Substitute [#{str}] to [#{res}]" }
      res
    end

    def formatting(str)
      return str unless Regexp.new('\$([_a-z])').match(str)
      res = str.gsub(/\$([_a-z])/) do
        @format[Regexp.last_match(1)] % @counter[Regexp.last_match(1)]
      end
      verbose { "Formatting [#{str}] to [#{res}]" }
      res
    end

    private

    def repeat(e0)
      c = e0['counter'] || '_'
      Msg.give_up('Repeat:Counter Duplicate') if @counter.key?(c)
      fmt = @format[c] = e0['format'] || '%d'
      caption = "Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]"
      enclose(caption, 'End') { sub_repeat(e0, c) { yield } }
      self
    end

    def sub_repeat(e0, c)
      Range.new(subst(e0['from']), subst(e0['to'])).each do |n|
        enclose("Turn Number[#{n}] Start", "Turn Number[#{n}] End") do
          @counter[c] = n
          yield
        end
      end
      @counter.delete(c)
    end
  end
end
