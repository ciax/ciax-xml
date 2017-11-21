#!/usr/bin/ruby
require 'json'
# Device simulator SQL generator from Stream Log file
# Internal functions
class LogToSql
  private

  def read_file(n = 0)
    @files.each do |fname|
      pn fname
      ln = IO.readlines(fname)
      pr "(#{ln.size})"
      yield n > 0 ? ln[0, n] : ln
    end
  end

  # ch => current hash
  def mk_dict(line, rec)
    ch = inspection(line)
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

  # Convert from old format to latest
  def inspection(line)
    ch = {}
    if line =~ /(^[0-9\.]+).*(\{.*\})/
      ch['time'] = Regexp.last_match(1).delete('.')
      line = Regexp.last_match(2)
    end
    modify(ch.update(JSON.parse(line)))
  end

  def modify(ch)
    time = ch['time']
    ch['time'] = time.delete('.').to_i if time.is_a? String
    chg_key(ch, 'data', 'base64')
    chg_key(ch, 'cid', 'cmd')
    ch
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

  def chg_key(ch, key1, key2)
    ch[key2] = ch.delete(key1) if ch.key?(key1)
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

  def pn(text)
    STDERR.print "\033[1;34m#{text}\33[0m"
    nil
  end

  def pr(text)
    STDERR.puts "\033[1;34m#{text}\33[0m"
    nil
  end
end

# Public functions
class LogToSql
  # record includes both command and response data
  # [ { :time => time, :id => id, :ver => ver,
  #     :snd => base64, :rcv => base64, :dur => msec } ]
  def initialize(id)
    id = '' if id == '-a'
    id = "{#{id}}" if id.include?(',')
    @files = Dir.glob(ENV['HOME'] + "/.var/log/stream_#{id}*.log").sort
    # field name vs data type table (:i=Integer, :s=String, :f=Float)
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
    read_file(n.to_i) do |ln|
      puts 'begin;'
      insert(ln.each_with_object({}) do |line, rec|
        mk_dict(line, rec)
      end)
      puts 'commit;'
    end
    self
  end

  def insert(rec)
    return if rec.empty?
    ks, vs = enclose(rec)
    puts "insert or ignore into stream (#{ks}) values (#{vs});"
    self
  end
end

abort 'Usage: log2sql (-a,c) [id,..] (lines)' if ARGV.empty?
id = ARGV.shift
if id == '-c'
  clr=true
  id = ARGV.shift
end
num = ARGV.shift
ARGV.clear

l2s = LogToSql.new(id)
l2s.drop.create if clr
l2s.transaction(num)
