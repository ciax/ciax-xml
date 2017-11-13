#!/usr/bin/ruby
require 'json'
# Device simulator by Log file
class LogToSql
  # Structure of @logary
  # line includes both command and response data
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  def initialize(id)
    @line = {}
    id = "{#{id}}" if id.include?(',')
    @files = Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log")
  end

  def create
    names = %w(time id ver cmd snd rcv dur).join("','")
    puts "create table stream ('#{names}',primary key(time));"
    self
  end

  def drop
    puts 'drop table if exists stream;'
    self
  end

  # pick up n lines each
  def transaction(n = 0)
    puts 'begin;'
    drop.create
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
    puts "insert or ignore into stream ('#{ks}') values ('#{vs}');"
    self
  end

  private

  def read_file(n = 0)
    @files.each_with_object([]) do |fname, ary|
      ln = IO.readlines(fname)
      ary.concat(n > 0 ? ln[0, n] : ln)
    end
  end

  def mk_dict(ch)
    data = ch['base64']
    case ch['dir']
    when 'snd'
      insert
      item_snd(data, ch)
    when 'rcv'
      item_rcv(data, ch)
    else
      pr 'no match'
    end
  end

  def item_snd(data, ch)
    @line = pick(%i(time id ver cmd), ch)
    @line[:snd] = data
    self
  end

  def item_rcv(data, ch)
    if @line.key(:rcv)
      pr 'rcv duplicated'
    elsif corresponding?(%i(id ver cmd), ch)
      @line[:rcv] = data
      dur = (ch.delete('time').to_i - @line[:time].to_i)
      @line[:dur] = dur.to_f / 1000.0
    end
    self
  end

  def pick(ks, ch)
    ks.each_with_object({}) { |k, h| h[k] = ch[k.to_s] }
  end

  def corresponding?(ks, ch)
    ks.all? { |k| @line[k] == ch[k.to_s] }
  end

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
    nil
  end
end

abort 'Usage: log2sql [id,..] (lines)' if ARGV.empty?
id = ARGV.shift
num = ARGV.shift
ARGV.clear

l2s = LogToSql.new(id)
l2s.transaction(num)
