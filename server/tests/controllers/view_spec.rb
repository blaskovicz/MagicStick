require_relative '../spec_helper'
require_relative '../../controllers/view'
require 'English'
describe 'View' do
  def app
    ViewController
  end

  it 'should respond to status check' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.body).not_to be_empty
    expect(last_response.headers['Content-Type']).to eq('text/html;charset=utf-8')

    npm_bin = `npm bin`.chomp
    expect($CHILD_STATUS).to be_success
    file = File.new('view.html', 'w')
    file.write(last_response.body)
    file.close
    sleep 1
    output = `#{File.join(npm_bin, 'phantomjs')} #{File.join(File.dirname(__FILE__), 'view.phantom.js')} file://#{File.expand_path(file.path)}`.chomp
    expect($CHILD_STATUS).to be_success
    expect(output).to eq('SUCCESS.')
    File.unlink(file.path)
  end
end
