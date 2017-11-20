#!/usr/bin/ruby
require 'json'
# Device simulator by Log file
class LogToSql
  # Structure of @logary
  # line includes both command and response data
  # [ { :time => time, :snd => base64, :rcv => base64, :diff => msec } ]
  def initialize(id)
    id = '' if id == '-a'
    id = "{#{id}}" if id.include?(',')
    @files = Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log")
    @field = { time: :i, id: :s, ver: :i, cmd: :s, snd: :s, rcv: :s, dur: :f }
  end

  def create
    names = @field.keys.join(',')
    puts "create table stream (#{names},primary key(time));"
    self
  end

  def drop
    puts 'drop table if exists stream;'
    self
  end

  # pick up n lines each
  def transaction(n = 0)
    puts 'begin;'
    drop.create.records(n)
    puts 'commit;'
    self
  end

  def records(n = 0)
    insert(
      read_file(n.to_i).each_with_object({}) do |line, rec|
        mk_dict(JSON.parse(line), rec)
      end
    )
  end

  def insert(rec)
    return if rec.empty?
    ks, vs = enclose(rec)
    puts "insert or ignore into stream (#{ks}) values (#{vs});"
    self
  end

  private

  def read_file(n = 0)
    @files.each_with_object([]) do |fname, ary|
      ln = IO.readlines(fname)
      ary.concat(n > 0 ? ln[0, n] : ln)
    end
  end

  # ch => current hash
  def mk_dict(ch, rec)
    case ch['dir']
    when 'snd'
      insert(rec)
      item_snd(ch, rec)
    when 'rcv'
      item_rcv(ch, rec)
    else
      pr 'no match'
    end
  end

  def item_snd(ch, rec)
    pick(%i(time id ver cmd), ch, rec)
    rec[:snd] = ch['base64']
    self
  end

  def item_rcv(ch, rec)
    if rec.key(:rcv)
      pr 'rcv duplicated'
    elsif corresponding?(%i(id ver cmd), ch, rec)
      rec[:rcv] = ch['base64']
      rec[:dur] = mk_dur(ch, rec)
    end
    self
  end

  def pick(ks, ch, rec = {})
    ks.each_with_object(rec) { |k, h| h[k] = ch[k.to_s] }
  end

  def corresponding?(ks, ch, rec)
    ks.all? { |k| rec[k] == ch[k.to_s] }
  end

  def mk_dur(ch, rec)
    (ch.delete('time').to_i - rec[:time].to_i).to_f / 1000.0
  end

  def enclose(rec)
    ks = []
    vs = []
    @field.each do |key, type|
      next unless rec.key?(key)
      ks << key
      vs << conv(rec[key], type)
    end
    [ks.join(','), vs.join(',')]
  end

  def conv(str, type)
    case type
    when :s
      "'#{str}'"
    when :i
      str.to_i
    when :f
      str.to_f
    end
  end

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
    nil
  end
end

abort 'Usage: log2sql (-a) [id,..] (lines)' if ARGV.empty?
id = ARGV.shift
num = ARGV.shift
ARGV.clear

l2s = LogToSql.new(id)
l2s.transaction(num)
