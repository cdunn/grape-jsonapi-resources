require 'spec_helper'

describe 'Grape::EndpointExtension' do
  if Grape::Util.const_defined?('InheritableSetting')
    subject { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: 'foo') }
  else
    subject { Grape::Endpoint.new({}, path: '/', method: 'foo') }
  end

  let(:serializer) { Grape::Formatter::JSONAPIResources }

  let(:user) do
    User.new(name: "yasiel")
  end

  let(:users) { [user, user] }

  describe '#render' do
    before do
      allow(subject).to receive(:env).and_return({})
    end

    it { should respond_to(:render) }

    context 'settings options' do
      it 'sets the jsonapi options on the environment' do
        expect(subject.render(users, {include: ["included_resource"]})).to eq(users)
        expect(subject.env).to include({"jsonapi_options"=>{:include=>["included_resource"]}})
      end
    end
  end
end
