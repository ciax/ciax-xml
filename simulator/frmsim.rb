#!/usr/bin/ruby
require 'json'
# Device simulator by Log file
class LogRing
  attr_reader :index, :max
  # Structure of @logary
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  LOG = []
  def initialize(id)
    @index = 0
    @line = {}
    @exists = []
    @dir = 'snd'
    sorted = read_file(id).sort_by { |h| h['time'] }.uniq
    pickid = sorted.select { |h| h['id'] == id }
    pickid.each { |h| mk_dict(h) }
    @max = LOG.size - 1
    @logary = LOG.dup
  end

  def mk_dict(crnt)
    data = crnt['base64']
    case crnt['dir']
    when 'snd'
      @line = { time: crnt['time'], snd: data, cmd: crnt['cmd'] }
      LOG << @line
    when 'rcv'
      item_rcv(data, crnt)
    else
      pr 'no match'
    end
  end

  def item_rcv(data, crnt)
    if @line.key(:rcv)
      pr 'rcv duplicated'
    elsif @line[:cmd] == crnt['cmd']
      @line[:rcv] = data
      dur = (crnt.delete('time').to_i - @line[:time].to_i)
      @line[:dur] = dur.to_f / 1000.0
    end
  end

  def read_file(id)
    ary = []
    Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log").each do|fname|
      ary.concat(IO.readlines(fname).map { |line| JSON.load(line) if line })
    end
    ary
  end

  def find_next(str)
    while (crnt = @logary.shift || rewind(str))
      next if crnt[:snd] != str
      @exists << str
      pr "#{crnt[:cmd]}(#{@logary.size}/#{@max})\n" if /sim/ =~ ENV['VER']
      return crnt
    end
  end

  def rewind(str)
    @logary = LOG.dup
    if @exists.include?(str)
      @logary.shift
    else
      pr "can't find [#{str}]"
      nil
    end
  end

  def to_s
    @logary.map(&:to_s).join("\n")
  end

  private

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
  end
end

def input
  select([STDIN])
  [STDIN.sysread(1024).chomp].pack('m').split("\n").join('')
end

abort 'Usage: frmsim [id]' if ARGV.size < 1
id = ARGV.shift
ARGV.clear

logv = LogRing.new(id)
while (inp = input)
  crnt = logv.find_next(inp) || next
  data = crnt[:rcv] || next
  sleep crnt[:dur].to_i
  res = data.unpack('m').first
  STDOUT.syswrite(res)
end
