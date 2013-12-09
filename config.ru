#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

$:.unshift './lib', './'
require 'bundler'
Bundler.require
require 'yui-search'

static = 'public'
use Rack::Static,
  :root => static,
  :index => 'index.html',
  :urls => Dir.glob("#{static}/*").map {|f| f.gsub(/^#{static}/, '') }

run YuiSearch::Application
