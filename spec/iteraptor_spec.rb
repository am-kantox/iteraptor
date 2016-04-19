require 'spec_helper'
require 'set'

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

  let!(:nest) do
    { top: { key: 42, subkey: { key: 3.1415 } }, keys: [:key, :key] }
  end

  let!(:set) do
    { a: 42, s: [:v1, :v2, 42].to_set }
  end

  # rubocop:disable Style/HashSyntax
  # rubocop:disable Style/SpaceInsideHashLiteralBraces
  # rubocop:disable Style/SpaceAroundOperators
  let!(:array_cada) do
    [["0", :a1],
     ["1", {:a2=>42, :a3=>3.1415, :a4=>[:a5, true], :a6=>{:a7=>42}}],
     ["1.a2", 42],
     ["1.a3", 3.1415],
     ["1.a4", [:a5, true]],
     ["1.a4.0", :a5],
     ["1.a4.1", true],
     ["1.a6", {:a7=>42}],
     ["1.a6.a7", 42],
     ["2", [:a8, :a9]],
     ["2.0", :a8],
     ["2.1", :a9],
     ["3", :a10]]
  end

  let!(:array_mapa) do
    [:a1, {:a2=>84, :a3=>6.283, :a4=>[:a5, true], :a6=>{:a7=>84}}, [:a8, :a9], :a10]
  end

  let!(:hash_cada) do
    [["a1", 42],
     ["a2", {:a3=>42, :a4=>{:a5=>42, :a6=>[:a7, :a8]}}],
     ["a2.a3", 42],
     ["a2.a4", {:a5=>42, :a6=>[:a7, :a8]}],
     ["a2.a4.a5", 42],
     ["a2.a4.a6", [:a7, :a8]],
     ["a2.a4.a6.0", :a7],
     ["a2.a4.a6.1", :a8]]
  end

  let!(:hash_mapa) do
    {:a1=>84, :a2=>{:a3=>84, :a4=>{:a5=>84, :a6=>[:a7, :a8]}}}
  end

  let!(:set_cada) do
    [["a", 42], ["s", [:v1, :v2, 42].to_set], "s"]
  end
  # rubocop:enable Style/SpaceAroundOperators
  # rubocop:enable Style/SpaceInsideHashLiteralBraces
  # rubocop:enable Style/HashSyntax

  it 'has a version number' do
    expect(Iteraptor::VERSION).not_to be nil
  end

  describe 'examples' do
    λ = ->(parent, element) { puts "#{parent.nil? ? 'nil' : parent} » #{element.inspect}" }
    [:a, b: { c: 42 }].cada(&λ)
    { a: 42, b: [:c, :d] }.cada(&λ)
  end

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

    it 'iterates a set instance' do
      expect(set.cada.to_a).to eq set_cada
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
        expect(array.mapa do |_, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq array_mapa
      end
    end
    describe 'hash' do
      it 'maps the elements correctly' do
        expect(hash.mapa do |_, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq hash_mapa
      end
    end
  end

  describe 'segar' do
    describe 'nest' do
      it 'calls back' do
        expect(nest.segar(:key) do |key, value|
          puts "Key is: #{key}, Value is: #{value}"
        end).to eq("top.key" => 42, "top.subkey.key" => 3.1415)
      end
    end
  end
end
