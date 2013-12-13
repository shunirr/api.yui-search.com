#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'groonga'
require 'digest/md5'

Groonga::Database.open('./db/data.groonga')

Groonga['Entries'].map do |record|
  "curl #{record.image} -o #{Digest::MD5.hexdigest(record.image)}.jpg" if record.image and record.image.include? 'jpg'
end.delete_if do |command|
  command.nil?
end.each do |command|
  puts command
end

