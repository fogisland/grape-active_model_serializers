require 'spec_helper'
require 'grape-active_model_serializers/formatter'

describe Grape::Formatter::ActiveModelSerializers do
  describe 'with a versioned API' do
    subject { Grape::Formatter::ActiveModelSerializers }

    describe 'serializer options from namespace' do
      let(:app) { Class.new(Grape::API) }

      before do
        app.format :json
        app.formatter :json, Grape::Formatter::ActiveModelSerializers
        app.version 'v1', using: :param

        app.namespace('space') do |ns|
          ns.get('/', root: false, apiver: 'v1') do
            { user: { first_name: 'JR', last_name: 'HE', email: 'jrhe@github.com' } }
          end
        end
      end

      it 'should read serializer options like "root"' do
        expect(described_class.build_options_from_endpoint(app.endpoints.first)).to include :root
      end
    end

    describe '.fetch_serializer' do
      let(:user) { User.new(first_name: 'John', email: 'j.doe@internet.com') }

      if Grape::Util.const_defined?('InheritableSetting')
        let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: 'foo', version: 'v1', root: false) }
      else
        let(:endpoint) { Grape::Endpoint.new({}, path: '/', method: 'foo', version: 'v1', root: false) }
      end

      let(:env) { { 'api.endpoint' => endpoint } }

      before do
        def endpoint.current_user
          @current_user ||= User.new(first_name: 'Current user')
        end

        def endpoint.default_serializer_options
          { only: :only, except: :except }
        end
      end

      subject { described_class.fetch_serializer(user, env) }

      it { should be_a V1::UserSerializer }

      it 'should have correct scope set' do
        expect(subject.scope.current_user).to eq(endpoint.current_user)
      end

      it 'should read default serializer options' do
        expect(subject.instance_variable_get('@only')).to eq([:only])
        expect(subject.instance_variable_get('@except')).to eq([:except])
      end

      it 'should read serializer options like "root"' do
        expect(described_class.build_options_from_endpoint(endpoint).keys).to include :root
      end
    end
  end
end
