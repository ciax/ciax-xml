#!/usr/bin/env ruby
require 'json'
# Device simulator by Log file
class LogRing
  attr_reader :index, :max
  # Structure of @logary
  # line includes both command and response data
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  def initialize(id)
    @index = 0
    @line = {}
    @exists = []
    @dir = 'snd'
    get_cache(id)
    @max = @logary.size - 1
    @tmplog = @logary.dup
  end

  def mk_dict(crnt)
    data = crnt['base64']
    case crnt['dir']
    when 'snd'
      @line = { time: crnt['time'], snd: data, cmd: crnt['cmd'] }
      @logary << @line
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

  def get_cache(id)
    @cachefile = ENV['HOME'] + "/.var/cache/stream_#{id}.mar"
    @logary = Marshal.load(IO.read(@cachefile))
  rescue Errno::ENOENT # if empty
    mk_logary(id)
  end

  def mk_logary(id)
    @logary = []
    sorted = read_file(id).sort_by { |h| h['time'] }.uniq
    pickid = sorted.select { |h| h['id'] == id }
    pickid.each { |h| mk_dict(h) }
    save_cache
  end

  def save_cache
    open(@cachefile, 'w') do |f|
      f << Marshal.dump(@logary)
    end
  end

  def read_file(id)
    ary = []
    Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log").each do |fname|
      ary.concat(IO.readlines(fname).map { |line| JSON.load(line) if line })
    end
    ary
  end

  def find_next(str)
    while (crnt = @tmplog.shift || rewind(str))
      next if crnt[:snd] != str
      @exists << str
      pr "#{crnt[:cmd]}(#{@tmplog.size}/#{@max})\n" if /sim/ =~ ENV['VER']
      return crnt
    end
  end

  def rewind(str)
    @tmplog = @logary.dup
    if @exists.include?(str)
      @tmplog.shift
    else
      pr "can't find [#{str}]"
      nil
    end
  end

  def to_s
    @tmplog.map(&:to_s).join("\n")
  end

  private

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
    nil
  end
end

def input
  select([STDIN])
  [STDIN.sysread(1024).chomp].pack('m').split("\n").join('')
end

abort 'Usage: frmsim [id]' if ARGV.empty?
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
