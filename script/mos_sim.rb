#!/usr/bin/ruby
require 'libsimap'
require 'libsimarm'
require 'libsimbb'
require 'libsimcar'
require 'libsimfp'

module CIAX::Simulator
  cfg = Conf.new
  mods = [Arm, Ap, BBIO, Carousel, FpDio]
  list = mods.map { |mod| mod.new(cfg) }
  Process.daemon(true, true)
  list.each(&:start)
  sleep
end
