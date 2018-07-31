require 'spec_helper'
require 'set'

describe Iteraptor::Delegator do
  let(:array) do
    [
      :a1,
      { a2: 42, a3: 3.1415, a4: [:a5, true], a6: { a7: 42 } },
      [:a8, :a9],
      :a10
    ]
  end

  let(:hash) do
    {
      a1: 42,
      a2: { a3: 42, a4: { a5: 42, a6: [:a7, :a8] } }
    }
  end

  let(:nest) do
    { top: { key: 42, subkey: { key: 3.1415 } }, keys: %w[1 2 3] }
  end

  let(:set) do
    { a: 42, s: [:v1, :v2, 42].to_set }
  end

  # rubocop:disable Style/HashSyntax
  # rubocop:disable Style/SpaceInsideHashLiteralBraces
  # rubocop:disable Style/SpaceAroundOperators
  let(:array_cada) do
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

  let(:array_mapa) do
    [:a1, {:a2=>84, :a3=>6.283, :a4=>[:a5, true], :a6=>{:a7=>84}}, [:a8, :a9], :a10]
  end

  let(:hash_cada) do
    [["a1", 42],
     ["a2", {:a3=>42, :a4=>{:a5=>42, :a6=>[:a7, :a8]}}],
     ["a2.a3", 42],
     ["a2.a4", {:a5=>42, :a6=>[:a7, :a8]}],
     ["a2.a4.a5", 42],
     ["a2.a4.a6", [:a7, :a8]],
     ["a2.a4.a6.0", :a7],
     ["a2.a4.a6.1", :a8]]
  end

  let(:hash_mapa) do
    {:a1=>84, :a2=>{:a3=>84, :a4=>{:a5=>84, :a6=>[:a7, :a8]}}}
  end

  let(:set_cada) do
    [["a", 42], ["s", [:v1, :v2, 42].to_set], "s"]
  end

  ##############################################################################

  # rubocop:enable Style/SpaceAroundOperators
  # rubocop:enable Style/SpaceInsideHashLiteralBraces
  # rubocop:enable Style/HashSyntax

  describe 'examples' do
    λ = ->(parent, element) { puts "#{parent.nil? ? 'nil' : parent} » #{element.inspect}" }
    [:a, b: { c: 42 }].iteraptor.each(&λ)
    { a: 42, b: [:c, :d] }.iteraptor.each(&λ)
  end

  describe 'iteraptor.each' do
    it 'can not be calculated lazily' do
      expect(array.iteraptor.each).to be_a Enumerator
      expect(array.iteraptor.each.size).to be_nil
      expect(hash.iteraptor.each).to be_a Enumerator
      expect(hash.iteraptor.each.size).to be_nil
    end

    it 'iterates through all the elements' do
      expect(array.iteraptor.each.to_a).to eq array_cada
      expect(hash.iteraptor.each.to_a).to eq hash_cada
    end

    it 'iterates a set instance' do
      expect(set.iteraptor.each.to_a).to eq set_cada
    end
  end

  describe 'empty' do
    it { expect({}.iteraptor.each {|_, _| nil}).to eq({}) }
    it { expect([].iteraptor.each {|_, _| nil}).to eq([]) }
    it { expect({}.iteraptor.map {|_, _| nil}).to eq({}) }
    it { expect([].iteraptor.map {|_, _| nil}).to eq([]) }
    it { expect({}.iteraptor.reject(//) {|*| nil}).to eq({}) }
    it { expect([].iteraptor.select(//) {|*| nil}).to eq([]) }
  end

  describe 'iteraptor.map' do
    it 'can not be calculated lazily' do
      expect(array.iteraptor.map).to be_a Enumerator
      expect(array.iteraptor.map.size).to be_nil
      expect(hash.iteraptor.map).to be_a Enumerator
      expect(hash.iteraptor.map.size).to be_nil
    end

    describe 'array' do
      it 'maps the elements correctly' do
        expect(array.iteraptor.map do |_, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq array_mapa
      end
      it 'does not stack overflows' do
        expect(array.iteraptor.map { |_, (k, v)| [k, v] }).to be_a Array
        expect(hash.iteraptor.map(full_parent: true) do |p, (key, value)|
          v = p.join + " :: #{value || key}"
          [key, v]
        end).to eq(
          :a1 => "a1 :: 42",
          :a2 => {
            :a3 => "a2a3 :: 42",
            :a4 => {
              :a5 => "a2a4a5 :: 42",
              :a6 => [
                "a2a4a60 :: a7",
                "a2a4a61 :: a8"
              ]
            }
          }
        )
      end
    end
    describe 'hash' do
      it 'maps the elements correctly' do
        expect(hash.iteraptor.map do |_, e|
          e.is_a?(Array) ? [e.first, e.last * 2] : e
        end).to eq hash_mapa
      end
    end
  end

  describe 'iteraptor.select' do
    describe 'nest' do
      it 'filters keys out' do
        expect(nest.iteraptor.select(/subkey/, symbolize_keys: true)).
          to eq(top: {subkey: {key: 3.1415}})
        expect(nest.iteraptor.reject(/subkey/, symbolize_keys: true)).
          to eq(top: {:key=>42}, keys: ["1", "2", "3"])
        expect(nest.iteraptor.select(/subkey/, symbolize_keys: true)).
          to eq(top: {subkey: {key: 3.1415}})
      end
      it 'calls back' do
        expect(nest.iteraptor.reject(:key, soft_keys: true) do |key, value|
          puts "Key is: #{key}, Value is: #{value}"
          value
        end).to eq("keys" => ["1", "2", "3"])
      end
    end
  end

  describe 'iteraptor.compact' do
    it 'compacts both arrays and hashes properly' do
      expect({foo: {bar: nil, sna: [42, nil], baz: {b1: nil, b2: 42}}}.iteraptor.compact).
        to eq({foo: {sna: [42], baz: {b2: 42}}})
    end
  end

  describe 'iteraptor.flatten' do
    it 'flattens the hash' do
      expect(hash.iteraptor.flatten).
        to eq("a1"=>42, "a2.a3"=>42, "a2.a4.a5"=>42, "a2.a4.a6.0"=>:a7, "a2.a4.a6.1"=>:a8)
      expect(hash.iteraptor.flatten delimiter: '_', symbolize_keys: true).
        to eq(:a1=>42, :a2_a3=>42, :a2_a4_a5=>42, :a2_a4_a6_0=>:a7, :a2_a4_a6_1=>:a8)
    end

    it 'flattens the array' do
      expect(array.iteraptor.flatten).
        to eq("0"=>:a1, "1.a2"=>42, "1.a3"=>3.1415, "1.a4.0"=>:a5,
              "1.a4.1"=>true, "1.a6.a7"=>42, "2.0"=>:a8, "2.1"=>:a9, "3"=>:a10)
      expect(array.iteraptor.flatten delimiter: '_', symbolize_keys: true).
        to eq(:"0"=>:a1, :"1_a2"=>42, :"1_a3"=>3.1415, :"1_a4_0"=>:a5,
              :"1_a4_1"=>true, :"1_a6_a7"=>42, :"2_0"=>:a8, :"2_1"=>:a9, :"3"=>:a10)
    end

    it 'does not ruins the single-level hash/array' do
      expect({foo: :bar}.iteraptor.flatten(symbolize_keys: true)).to eq(foo: :bar)
      expect({foo: :bar}.iteraptor.flatten).to eq("foo" => :bar)
      expect([1, 2, 3].iteraptor.flatten).to eq({"0"=>1, "1"=>2, "2"=>3})
    end
  end

  describe 'iteraptor.collect' do
    it 'works' do
      expect({"top.key"=>42, "keys.0"=>"1", "keys.1"=>"2", "keys.2"=>"3"}.iteraptor.collect(symbolize_keys: true)).
        to eq(top: {key: 42}, keys: %w[1 2 3])
    end

    it 'is an exact reverse for aplanar' do
      expect({top: {key: 42}, keys: %w[1 2 3]}.aplanar.iteraptor.collect(symbolize_keys: true)).
        to eq(top: {key: 42}, keys: %w[1 2 3])
      expect({top: {key: 42}, keys: [1, {foo: 2}, 3]}.aplanar.iteraptor.collect(symbolize_keys: true)).
        to eq(top: {key: 42}, keys: [1, {foo: 2}, 3])
    end
  end

  describe 'iteraptor.flat_map' do
    it 'can not be calculated lazily' do
      expect(array.iteraptor.flat_map).to be_a Enumerator
      expect(array.iteraptor.flat_map.size).to be_nil
      expect(hash.iteraptor.flat_map).to be_a Enumerator
      expect(hash.iteraptor.flat_map.size).to be_nil
    end

    it 'flat-maps the hash' do
      expect(hash.iteraptor.flat_map { |_k, v| v}).
        to eq([42, 42, 42, :a7, :a8])
      expect(hash.iteraptor.flat_map(delimiter: '_', symbolize_keys: true) { |k, _v| k }).
        to eq([:a1, :a2_a3, :a2_a4_a5, :a2_a4_a6_0, :a2_a4_a6_1])
    end
  end

  describe 'full_parent' do
    it 'yields the array of keys' do
      expect(hash.iteraptor.map(full_parent: true) do |p, (key, value)|
        v = p.join('_')
        value ? [key, v + " :: #{value}"] : v
      end).to eq(
        :a1 => "a1 :: 42",
        :a2 => {
          :a3 => "a2_a3 :: 42",
          :a4 => {
            :a5 => "a2_a4_a5 :: 42",
            :a6 => ["a2_a4_a6_0", "a2_a4_a6_1"]
          }
        }
      )
    end
  end
end
