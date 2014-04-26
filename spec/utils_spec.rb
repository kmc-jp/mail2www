# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'mail'
require_relative './spec_helper'
require_relative '../script/utils'

describe Mail2www::Utils do
  include Mail2www::Utils

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
end
