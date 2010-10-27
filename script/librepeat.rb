#!/usr/bin/ruby
require 'libverbose'
class Repeat < Hash
  def initialize
    @v=Verbose.new("Repeat")
  end

  def repeat(e0)
    a=e0.attributes
    fmt=a['format'] || '%d'
    c=a['counter'] || '_'
    c.next! while self[c]
    @v.msg(1){"Counter[\$#{c}]/Range[#{a['from']}-#{a['to']}]/Format[#{fmt}]"}
    begin
      Range.new(a['from'],a['to']).each { |n|
        self[c]=fmt % n
        e0.each_element { |e1| yield e1}
      }
      self.delete(c)
    ensure
      @v.msg(-1){"End"}
    end
  end

  def subst(str)
    return str unless /\$[_a-z]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      str=str.gsub(/\$([_a-z]+)/){ self[$1] }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end
end
