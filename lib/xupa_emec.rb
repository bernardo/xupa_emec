require "rubygems"
require 'nokogiri'
require "mechanize"
require 'active_support'
require 'trollop'
require 'fastercsv'
require 'xupa_emec/version'
require 'xupa_emec/crawler'


#monkey patches string for mb_chars
class String
  def mb_chars
    ActiveSupport::Multibyte::Chars.new(self)
  end
end





