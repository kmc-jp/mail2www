require 'bundler/setup'
require 'json'
require 'rack/mock'

require_relative 'spec_helper'
require_relative '../lib/app'

describe Mail2www::App do
  let(:mail_root) { File.expand_path('fixtures/mail', __dir__) }
  let(:app_class) do
    Class.new(described_class).tap do |app|
      app.set :mail_dir, mail_root
      app.set :folders, %w[public]
      app.set :smtp_server, 'smtp.example.test'
      app.set :mailname, 'example.test'
      app.set :bounce_to, 'bounce@example.test'
    end
  end
  let(:request) { Rack::MockRequest.new(app_class.new) }

  it 'reports API health without redirecting' do
    response = request.get('/api')

    expect(response.status).to eq(200)
    expect(response['content-type']).to include('application/json')
    expect(JSON.parse(response.body)).to eq('OK')
  end

  it 'returns frontend configuration' do
    response = request.get('/api/config', 'HTTP_X_FORWARDED_USER' => 'member')

    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)).to include(
      'folders' => ['public'], 'ruby_version' => RUBY_VERSION, 'remote_user' => 'member'
    )
    expect(JSON.parse(response.body)).not_to have_key('title')
    expect(JSON.parse(response.body)).not_to have_key('mails_per_page')
  end

  it 'lists messages with pagination metadata' do
    response = request.get('/api/folders/public/messages?page=0&per_page=10')
    body = JSON.parse(response.body)

    expect(response.status).to eq(200)
    expect(body).to include('page' => 0, 'pages' => 1, 'total' => 7)
    expect(body.fetch('messages').first).to include(
      'number' => '7',
      'from' => [{ 'name' => 'Sender', 'address' => 'sender@example.test' }],
      'subject' => 'Virus-flagged message with attachment',
      'date' => '2026-01-07T00:00:00+00:00'
    )
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
    expect(body.fetch('body')).to eq(
      'text' => "Hello from the API.\n",
      'html' => nil
    )
    expect(body.fetch('headers')).to include(
      'from' => [{ 'name' => 'Sender', 'address' => 'sender@example.test' }],
      'to' => [{ 'name' => nil, 'address' => 'archive@example.test' }],
      'cc' => [],
      'date' => '2026-01-01T00:00:00+00:00'
    )
    expect(body).not_to have_key('remote_user')
  end

  it 'lists folders that are not in the navigation configuration' do
    response = request.get('/api/folders/unlisted/messages?per_page=10')
    body = JSON.parse(response.body)

    expect(response.status).to eq(200)
    expect(body.fetch('messages').first).to include('number' => '1', 'subject' => 'Unlisted folder')
  end

  it 'rejects folders beginning with a dot' do
    response = request.get('/api/folders/.private/messages?per_page=10')

    expect(response.status).to eq(404)
    expect(JSON.parse(response.body)).to eq('error' => 'Folder not found')
  end

  it 'rejects folders containing a slash' do
    response = request.get('/api/folders/public%2Fsecret/messages?per_page=10')

    expect(response.status).to eq(404)
    expect(JSON.parse(response.body)).to eq('error' => 'Folder not found')
  end

  it 'rejects path-like message numbers' do
    response = request.get('/api/folders/public/messages/not-a-number')
    expect(response.status).to eq(404)
  end
end
