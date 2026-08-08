# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'kconv'
require 'public_suffix'
require 'simpleidn'
require 'sinatra/base'
require 'unicode/scripts'
require_relative 'unicode_confusables'

module Mail2www
  module Helpers
    DOMAIN_LABEL = '[\p{L}\p{N}](?:[\p{L}\p{N}\p{M}-]{0,61}[\p{L}\p{N}\p{M}])?'
    DOMAIN_PATTERN = /#{DOMAIN_LABEL}(?:\.#{DOMAIN_LABEL})*\.\p{L}[\p{L}\p{M}]{1,62}/i
    IDN_DOT_SEPARATORS = "\uFF0E\u3002\uFF61"

    def get_addresses(mail, field_name)
      field = mail[field_name]
      return [] unless field&.element

      field.element.addresses.map do |mailbox|
        name = mailbox.display_name&.encode('utf-8')&.scrub
        address = mailbox.address.encode('utf-8').scrub
        suspicious_name, suspicious_address = mailbox_suspicion(name, address)
        address = resolve_mailbox_address(address, suspicious_address)
        { name:, address:, suspicious_name:, suspicious_address: }
      end
    end

    def resolve_mailbox_address(address, suspicious_address)
      local, separator, domain = address.rpartition('@')
      return address if separator.empty?

      decoded_domain = SimpleIDN.to_unicode(domain.delete_suffix('.'))
      resolved_domain = suspicious_address ? SimpleIDN.to_ascii(decoded_domain) : decoded_domain
      "#{local}@#{resolved_domain}"
    rescue SimpleIDN::ConversionError
      address
    end

    def mailbox_suspicion(name, address)
      domain = address.rpartition('@').last.downcase.delete_suffix('.')
      return [suspicious_name_syntax?(name), false] if domain.empty?

      decoded_domain = SimpleIDN.to_unicode(domain)
      suspicious_address = decoded_domain.split('.').any? { |label| Unicode::Scripts.mixed?(label) }
      [suspicious_mailbox_name_for_domain?(name, decoded_domain, suspicious_address), suspicious_address]
    rescue SimpleIDN::ConversionError
      [suspicious_name_syntax?(name) || domain_like_name?(name), true]
    end

    def suspicious_mailbox_name_for_domain?(name, domain, suspicious_address)
      return false unless name
      return true if /[@<>]/.match?(name)

      skeleton_domains = domain_skeletons(name)
      return false if skeleton_domains.empty?
      return true if suspicious_address

      address_registrable_domain = registrable_domain(domain)
      name_domains = name.downcase.scan(DOMAIN_PATTERN)
      name_domains.empty? || name_domains.any? do |candidate|
        registrable_domain(candidate) != address_registrable_domain
      end
    end

    def suspicious_name_syntax?(name)
      !!(name && /[@<>]/.match?(name))
    end

    def domain_like_name?(name)
      !!(name && !domain_skeletons(name).empty?)
    end

    def domain_skeletons(name)
      detectable_name = name.downcase.tr(IDN_DOT_SEPARATORS, '.')
      UnicodeConfusables.default.skeleton(detectable_name).scan(DOMAIN_PATTERN)
    end

    def registrable_domain(domain)
      PublicSuffix.domain(SimpleIDN.to_ascii(domain))
    end

    def get_subject(mail)
      mail.subject ? mail.subject.encode('utf-8').scrub : '(no subject)'
    rescue Encoding::UndefinedConversionError
      '(no subject)'
    end

    def get_date(mail)
      mail.date || mail.envelope_date
    end

    def body_text(message)
      raw_text = message.body.decoded

      if message.content_type
        charset = message.content_type_parameters['charset']
      end

      encoding =
        begin
          Encoding.find(charset) if charset
        rescue ArgumentError
          nil
        end || Kconv.guess(raw_text) || Encoding.UTF_8

      raw_text.force_encoding(encoding).encode('utf-8', invalid: :replace, undef: :replace)
    end

    def get_body(message)
      text_part = message.text_part
      html_part = message.html_part

      unless message.multipart?
        text_part ||= message if message.mime_type.nil? || message.mime_type == 'text/plain'
        html_part ||= message if message.mime_type == 'text/html'
      end

      {
        text: text_part && body_text(text_part),
        html: html_part && body_text(html_part)
      }
    end

    def spam?(mail)
      spam = [*mail.header['X-Spam']]
      spam.any? {|v| v.value.upcase == 'YES' }
    end

    def virus_detected?(mail)
      virus = [*mail.header['X-Virus']]
      return if virus.empty?

      virus.map(&:value).join(', ')
    end
  end
end
