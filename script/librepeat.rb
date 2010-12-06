#!/usr/bin/ruby
require 'libverbose'
class Repeat < Array
  def initialize
    @v=Verbose.new("Repeat")
    @counter={}
  end

  def repeat(e0)
    clear
    fmt=e0['format'] || '%d'
    c=e0['counter'] || '_'
    c.next! while @counter[c]
    @v.msg(1){"Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]"}
    begin
      Range.new(e0['from'],e0['to']).each { |n|
        @v.msg(1){"Turn Number[#{n}]"}
        @counter[c]=fmt % n
        begin
          push yield
        ensure
          @v.msg(-1){"Turn End"}
        end
      }
      @counter.delete(c)
      self
    ensure
      @v.msg(-1){"End"}
    end
  end

  def subst(str)
    return str unless /\$[_a-z]/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => @counter[key]
      str=str.gsub(/\$([_a-z])/){ @counter[$1] }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end
end
