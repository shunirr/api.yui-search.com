#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'groonga'

PATH = './db/data.groonga'

if File.exist?(PATH)
  @database = Groonga::Database.open(PATH)
else
  @database = Groonga::Database.create(:path => PATH)
  Groonga::Schema.define do |schema|  
    schema.create_table("Entries", :type => :array) do |table|
      table.text("permalink")
      table.text("title")
      table.text("body")
    end

    schema.create_table("Terms",
                        :type => :patricia_trie,
                        :key_type => "ShortText",
                        :default_tokenizer => "TokenBigram",
                        :key_normalize => true) do |table|
      table.index("Entries.body")
    end
  end
end  

Dir.glob('./html/*.html').each do |html|
  doc = Nokogiri::HTML.parse(open(html).read)
  title = doc.xpath('//h3[@class="title"]').first.text.gsub("\n", '')
  permalink = doc.xpath('//h3[@class="title"]/a').first[:href]
  content = doc.xpath('//div[@class="subContentsInner"]')
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
  Groonga['Entries'].add({
    'permalink' => permalink,
    'title' => title,
    'body' => "#{title} #{children.join}"
  })
  puts "add #{title}"
end

