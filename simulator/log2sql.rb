#!/usr/bin/ruby
require 'json'
# Device simulator by Log file
class LogToSql
  # Structure of @logary
  # line includes both command and response data
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  def initialize(id)
    @id = id
    @line = {}
    @files = Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log")
  end

  def create
    names = %w(time dev cmd snd rcv dur).join("','")
    puts "create table stream_#{@id} ('#{names}',primary key(time));"
    self
  end

  def drop
    puts "drop table if exists stream_#{@id};"
    self
  end

  def transaction(n = 0)
    puts 'begin;'
    read_file(n.to_i).each do |line|
      mk_dict(JSON.parse(line))
    end
    insert
    puts 'commit;'
    self
  end

  def insert
    return if @line.empty?
    ks = @line.keys.join("','")
    vs = @line.values.join("','")
    puts "insert or ignore into stream_#{@id} ('#{ks}') values ('#{vs}');"
    self
  end

  private

  def read_file(n = 0)
    ary = []
    Dir.glob(@files).each do |fname|
      ary.concat(IO.readlines(fname))
    end
    n > 0 ? ary[0, n] : ary
  end

  def mk_dict(ch)
    data = ch['base64']
    case ch['dir']
    when 'snd'
      insert
      @line = { time: ch['time'], dev: ch['id'], cmd: ch['cmd'], snd: data }
    when 'rcv'
      item_rcv(data, ch)
    else
      pr 'no match'
    end
  end

  def item_rcv(data, ch)
    if @line.key(:rcv)
      pr 'rcv duplicated'
    elsif @line[:cmd] == ch['cmd']
      @line[:rcv] = data
      dur = (ch.delete('time').to_i - @line[:time].to_i)
      @line[:dur] = dur.to_f / 1000.0
    end
  end

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
    nil
  end
end

abort 'Usage: log2sql [id] (lines)' if ARGV.empty?
id = ARGV.shift
num = ARGV.shift
ARGV.clear

l2s = LogToSql.new(id)
l2s.drop.create.transaction(num)
