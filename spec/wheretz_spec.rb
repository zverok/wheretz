# frozen_string_literal: true

describe WhereTZ do
  describe '#lookup' do
    subject { described_class.method(:lookup) }

    context 'when unambiguous bounding box: Moscow' do
      its_call(55.75, 37.616667) { is_expected.to ret('Europe/Moscow') }
      its_call(55.75, 37.616667) { is_expected.not_to send_message(File, :read) }
    end

    context 'when ambiguous bounding box: Kharkiv' do
      before {
        expect(File).to receive(:read).twice.and_call_original # rubocop:disable RSpec/ExpectInHook,RSpec/MessageSpies
      }

      its_call(50.004444, 36.231389) { is_expected.to ret 'Europe/Kiev' }
    end

    context 'when edge case' do
      its_call(43.6605555555556, 7.2175) { is_expected.to ret 'Europe/Paris' }
    end

    context 'when no timezone: middle of the ocean' do
      its_call(35.024992, -39.481339) { is_expected.to ret be_nil }
    end

    context 'when ambiguous timezones' do
      its_call(50.28337, -107.80135) {
        is_expected.to ret ['America/Regina', 'America/Swift_Current']
      }
    end
  end

  describe '#get' do
    subject { described_class.method(:get) }

    its_call(55.75, 37.616667) { is_expected.to ret TZInfo::Timezone.get('Europe/Moscow') }
    its_call(35.024992, -39.481339) { is_expected.to ret be_nil }

    context 'when ambiguous timezones' do
      its_call(50.28337, -107.80135) {
        is_expected.to ret [TZInfo::Timezone.get('America/Regina'),
                            TZInfo::Timezone.get('America/Swift_Current')]
      }
    end
  end
end
