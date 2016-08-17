require 'spec_helper'

describe Grape::Formatter::JSONAPIResources do
  subject { Grape::Formatter::JSONAPIResources }

  describe 'serializer options from namespace' do
    let(:app) { Class.new(Grape::API) }

    before do
      app.format :json
      app.formatter :json, Grape::Formatter::JSONAPIResources

      app.namespace('space') do |ns|
        ns.jsonapi_base_url "/api/v1"
        ns.get('/') do
          { user: { first_name: 'Cary', last_name: 'D' } }
        end
      end
    end

    it 'should read serializer options like "jsonapi_base_url"' do
      expect(described_class.build_options_from_endpoint(app.endpoints.first)).to include({base_url: "/api/v1"})
    end
  end

  describe '.serialize_resource' do
    let(:user) { User.new(first_name: 'John', id: 123) }
    let(:user_2) { User.new(first_name: 'Jane', id: 456) }
    let(:blog_post) { BlogPost.new(title: 'Blag', body: 'Super blag', id: 321) }

    if Grape::Util.const_defined?('InheritableSetting')
      let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: 'foo', root: false) }
    else
      let(:endpoint) { Grape::Endpoint.new({}, path: '/', method: 'foo', root: false) }
    end

    let(:env) { { 'api.endpoint' => endpoint } }

    before do
      def endpoint.current_user
        @current_user ||= User.new(first_name: 'Current user')
      end
    end

    subject { described_class.serialize_resource(user, env) }

    it { should be_a String }

    it 'should have used the correct resource' do
      expect(UserResource).to receive(:new).with(user, {current_user: endpoint.current_user}).once.and_call_original
      subject
    end

    it 'should map a collect of resources' do
      expect(UserResource).to receive(:new).with(user, {current_user: endpoint.current_user}).twice.and_call_original
      described_class.serialize_resource([ user, user ], env)
    end

    it 'should maintain order of different resources' do
      serialized_results = ActiveSupport::JSON.decode(described_class.serialize_resource([user, blog_post, user_2], env))
      expect(serialized_results["data"].map {|r| r["id"]}).to eq([user.id, blog_post.id, user_2.id].map(&:to_s))
      expect(serialized_results["data"].map {|r| r["type"]}).to eq(["users", "blog-posts", "users"])
    end

    it 'should specify serializer options like "base_url" and "include"' do
      allow(described_class).to receive(:build_options_from_endpoint).with(endpoint).and_return({base_url: "/api/v1"})
      expect(JSONAPI::ResourceSerializer).to receive(:new).with(UserResource, {base_url: "/api/v1"}).and_call_original
      subject
    end

    it 'should allow custom meta tag' do
      meta = {total_pages: 123}
      allow(described_class).to receive(:build_options_from_endpoint).with(endpoint).and_return({meta: meta})
      expect(subject).to match meta.to_json
    end
  end
end
