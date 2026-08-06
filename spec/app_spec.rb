require 'bundler/setup'
require 'fileutils'
require 'json'
require 'rack/mock'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/app'

describe Mail2www::App do
  let(:mail_root) { Dir.mktmpdir('mail2www-spec') }
  let(:app_class) do
    Class.new(described_class).tap do |app|
      app.set :mail_dir, mail_root
      app.set :folders, %w[public]
      app.set :title, 'Test archive'
      app.set :smtp_server, 'smtp.example.test'
      app.set :mailname, 'example.test'
      app.set :bounce_to, 'bounce@example.test'
    end
  end
  let(:request) { Rack::MockRequest.new(app_class.new) }

  before do
    FileUtils.mkdir_p(File.join(mail_root, 'public'))
    File.binwrite(File.join(mail_root, 'public', '1'), <<~MAIL)
      From sender@example.test Thu Jan 01 00:00:00 2026
      From: Sender <sender@example.test>
      To: archive@example.test
      Subject: API test
      Date: Thu, 1 Jan 2026 00:00:00 +0000
      Content-Type: text/plain; charset=UTF-8

      Hello from the API.
    MAIL
  end

  after { FileUtils.remove_entry(mail_root) }

  it 'reports API health without redirecting' do
    response = request.get('/api')

    expect(response.status).to eq(200)
    expect(response['content-type']).to include('application/json')
    expect(JSON.parse(response.body)).to eq('OK')
  end

  it 'returns frontend configuration' do
    response = request.get('/api/config')

    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)).to include(
      'title' => 'Test archive', 'folders' => ['public']
    )
    expect(JSON.parse(response.body)).not_to have_key('mails_per_page')
  end

  it 'lists messages with pagination metadata' do
    response = request.get('/api/folders/public/messages?page=0&per_page=10')
    body = JSON.parse(response.body)

    expect(response.status).to eq(200)
    expect(body).to include('page' => 0, 'pages' => 1, 'total' => 1)
    expect(body.fetch('messages').first).to include('number' => '1', 'subject' => 'API test')
  end

  it 'requires the frontend to choose a page size' do
    response = request.get('/api/folders/public/messages')

    expect(response.status).to eq(400)
    expect(JSON.parse(response.body).fetch('error')).to start_with('per_page must be')
  end

  it 'returns a parsed message' do
    response = request.get('/api/folders/public/messages/1', 'HTTP_X_FORWARDED_USER' => 'member')
    body = JSON.parse(response.body)

    expect(response.status).to eq(200)
    expect(body.fetch('body')).to include('Hello from the API.')
    expect(body.fetch('remote_user')).to eq('member')
  end

  it 'returns JSON errors and rejects unconfigured folders' do
    response = request.get('/api/folders/private/messages')

    expect(response.status).to eq(404)
    expect(response['content-type']).to include('application/json')
    expect(JSON.parse(response.body)).to eq('error' => 'Folder not found')
  end

  it 'rejects path-like message numbers' do
    response = request.get('/api/folders/public/messages/not-a-number')
    expect(response.status).to eq(404)
  end
end
