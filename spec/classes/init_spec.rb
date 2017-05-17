require 'spec_helper'
describe 'gunicorn' do
  context 'with default values for all parameters' do
    it { should contain_class('gunicorn') }
  end
end
