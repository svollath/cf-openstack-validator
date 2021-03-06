require_relative 'spec_helper'

describe Converter do

  describe 'end to end' do
    it 'produces the expected result for the given input' do
      validator_config = YAML.load_file("#{File.dirname(__FILE__)}/../assets/validator.yml")
      expected_cpi_config =  YAML.load_file("#{File.dirname(__FILE__)}/../assets/expected_cpi.json")

      allow(NetworkHelper).to receive(:next_free_ephemeral_port).and_return(11111)

      expect(Converter.to_cpi_json(validator_config)).to eq(expected_cpi_config)
    end
  end

  describe '.to_cpi_json' do

    let(:complete_config) do
      {
        'openstack' => {
          'auth_url' => 'https://auth.url/v3',
          'username' => 'username',
          'password' => 'password',
          'domain' => 'domain',
          'project' => 'project'
        }
      }
    end

    describe 'validating input' do

      required_keys = ['auth_url', 'username', 'password', 'domain', 'project']
      key_permutations = required_keys.combination(1).to_a + required_keys.combination(2).to_a

      key_permutations.each do |keys|
        context "when '#{keys.join(', ')}' is missing" do
          it 'raises a standard error' do
            keys.each { |key| complete_config['openstack'].delete(key) }

            expect {
              Converter.to_cpi_json(complete_config)
            }.to raise_error StandardError, "Required openstack properties missing: '#{keys.join(', ')}'"
          end
        end
      end
    end

    describe 'conversions' do
      it "appends 'auth/tokens' to 'auth_url' parameter" do
        rendered_cpi_config = Converter.to_cpi_json(complete_config)

        expect(rendered_cpi_config['cloud']['properties']['openstack']['auth_url']).to eq 'https://auth.url/v3/auth/tokens'
      end

      it "replaces 'password' key with 'api_key'" do
        rendered_cpi_config = Converter.to_cpi_json(complete_config)

        expect(rendered_cpi_config['cloud']['properties']['openstack']['api_key']).to eq complete_config['openstack']['password']
        expect(rendered_cpi_config['cloud']['properties']['openstack']['password']).to be_nil
      end
    end

    describe 'registry configuration' do
      it "uses the next free ephemeral port" do
        expect(NetworkHelper).to receive(:next_free_ephemeral_port).and_return(60000)

        rendered_cpi_config = Converter.to_cpi_json(complete_config)

        expect(rendered_cpi_config['cloud']['properties']['registry']['endpoint']).to eq('http://localhost:60000')
      end
    end

  end
end