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

  # rubocop:disable Style/HashSyntax
  # rubocop:disable Style/SpaceInsideHashLiteralBraces
  # rubocop:disable Style/SpaceAroundOperators
  let!(:array_cada) do
    [[array, true, nil, :a1],
     [array, false, nil, {:a2=>42, :a3=>3.1415, :a4=>[:a5, true], :a6=>{:a7=>42}}],
     [array, true, "1", [:a2, 42]],
     [array, true, "1", [:a3, 3.1415]],
     [array, false, "1", [:a4, [:a5, true]]],
     [array, true, "1.a4", :a5],
     [array, true, "1.a4", true],
     [array, false, "1", [:a6, {:a7=>42}]],
     [array, true, "1.a6", [:a7, 42]],
     [array, false, nil, [:a8, :a9]],
     [array, true, "2", :a8],
     [array, true, "2", :a9],
     [array, true, nil, :a10]]
  end

  let!(:array_mapa) do
    [:a1, {:a2=>84, :a3=>6.283, :a4=>[:a5, true], :a6=>{:a7=>84}}, [:a8, :a9], :a10]
  end

  let!(:hash_cada) do
    [[hash, true, nil, [:a1, 42]],
     [hash, false, nil, [:a2, {:a3=>42, :a4=>{:a5=>42, :a6=>[:a7, :a8]}}]],
     [hash, true, "a2", [:a3, 42]],
     [hash, false, "a2", [:a4, {:a5=>42, :a6=>[:a7, :a8]}]],
     [hash, true, "a2.a4", [:a5, 42]],
     [hash, false, "a2.a4", [:a6, [:a7, :a8]]],
     [hash, true, "a2.a4.a6", :a7],
     [hash, true, "a2.a4.a6", :a8]]
  end

  let!(:hash_mapa) do
    {:a1=>84, :a2=>{:a3=>84, :a4=>{:a5=>84, :a6=>[:a7, :a8]}}}
  end
  # rubocop:enable Style/SpaceAroundOperators
  # rubocop:enable Style/SpaceInsideHashLiteralBraces
  # rubocop:enable Style/HashSyntax

  it 'has a version number' do
    expect(Iteraptor::VERSION).not_to be nil
  end

  # rubocop:disable Style/AsciiIdentifiers
  # rubocop:disable Style/VariableName
  describe 'examples' do
    λ = ->(root, leaf, parent, element) { puts "#{root.inspect} » #{leaf} » #{parent.nil? ? 'nil' : parent} » #{element.inspect}" }
    [:a, b: { c: 42 }].cada(&λ)
    { a: 42, b: [:c, :d] }.cada(&λ)
  end
  # rubocop:enable Style/VariableName
  # rubocop:enable Style/AsciiIdentifiers

  describe 'cada' do
    it 'can not be calculated lazily' do
      expect(array.cada).to be_is_a Enumerator
      expect(array.cada.size).to be_nil
      expect(hash.cada).to be_is_a Enumerator
      expect(hash.cada.size).to be_nil
    end

    it 'iterates through all the elements' do
      expect(array.cada.to_a).to eq array_cada
      expect(hash.cada.to_a).to eq hash_cada
    end
  end

  describe 'mapa' do
    it 'can not be calculated lazily' do
      expect(array.mapa).to be_is_a Enumerator
      expect(array.mapa.size).to be_nil
      expect(hash.mapa).to be_is_a Enumerator
      expect(hash.mapa.size).to be_nil
    end

    describe 'array' do
      it 'maps the elements correctly' do
        expect(array.mapa do |_, _, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq array_mapa
      end
    end
    describe 'hash' do
      it 'maps the elements correctly' do
        expect(hash.mapa do |_, _, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq hash_mapa
      end
    end
  end
end
