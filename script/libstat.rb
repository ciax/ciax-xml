#!/usr/bin/ruby
require 'libverbose'
class Stat < Hash
  attr_accessor :stat

  def initialize
    @v=Verbose.new
    @stat={}
  end

  def sub_stat(str)
    return str unless /\${/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub ${key1:key2:idx} => hash[key1][key2][idx]
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        [*acc_array($1,@stat)].join(',')
      }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def acc_stat(key)
    acc_array(key,@stat)
  end

  def acc_array(key,h)
    return h unless key
    key.split(':').each {|i|
      @v.msg{"Stat:Type[#{h.class}] Name[#{i}]"}
      i=eval(i) if Array === h
      h=h[i]||raise("No such Value [#{i}]")
    }
    h
  end
end
