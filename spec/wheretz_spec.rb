describe WhereTZ do
  describe :lookup do
    subject{WhereTZ.lookup(*lat_lng)}

    context 'unambiguous bounding box' do
      let(:lat_lng){ [55.75, 37.616667]} # Moscow
      before{
        expect(File).not_to receive(:read)
      }
      it{should == 'Europe/Moscow'}
    end

    context 'ambiguous bounding box' do
      let(:lat_lng){ [50.004444, 36.231389] } # Kharkiv
      before{
        expect(File).to receive(:read).exactly(2).times.and_call_original
      }
      it{should == 'Europe/Kiev'}
    end

    context 'edge case' do
      let(:lat_lng){ [43.6605555555556, 7.2175] }
      it{should == 'Europe/Paris'}
    end

    context 'no timezone' do
      let(:lat_lng){ [35.024992,-39.481339] } # middle of the ocean
      it{should be_nil}
    end
  end

  describe :get do

    context 'when found' do
      let(:lat_lng){ [55.75, 37.616667]}
      subject{WhereTZ.get(*lat_lng)}
      it{should == TZInfo::Timezone.get('Europe/Moscow')}
    end

    context 'when notfound' do
      let(:lat_lng){ [35.024992,-39.481339]}
      subject{WhereTZ.get(*lat_lng)}
      it{should be_nil}
    end

    xcontext 'when tzinfo not installed' do
      before{
        expect(Kernel).to receive(:require).
          with('tzinfo'){p "HERE"; raise LoadError}
      }
      it 'should raise informative error' do
        expect{WhereTZ.get(55.75, 37.616667)}.to \
          raise_error(LoadError, "Please install tzinfo for using #get")
      end
    end
  end
end
