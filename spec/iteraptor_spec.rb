require 'spec_helper'

describe Iteraptor do
  let!(:array) do
    [
      :a1,
      { a2: 42, a3: 3.1415, a4: [:a5, true], a6: { a7: 42 } },
      [:a8, :a9],
      :a10
    ]
  end

  let!(:hash) do
    {
      a1: 42,
      a2: { a3: 42, a4: { a5: 42, a6: [:a7, :a8] } }
    }
  end

  it 'has a version number' do
    expect(Iteraptor::VERSION).not_to be nil
  end

  it 'iterates through all the elements' do
    array.cada do |*elem|
      puts elem.inspect
    end
    hash.cada do |*elem|
      puts elem.inspect
    end
    # expect(false).to eq(true)
  end
end
