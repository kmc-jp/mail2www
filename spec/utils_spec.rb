# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'mail'
require_relative './spec_helper'
require_relative '../lib/utils'

describe Mail2www::Utils do
  include Mail2www::Utils

  describe "how_old" do
    let (:now) { Time.local(2014, 4, 1, 10, 10, 10) }
    let (:minute) { 60 }
    let (:hour) { 60 * minute }
    let (:day) { 24 * hour }
    before { Time.stub(:now).and_return(now) }

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

  describe "in_to_or_cc?" do
    context "when mail doesn't have either To or Cc" do
      it "should return nil" do
        mail = Mail.new
        expect(in_to_or_cc?(mail, /me/)).to eq(nil)
      end
    end

    context "when mail have only To" do
      let (:mail) { Mail.new { to "me@example.jp" } }
      context "when regexp matches To" do
        it "should return 0" do
          expect(in_to_or_cc?(mail, /me/)).to eq(0)
        end
      end

      context "when regexp doesn't match To" do
        it "should return nil" do
          expect(in_to_or_cc?(mail, /you/)).to eq(nil)
        end
      end
    end

    context "when mail have only Cc" do
      let (:mail) { Mail.new { cc "me@example.jp" } }
      context "when regexp matches Cc" do
        it "should return 0" do
          expect(in_to_or_cc?(mail, /me/)).to eq(0)
        end
      end

      context "when regexp doesn't match Cc" do
        it "should return nil" do
          expect(in_to_or_cc?(mail, /you/)).to eq(nil)
        end
      end
    end

    context "when mail have To and Cc" do
      let (:mail) { Mail.new do
          to "me@example.jp"
          cc "cc@example.jp"
        end }

      context "when regexp matches To or Cc" do
        it "should return 0" do
          expect(in_to_or_cc?(mail, /cc/)).to eq(0)
          expect(in_to_or_cc?(mail, /me/)).to eq(0)
        end
      end

      context "when regexp doesn't match To and Cc" do
        it "should return nil" do
          expect(in_to_or_cc?(mail, /you/)).to eq(nil)
        end
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
end
