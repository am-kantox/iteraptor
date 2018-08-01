require "iteraptor/version"

# rubocop:disable Style/VariableNumber
# rubocop:disable Metrics/ModuleLength
module Iteraptor

  def self.included base
    raise "This module might be included into Enumerables only" unless base.ancestors.include? Enumerable
  end

  def iteraptor
    @__iteraptor__ ||= Iteraptor::Delegator.new(self)
  end

  %i[cada mapa].each do |m|
    define_method m do |key = nil, value = nil, **params, &λ|
      return enum_for(m, key, value, **params) unless λ
      return self if empty?

      send_to = H.enumerable_parent?(self)
      send_to && send("#{m}_in_#{send_to.name.downcase}", key || self, value, **params, &λ)
    end
  end

  def rechazar *filter, **params, &λ
    return self if empty?
    rechazar_o_escoger false, *filter, **params, &λ
  end

  def escoger *filter, **params, &λ
    return self if empty?
    rechazar_o_escoger true, *filter, **params, &λ
  end

  def compactar **params
    (is_a?(Array) ? compact : self).
      mapa(yield_all: true) do |_p, (k, v)|
        v.is_a?(Array) ? [k, v.compact] : [k, v]
      end.mapa(**params) do |parent, (k, v)|
        p = parent.split(H.iteraptor_delimiter(params)).last
        p.to_i.to_s != p && v.nil? ? nil : [k, v]
      end.tap do |this|
        break {} if this.empty? && is_a?(Hash)
      end
  end

  # rubocop:disable Style/Alias
  alias_method :segar, :escoger
  # rubocop:enable Style/Alias

  def aplanar **params
    return self if empty?
    cada(**params).with_object({}) do |(key, value), acc|
      key = key.join(H.iteraptor_delimiter(params)) if params[:full_parent]
      key = key.to_sym if params[:symbolize_keys]
      acc[key] = value unless value.is_a?(Enumerable)
      yield key, value if block_given?
    end
  end

  def recoger **params
    return self if empty?
    # rubocop:disable Style/MultilineBlockChain
    aplanar(**params).each_with_object(
      Hash.new { |h, k| h[k] = h.clone.clear }
    ) do |(k, v), acc|
      keys = k.to_s.split(H.iteraptor_delimiter(params))
      parent = keys[0..-2].reduce(acc){ |h, kk| h[kk] }
      parent[keys.last] = v
    end.mapa(yield_all: true, **params) do |_parent, (k, v)|
      [k, v]
    end
    # rubocop:enable Style/MultilineBlockChain
  end

  def plana_mapa **params
    return enum_for(:plana_mapa, delimiter: params[:delimiter], **params) unless block_given?
    return self if empty?

    cada(**params).with_object([]) do |(key, value), acc|
      key = key.join(H.iteraptor_delimiter(params)) if params[:full_parent]
      key = key.to_sym if params[:symbolize_keys]
      acc << yield(key, value) unless value.is_a?(Enumerable)
    end
  end

  private

  ##############################################################################
  ### cada
  CADA_PROC = lambda do |e, root, p, **params, &λ|
    case e
    when Iteraptor then e.cada(root, p, **params, &λ)
    when Enumerable then e.each(&λ.curry[p])
    end
  end

  def cada_in_array root = nil, parent = nil, **params, &λ
    cada_in_array_or_hash true, root, parent, **params, &λ
  end
  alias cada_in_enumerable cada_in_array

  def cada_in_hash root = nil, parent = nil, **params, &λ
    cada_in_array_or_hash false, root, parent, **params, &λ
  end

  def cada_in_array_or_hash in_array, root = nil, parent = nil, **params, &λ
    (in_array ? each_with_index : each).each do |k, v|
      k, v = v, k if in_array
      result = H.push_flatten_compact(parent, k)
      result = result.join(H.iteraptor_delimiter(params)) unless params[:full_parent]
      result.tap do |p|
        yield p, v
        CADA_PROC.call(v, root, p, **params, &λ)
      end
    end
  end

  ##############################################################################
  ### mapa
  # FIXME what happens if I return nil from mapa in array?
  # Params:
  #  - with_index
  #  - yield_all
  #  - symbolize_keys
  def mapa_in_array root = nil, parent = nil, **params, &λ
    map.with_index do |e, idx|
      p = H.push_flatten_compact(parent, idx)
      p = p.join(H.iteraptor_delimiter(params)) unless params[:full_parent]

      yielded =
        if !H.enumerable_parent?(e) || params[:yield_all]
          yield p, (params[:with_index] ? [idx.to_s, e] : e)
        else
          e
        end
      # allow blindly return [k, v] instead of check for an array instance
      #  when block arguments are matched as (k, v)
      yielded = yielded.last || yielded.first if
        yielded.is_a?(Array) && yielded.size == 2 && (yielded.last.nil? || yielded.first == e)

      case yielded
      when Iteraptor then yielded.mapa(root, p, **params, &λ)
      when Enumerable then yielded.map(&λ.curry[p])
      else yielded
      end
    end
  end
  alias mapa_in_enumerable mapa_in_array

  # Params:
  #  - yield_all
  #  - symbolize_keys
  def mapa_in_hash root = nil, parent = nil, **params, &λ
    map do |k, v|
      p = H.push_flatten_compact(parent, k)
      p = p.join(H.iteraptor_delimiter(params)) unless params[:full_parent]

      k, v = yield p, [k, v] if !v.is_a?(Enumerable) || params[:yield_all]

      case v
      when Iteraptor then [k, v.mapa(root, p, **params, &λ)]
      when Enumerable then [k, v.map(&λ.curry[p])]
      else k.nil? ? nil : [k, v]
      end
    end.compact.send(:to_hash_or_array, **params)
  end

  ##############################################################################
  ### helpers

  def to_hash_or_array **params
    # rubocop:disable Style/MultilineTernaryOperator
    # rubocop:disable Style/RescueModifier
    receiver =
      is_a?(Array) &&
        all? { |e| e.is_a?(Enumerable) && e.size == 2 } &&
        map(&:first).uniq.size == size ? (to_h rescue self) : self
    # rubocop:enable Style/RescueModifier

    return receiver unless receiver.is_a?(Hash)
    return receiver.values if receiver.keys.each_with_index.all? { |key, idx| key == idx.to_s }
    return receiver unless params[:symbolize_keys]

    receiver.map { |k, v| [H.safe_symbolize(k), v] }.to_h
    # rubocop:enable Style/MultilineTernaryOperator
  end

  HASH_TO_ARRAY_ERROR_MSG = %(undefined method `hash_to_array?' for "%s":%s).freeze
  def hash_to_hash_or_array
    raise NoMethodError, HASH_TO_ARRAY_ERROR_MSG % [inspect, self.class] unless is_a?(Hash)
  end

  ##############################################################################
  # filters
  def rechazar_o_escoger method, *filter, **params
    raise ArgumentError, "no filter given in call to #{method ? :escoger : :rechazar}" if filter.empty?

    plough = method ? :none? : :any?
    aplanar(**params).each_with_object({}) do |(key, value), acc|
      to_match = key.to_s.split(H.iteraptor_delimiter(params)) unless params[:full_parent]
      to_match = to_match.flat_map { |k| [k.to_s, k.to_s.to_sym] } if params[:soft_keys]

      next if filter.public_send(plough, &->(f){ to_match.any?(&f.method(:===)) })

      value = yield key, value if block_given?
      acc[key] = value
    end.recoger(**params)
  end

  ##############################################################################
  ### helpers
  module H
    class << self
      DELIMITER = '.'.freeze

      def safe_symbolize key
        key.respond_to?(:to_sym) ? key.to_sym : key
      end

      def iteraptor_delimiter(params)
        params[:delimiter] || DELIMITER
      end

      def push_flatten_compact array, tail
        case array
        when NilClass then [tail]
        when Array then array + [tail]
        else [array, tail]
        end.compact
      end

      def enumerable_parent?(receiver)
        [Hash, Array, Enumerable].detect(&receiver.method(:is_a?))
      end
    end
  end
end

require 'iteraptor/greedy'
require 'iteraptor/delegator'
