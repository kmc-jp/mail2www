# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'mail'
require_relative './spec_helper'
require_relative '../lib/helpers'

describe Mail2www::Helpers do
  include Mail2www::Helpers

  describe "how_old" do
    let (:now) { Time.local(2014, 4, 1, 10, 10, 10) }
    let (:minute) { 60 }
    let (:hour) { 60 * minute }
    let (:day) { 24 * hour }
    before { allow(Time).to receive(:now).and_return(now) }

    context "when diff is less than 60 seconds" do
      it "should return diff in seconds" do
        expect(how_old(now - 10)).to eq("10s")
        expect(how_old(now - minute)).not_to eq("60s")
      end
    end

    context "when diff is less than an hour" do
      it "should return diff in minutes" do
        expect(how_old(now - minute)).to eq("1m")
        expect(how_old(now - 60 * minute)).not_to eq("60m")
      end
    end

    context "when diff is less than a day" do
      it "should return diff in hours" do
        expect(how_old(now - hour)).to eq("1h")
        expect(how_old(now - 24 * hour)).not_to eq("24h")
      end
    end

    context "when diff is equal or less than 30 days" do
      it "should return diff in days" do
        expect(how_old(now - day)).to eq("1d")
        expect(how_old(now - 30 * day - 1)).not_to eq("30d")
      end
    end

    context "when diff is more than 30 days" do
      it "should return diff in months" do
        expect(how_old(now - 30 * day - 1)).to eq("1M")
      end
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
        'link1: <a href="http://example.com/">http://example.com/</a> , ' +
          'link2: <a href="http://example.jp/">http://example.jp/</a> &lt;&gt;'
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
