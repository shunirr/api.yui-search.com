#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'groonga'
require 'date'

PATH = './db/data.groonga'

if File.exist?(PATH)
  @database = Groonga::Database.open(PATH)
else
  @database = Groonga::Database.create(:path => PATH)
  Groonga::Schema.define do |schema|  
    schema.create_table("Sites",
                        :type => :hash, 
                        :key_type => "ShortText") do |table|
      table.text("title")
    end

    schema.create_table("Entries", :type => :array) do |table|
      table.text("permalink")
      table.text("title")
      table.text("body")
      table.text("image")
      table.time("created_at")
      table.reference("site", "Sites")
    end

    schema.create_table("Terms",
                        :type => :patricia_trie,
                        :key_type => "ShortText",
                        :default_tokenizer => "TokenBigram",
                        :key_normalize => true) do |table|
      table.index("Entries.body")
      table.index("Sites._key")  
    end
  end
end  

def find_site_or_insert(permalink, title)
  site = Groonga['Sites'][permalink]
  if site.nil?
    Groonga['Sites'][permalink] = { 'title' => title }
  end
  Groonga['Sites'][permalink]
end

def add_entry(entry)
  Groonga['Entries'].add entry
end

Dir.glob('./html/*.html').each do |html|
  doc = Nokogiri::HTML.parse(open(html).read)
  site_title = doc.xpath('//title').text.split('｜')[1]
  site_permalink = doc.xpath('//h1/a').first[:href]
  title = doc.xpath('//h3[@class="title"]').first.text.gsub("\n", '')
  permalink = doc.xpath('//h3[@class="title"]/a').first[:href]
  content = doc.xpath('//div[@class="subContentsInner"]')
  d = doc.xpath('//span[@class="date"]').text.split(/[-年月日]/).map {|a| a.to_i }
  date = Date.new(d[0], d[1], d[2])
  image_node = content.xpath('//img[@border]')
  image = nil
  image_node.each do |i|
    if i[:src].include? 'jpg'
      image = i[:src]
      break
    end
  end
  start = false
  children = []
  content.children.each do |child|
    if start then
      if child.to_s.include? 'google_ad_section_end' then
        break
      else
        children << child
      end
    else
      if child.to_s.include? 'google_ad_section_start' then
        start = true
      end
    end
  end
  site = find_site_or_insert(site_permalink, site_title)
  entry = {
    'permalink' => permalink,
    'title' => title,
    'image' => image,
    'body' => "#{title} #{children.join}",
    'site' => site,
    'created_at' => date.to_time.to_i
  }
  add_entry entry
  puts "add #{title}"
end

