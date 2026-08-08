# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'mail'
require_relative './spec_helper'
require_relative '../lib/helpers'

describe Mail2www::Helpers do
  include Mail2www::Helpers

  def suspicious_mailbox_name?(name, address)
    mailbox_suspicion(name, address).first
  end

  def suspicious_mailbox_address?(address)
    mailbox_suspicion(nil, address).last
  end

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

  describe 'get_addresses' do
    it 'returns display names and addresses for each mailbox' do
      message = Mail.new
      message.to = ['John Doe <john@example.com>', 'jane@example.com']

      expect(get_addresses(message, :to)).to eq(
        [
          { name: 'John Doe', address: 'john@example.com', suspicious_name: false, suspicious_address: false },
          { name: nil, address: 'jane@example.com', suspicious_name: false, suspicious_address: false }
        ]
      )
      expect(get_addresses(message, :cc)).to eq([])
    end

    it 'marks mailbox names containing address syntax as suspicious' do
      expect(suspicious_mailbox_name?('Admin <admin@example.com>', 'user@example.com')).to be(true)
      expect(suspicious_mailbox_name?('admin@example.com', 'user@example.com')).to be(true)
    end

    it 'allows an ASCII domain that matches the address domain' do
      expect(suspicious_mailbox_name?('Example.com', 'user@example.com')).to be(false)
      expect(suspicious_mailbox_name?('accounts.example.com', 'user@example.com')).to be(false)
      expect(suspicious_mailbox_name?('example.com', 'user@accounts.example.com')).to be(false)
    end

    it 'compares registrable domains using the Public Suffix List' do
      expect(suspicious_mailbox_name?('example.co.jp', 'user@accounts.example.co.jp')).to be(false)
      expect(suspicious_mailbox_name?('accounts.example.co.jp', 'user@example.co.jp')).to be(false)
      expect(suspicious_mailbox_name?('example.jp', 'user@example.co.jp')).to be(true)
      expect(suspicious_mailbox_name?('example1.co.jp', 'user@example.co.jp')).to be(true)
    end

    it 'decodes a Punycode address domain before matching' do
      expect(suspicious_mailbox_name?('bücher.example', 'user@xn--bcher-kva.example')).to be(false)
      expect(suspicious_mailbox_name?('bucher.example', 'user@xn--bcher-kva.example')).to be(true)
    end

    it 'returns a decoded address when its IDN domain is not suspicious' do
      expect(resolve_mailbox_address('user@xn--bcher-kva.example', false)).to eq('user@bücher.example')
    end

    it 'returns a Punycode address when its IDN domain is suspicious' do
      mixed_domain = "p\u0430ypal.com"

      expect(resolve_mailbox_address("user@#{mixed_domain}", true))
        .to eq("user@#{SimpleIDN.to_ascii(mixed_domain)}")
    end

    it 'leaves a broken IDN address unchanged' do
      allow(SimpleIDN).to receive(:to_unicode).and_raise(SimpleIDN::ConversionError)

      expect(resolve_mailbox_address('user@xn--invalid.example', true)).to eq('user@xn--invalid.example')
    end

    it 'checks the name independently when the address contains invalid Punycode' do
      allow(SimpleIDN).to receive(:to_unicode).and_raise(SimpleIDN::ConversionError)

      expect(suspicious_mailbox_name?('Example', 'user@xn--invalid.example')).to be(false)
      expect(suspicious_mailbox_name?('Example.com', 'user@xn--invalid.example')).to be(true)
      expect(suspicious_mailbox_name?(nil, 'user@xn--invalid.example')).to be(false)
      expect(suspicious_mailbox_address?('user@xn--invalid.example')).to be(true)
    end

    it 'marks a mixed-script address domain as suspicious' do
      mixed_domain = "ex\u0430mple.com"

      expect(suspicious_mailbox_address?("user@#{mixed_domain}")).to be(true)
      expect(suspicious_mailbox_name?('example.com', "user@#{mixed_domain}")).to be(true)
      expect(suspicious_mailbox_name?('Example', "user@#{mixed_domain}")).to be(false)
    end

    it 'allows compatible scripts in an address domain' do
      expect(suspicious_mailbox_address?('user@example.com')).to be(false)
      expect(suspicious_mailbox_address?("user@\u65E5\u672C\u8A9E\u3002\uFF2A\uFF30")).to be(false)
    end

    %w[日本語.jp ドメイン名例.jp].each do |domain|
      it "allows the legitimate Japanese domain #{domain}" do
        expect(suspicious_mailbox_address?("user@#{domain}")).to be(false)
        expect(suspicious_mailbox_name?(domain, "user@#{domain}")).to be(false)
      end
    end

    it 'marks a mismatching domain-like name as suspicious' do
      expect(suspicious_mailbox_name?('Example.com', 'user@example.net')).to be(true)
      expect(suspicious_mailbox_name?('notexample.com', 'user@example.com')).to be(true)
    end

    it 'marks a confusable email domain as suspicious' do
      expect(suspicious_mailbox_name?("example\uFF0Ecom", 'user@example.com')).to be(true)
      expect(suspicious_mailbox_name?("example\u2024com", 'user@example.com')).to be(true)
      expect(suspicious_mailbox_name?("examp\u04CFe.com", 'user@example.com')).to be(true)
    end

    it 'returns an empty array for a malformed address header' do
      message = Mail.read_from_string("From: invalid address <\n\nBody")

      expect(get_addresses(message, :from)).to eq([])
    end
  end

  describe 'get_date' do
    it 'returns the message DateTime without converting it to a string' do
      message = Mail.new(date: 'Fri, 7 Aug 2026 12:34:56 +0900')

      expect(get_date(message)).to be_a(DateTime)
      expect(get_date(message)).to eq(message.date)
    end
  end

end
