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

  describe 'get_addresses' do
    it 'returns display names and addresses for each mailbox' do
      message = Mail.new
      message.to = ['John Doe <john@example.com>', 'jane@example.com']

      expect(get_addresses(message, :to)).to eq(
        [
          { name: 'John Doe', address: 'john@example.com' },
          { name: nil, address: 'jane@example.com' }
        ]
      )
      expect(get_addresses(message, :cc)).to eq([])
    end
  end

end
