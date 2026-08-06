# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'mail'
require_relative './spec_helper'
require_relative '../lib/helpers'

describe Mail2www::Helpers do
  include Mail2www::Helpers

  describe 'get_body' do
    it 'returns the body of a single-part HTML message' do
      message = Mail.new do
        content_type 'text/html; charset=UTF-8'
        body '<p>HTML body</p>'
      end

      expect(get_body(message)).to eq(text: nil, html: '<p>HTML body</p>')
    end

    it 'separates a message with both plain text and HTML parts' do
      message = Mail.new do
        text_part { body 'Plain body' }
        html_part { content_type 'text/html; charset=UTF-8'; body '<p>HTML body</p>' }
      end

      expect(get_body(message)).to eq(text: 'Plain body', html: '<p>HTML body</p>')
    end
  end

  describe "append_slash" do
    let (:url) { "http://example.com/example" }
    let (:url_end_with_slash) { "http://example.com/example/" }
    let (:with_query) { "http://example.com/example?foo=bar" }
    let (:with_query2) { "http://example.com/example/?foo=bar" }

    context "when an url is not end with a slash" do
      it "should return the url with a slash" do
        expect(append_slash(url)).to eq(url_end_with_slash)
        expect(append_slash(with_query)).to eq(with_query2)
      end
    end

    context "when an url is end with a slash" do
      it "should return the url as is" do
        expect(append_slash(url_end_with_slash)).to eq(url_end_with_slash)
        expect(append_slash(with_query2)).to eq(with_query2)
      end
    end
  end

  describe "surround_urls_with_a_tag" do
    context "when a text has URLs" do
      let (:text) { 'link1: http://example.com/ , link2: http://example.jp/ <>' }
      let (:urls) { ['http://example.com/', 'http://example.jp/'] }
      let (:expected) {
        'link1: <a href="http://example.com/" rel=noreferrer>http://example.com/</a> , ' +
          'link2: <a href="http://example.jp/" rel=noreferrer>http://example.jp/</a> &lt;&gt;'
      }
      it "should surround all URLs in the text with a-tag and escape the text" do
        expect(surround_urls_with_a_tag(text, urls)).to eq(expected)
      end
    end

    context "when a text has no URL" do
      let (:text) { 'There is no link <>' }
      let (:urls) { [] }
      let (:expected) { 'There is no link &lt;&gt;' }
      it "should return the escaped text" do
        expect(surround_urls_with_a_tag(text, urls)).to eq(expected)
      end
    end
  end
end
