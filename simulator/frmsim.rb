#!/usr/bin/ruby
require 'json'
# Device simulator by Log file
class LogRing
  attr_reader :index, :max
  # Structure of @logary
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  def initialize(id)
    @logary = [{}]
    @sndary = []
    @index = 0
    @line = {}
    @dir = 'snd'
    sorted = read_file(id).sort_by { |h| h['time'] }.uniq
    pickid = sorted.select { |h| h['id'] == id }
    pickid.each { |h| mk_dict(h) }
    @max = @logary.size - 1
  end

  def mk_dict(h)
    data = h['base64']
    case h['dir']
    when 'snd'
      @line = { time: h['time'], snd: data }
      @logary << @line
    when 'rcv'
      item_rcv(data)
    else
      pr 'no match'
    end
  end

  def item_snd(data)
    @line['snd'] = data
    if @logary.last.key?('rcv')
      @logary << h
    else
      @logary.last.update h
    end
  end

  def item_rcv(data)
    if @logary.last.key('rcv')
      pr 'rcv duplicated'
    elsif @logary.last['cmd'] == h['cmd']
      h['rcv'] = data
      dur = h.delete('time').to_f * 1000 - @logary.last['time'].to_f * 1000
      h['dur'] = dur.round / 1000.0
      @logary.last.update h
    end
  end

  def read_file(id)
    ary = []
    Dir.glob(ENV['HOME'] + "/.var/stream_#{id}*.log").each do|fname|
      open(fname) do|fd|
        while (line = fd.gets)
          hash = JSON.load(line) || next
          ary << hash
        end
      end
    end
  end

  def find_next(str)
    if @sndary.include?(str)
      next_index(str)
      crnt = @logary[@index]
      pr "#{crnt['cmd']}(#{@index}/#{@max})\n" if /sim/ =~ ENV['VER']
      crnt
    else
      pr "Can't find logline for input of [#{str}]\n"
      nil
    end
  end

  def next_index(str)
    loop do
      @index += 1
      @index = 0 if @index > @max
      break if @logary[@index]['snd'] == str
    end
  end

  def include?(str)
    @sndary.include?(str)
  end

  def to_s
    @logary.map(&:to_s).join("\n")
  end

  private

  def pr(text)
    STDERR.print "\033[1;34m#{text}\33[0m"
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
  sleep crnt['dur'].to_i
  STDOUT.syswrite(crnt['rcv'].unpack('m').first)
end
