# frozen_string_literal: true

RSpec.describe 'HTTP connection retry on stale keep-alive' do
  let(:http_connection) { instance_double(Net::HTTP) }
  let(:response_body) do
    ([%w[value], %w[UInt8], [1]]).map(&:to_json).join("\n")
  end
  let(:response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
  let(:config) do
    {
      adapter: 'clickhouse',
      host: 'localhost',
      port: 8123,
      database: 'test_db'
    }
  end
  subject(:adapter) { ActiveRecord::Base.clickhouse_connection(config) }

  before do
    allow(Net::HTTP).to receive(:start).and_return(http_connection)
    allow(http_connection).to receive(:ca_file=)
    allow(http_connection).to receive(:read_timeout=)
    allow(http_connection).to receive(:write_timeout=)
    allow(http_connection).to receive(:keep_alive_timeout=)
    allow(http_connection).to receive(:started?).and_return(true)
    allow(http_connection).to receive(:finish)
  end

  describe '#execute (POST)' do
    it 'reconnects and retries once when the socket raises EOFError' do
      call_count = 0
      allow(http_connection).to receive(:post) do
        call_count += 1
        raise EOFError, 'end of file reached' if call_count == 1

        response
      end

      expect { adapter.execute('SELECT 1') }.not_to raise_error
      expect(call_count).to eq(2)
      # initial connect + one reconnect after the stale-socket error
      expect(Net::HTTP).to have_received(:start).twice
      expect(http_connection).to have_received(:finish).once
    end

    it 'reconnects and retries once for Errno::ECONNRESET' do
      call_count = 0
      allow(http_connection).to receive(:post) do
        call_count += 1
        raise Errno::ECONNRESET if call_count == 1

        response
      end

      expect { adapter.execute('SELECT 1') }.not_to raise_error
      expect(call_count).to eq(2)
      expect(Net::HTTP).to have_received(:start).twice
    end

    it 're-raises when the second attempt also fails' do
      allow(http_connection).to receive(:post).and_raise(EOFError, 'end of file reached')

      expect { adapter.execute('SELECT 1') }.to raise_error(EOFError)
      # initial connect + one reconnect; then the second failure is re-raised
      expect(Net::HTTP).to have_received(:start).twice
      expect(http_connection).to have_received(:post).twice
    end

    it 'does not retry on unrelated errors' do
      allow(http_connection).to receive(:post).and_raise(ArgumentError, 'boom')

      expect { adapter.execute('SELECT 1') }.to raise_error(ArgumentError, 'boom')
      # no reconnect
      expect(Net::HTTP).to have_received(:start).once
      expect(http_connection).to have_received(:post).once
    end
  end

  describe '#execute_to_file (streaming)' do
    let(:streaming_response) { instance_double(Net::HTTPResponse, code: '200') }

    it 'reconnects and retries once when the socket raises EOFError' do
      allow(streaming_response).to receive(:read_body).and_yield("value\nUInt8\n1\n")

      call_count = 0
      allow(http_connection).to receive(:request) do |_req, _body, &block|
        call_count += 1
        raise EOFError, 'end of file reached' if call_count == 1

        block.call(streaming_response)
      end

      file = adapter.execute_to_file('SELECT 1')
      expect(file.read).to eq("value\nUInt8\n1\n")
      file.close!

      expect(call_count).to eq(2)
      expect(Net::HTTP).to have_received(:start).twice
    end
  end
end
