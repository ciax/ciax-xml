#!/usr/bin/env ruby
require 'libmsg'

module CIAX
  module Xml
    # XML Repeated Data Handling Class
    class Repeat
      include Msg
      def initialize
        @counter = {}
        @format = {}
      end

      def each(e0)
        return unless e0
        e0.each do |e1|
          if /repeat.*/ =~ e1.name
            ___repeat(e1) do
              each(e1) { |e2| yield e2 }
            end
          else
            yield e1
          end
        end
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

      def ___repeat(e0)
        c = e0['counter'] || '_'
        Msg.give_up('Repeat:Counter Duplicate') if @counter.key?(c)
        fmt = @format[c] = e0['format'] || '%d'
        caption = "Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]"
        enclose(caption, 'End') { ___sub_repeat(e0, c) { yield } }
        self
      end

      def ___sub_repeat(e0, c)
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
end
