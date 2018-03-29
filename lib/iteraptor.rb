require "iteraptor/version"

# rubocop:disable Style/VariableNumber
# rubocop:disable Metrics/ModuleLength
module Iteraptor
  DELIMITER = '.'.freeze

  def self.included base
    raise "This module might be included into Enumerables only" unless base.ancestors.include? Enumerable
  end

  %i[cada mapa].each do |m|
    define_method m do |root = nil, parent = nil, yield_all: false, &λ|
      return enum_for(m, root, parent, yield_all: yield_all) unless λ

      send_to = [Hash, Array, Enumerable].detect(&method(:is_a?))
      send_to && send("#{m}_in_#{send_to.name.downcase}", root || self, parent, yield_all: yield_all, &λ)
    end
  end

  def escoger *filter, soft_keys: true
    raise ArgumentError, "no filter given in call to escoger" if filter.empty?

    mapa do |parent, (k, v)|
      to_match = soft_keys ? [k.to_s, k.to_s.to_sym] : [k]
      next unless filter.any? { |f| to_match.any?(&f.method(:===)) }

      v = yield parent, [k, v] if block_given?
      [k, v]
    end
  end

  def rechazar *filter, soft_keys: true
    raise ArgumentError, "no filter given in call to rechazar" if filter.empty?

    aplanar.each_with_object({}) do |(key, value), acc|
      to_match = key.split(DELIMITER)
      to_match = to_match.flat_map { |k| [k.to_s, k.to_s.to_sym] } if soft_keys
      puts [key, value.inspect, to_match].inspect

      next if filter.any? { |f| to_match.any?(&f.method(:===)) }

      value = yield key, value if block_given?
      acc[key] = value
    end.recoger
  end

  # rubocop:disable Style/Alias
  alias_method :segar, :rechazar
  # rubocop:enable Style/Alias

  def aplanar delimiter: DELIMITER, symbolize_keys: false
    cada.with_object({}) do |(parent, element), acc|
      key = parent.tr(DELIMITER, delimiter)
      key = key.to_sym if symbolize_keys
      acc[key] = element unless element.is_a?(Enumerable)
      yield key, element if block_given?
    end
  end

  def recoger delimiter: DELIMITER, symbolize_keys: false
    # rubocop:disable Style/MultilineBlockChain
    aplanar.each_with_object(
      Hash.new { |h, k| h[k] = h.clone.clear }
    ) do |(k, v), acc|
      keys = k.split(delimiter)
      parent = keys[0..-2].reduce(acc){ |h, kk| h[kk] }
      parent[keys.last] = v
    end.mapa(yield_all: true) do |parent, (k, v)|
      # puts [parent, k, v].inspect
      # # binding.pry if v.is_a?(Hash)
      # v = v.values if v.is_a?(Hash) && v.keys.map(&:to_i).sort == (0...v.keys.size).to_a
      [k, v]
    end
    # rubocop:enable Style/MultilineBlockChain
  end

  def plana_mapa delimiter: DELIMITER, symbolize_keys: false
    # rubocop:disable Style/MultilineIfModifier
    return enum_for(
      :plana_mapa, delimiter: delimiter, symbolize_keys: symbolize_keys
    ) unless block_given?
    # rubocop:enable Style/MultilineIfModifier

    cada.with_object([]) do |(parent, element), acc|
      key = parent.tr(DELIMITER, delimiter)
      key = key.to_sym if symbolize_keys
      acc << yield(key, element) unless element.is_a?(Enumerable)
    end
  end

  private

  ##############################################################################
  ### cada
  CADA_PROC = lambda do |e, root, p, &λ|
    case e
    when Iteraptor then e.cada(root, p, &λ)
    when Enumerable then e.each(&λ.curry[p])
    end
  end

  def cada_in_array root = nil, parent = nil, **_
    λ = Proc.new
    each.with_index do |e, idx|
      [parent, idx].compact.join(DELIMITER).tap do |p|
        yield p, e
        CADA_PROC.call(e, root, p, &λ)
      end
    end
  end
  alias cada_in_enumerable cada_in_array

  def cada_in_hash root = nil, parent = nil, **_
    λ = Proc.new
    each do |k, v|
      [parent, k].compact.join(DELIMITER).tap do |p|
        yield p, v
        CADA_PROC.call(v, root, p, &λ)
      end
    end
  end

  ##############################################################################
  ### mapa
  # FIXME what happens if I return nil from mapa in array?
  def mapa_in_array root = nil, parent = nil, with_index: false, yield_all: false
    λ = Proc.new

    map.with_index do |e, idx|
      p = [parent, idx].compact.join(DELIMITER)

      e = yield p, (with_index ? [idx.to_s, e] : e) if !e.is_a?(Enumerable) || yield_all

      case e
      when Iteraptor then e.mapa(root, p, yield_all: yield_all, &λ)
      when Enumerable then e.map(&λ.curry[p])
      else e
      end
    end
  end
  alias mapa_in_enumerable mapa_in_array

  def mapa_in_hash root = nil, parent = nil, yield_all: false
    λ = Proc.new

    map do |k, v|
      p = [parent, k].compact.join(DELIMITER)

      k, v = yield p, [k, v] if !v.is_a?(Enumerable) || yield_all

      case v
      when Iteraptor then [k, v.mapa(root, p, yield_all: yield_all, &λ)]
      when Enumerable then [k, v.map(&λ.curry[p])]
      else k.nil? ? nil : [k, v]
      end
    end.compact.send(:to_hash_or_array)
  end

  ##############################################################################
  ### filter
  def to_hash_or_array
    # rubocop:disable Style/MultilineTernaryOperator
    # rubocop:disable Style/RescueModifier
    receiver =
      is_a?(Array) &&
        all? { |e| e.is_a?(Enumerable) && e.size == 2 } &&
        map(&:first).uniq.size == size ? (to_h rescue self) : self
    # rubocop:enable Style/RescueModifier

    receiver.is_a?(Hash) &&
      receiver.keys.each_with_index.all? { |key, idx| key == idx.to_s } ?
      receiver.values : receiver
    # rubocop:enable Style/MultilineTernaryOperator
  end

  HASH_TO_ARRAY_ERROR_MSG = %(undefined method `hash_to_array?' for "%s":%s).freeze
  def hash_to_hash_or_array
    raise NoMethodError, HASH_TO_ARRAY_ERROR_MSG % [inspect, self.class] unless is_a?(Hash)
  end

  def mapa_filtered select = true

  end


  ##############################################################################
  ### helpers
  def leaf? e
    [Iteraptor, Enumerable].none?(&e.method(:is_a?))
  end
end

require 'iteraptor/greedy'
