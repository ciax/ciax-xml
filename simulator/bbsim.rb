#!/usr/bin/ruby
# Field Point I/O Simulator
require 'gserver'

# 16bit data handling
class Word
  def initialize(n = 0)
    @num = n
  end

  def [](pos)
    @num[pos]
  end

  def []=(pos, bin)
    mask(1 << pos, bin << pos)
  end

  def mask(cmask, data = 0) # change bit
    stay = @num & (0xffff ^ cmask)
    @num = stay + data
    self
  end

  def to_x
    format('%04X', @num)
  end

  def to_b
    format('%016b', @num)
  end

  # Big endian
  def to_cb
    [@num].pack('n*')
  end

  # Little endian
  def to_cl
    [@num].pack('v*')
  end

  def to_s
    @num
  end

  def xbcc
    chk = 0
    to_x.each_byte { |c| chk += c }
    format('%02X', chk % 256)
  end
end

# Field Point I/O
class BBIO < GServer
  def initialize(port = 10_003, *args)
    super(port, *args)
    Thread.abort_on_exception = true
    @ioreg = Word.new(0)
  end

  def serve(io)
    while (str = io.readpartial(6))
      sleep 0.1
      res = dispatch(str)
      io.print res if res
    end
  rescue
    warn $ERROR_INFO
  end

  private

  def dispatch(str)
    case str
    # getstat
    when /^!0RD/
      @ioreg.to_cb
    when /^!0SO/
      num=$'.unpack('n*').first
      @ioreg = Word.new(num)
      nil
    end
  end
end

sv = BBIO.new(*ARGV)
sv.start
sleep
