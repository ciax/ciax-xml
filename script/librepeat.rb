#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class Repeat
    NS_COLOR = 1
    include Msg
    def initialize
      @cls_color = 5
      @counter = {}
      @format = {}
      @rep = []
    end

    def each(e0)
      e0.each do|e1|
        case e1.name
        when /repeat.*/
          repeat(e1) do
            each(e1) do|e2|
              yield e2, self
            end
          end
        else
          yield e1, self
        end
      end if e0
    end

    def subst(str) # Sub $key => @counter[key]
      return str unless /\$([_a-z])/ === str
      res = str.gsub(/\$([_a-z])/) { @counter[$1] }
      res = res.split(':').map { |i| /\$/ =~ i ? i : eval(i) }.join(':')
      Msg.cfg_err('Empty String') if res == ''
      verbose { "Substitute [#{str}] to [#{res}]" }
      res
    end

    def format(str)
      return str unless /\$([_a-z])/ === str
      res = str.gsub(/\$([_a-z])/) { @format[$1] % @counter[$1] }
      verbose { "Format [#{str}] to [#{res}]" }
      res
    end

    private
    def repeat(e0)
      @rep.clear
      c = e0['counter'] || '_'
      Msg.abort('Repeat:Counter Duplicate') if @counter.key?(c)
      fmt = @format[c] = e0['format'] || '%d'
      enclose("Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]", 'End') do
        Range.new(subst(e0['from']), subst(e0['to'])).each do |n|
          enclose("Turn Number[#{n}] Start", "Turn Number[#{n}] End") do
            @counter[c] = n
            @rep.push yield
          end
        end
        @counter.delete(c)
      end
      self
    end
  end
end
