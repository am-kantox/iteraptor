require "iteraptor/version"

module Iteraptor
  DELIMITER = '.'.freeze

  def self.included base
    raise "This module might be included into Enumerables only" unless base.ancestors.include? Enumerable
  end

  %i(cada mapa).each do |m|
    define_method m do |root = nil, parent = nil, &λ|
      return enum_for(m, root, parent) unless λ
      send_to = [Hash, Array, Enumerable].detect { |c| is_a? c }
      send_to && send("#{m}_in_#{send_to.name.downcase}", root || self, parent, &λ)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def segar filter
    return enum_for(:segar, filter) unless block_given?

    cada.with_object({}) do |(parent, element), memo|
      p = parent.split(DELIMITER)
      if case filter
         when String then p.include?(filter)
         when Symbol then p.include?(filter.to_s)
         when Regexp then p.any? { |key| key =~ filter }
         when Array then parent.include?(filter.map(&:to_s).join(DELIMITER))
         end
        yield parent, element
        memo[parent] = element
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  ##############################################################################
  ### cada
  def cada_in_array root = nil, parent = nil
    λ = Proc.new

    each.with_index do |e, idx|
      p = [parent, idx].compact.join(DELIMITER)

      yield p, e

      case e
      when Iteraptor then e.cada(root, p, &λ)
      when Enumerable then e.each(&λ.curry[p])
      end
    end
  end
  alias cada_in_enumerable cada_in_array

  def cada_in_hash root = nil, parent = nil
    λ = Proc.new

    each do |k, v|
      p = [parent, k].compact.join(DELIMITER)

      yield p, v

      case v
      when Iteraptor then v.cada(root, p, &λ)
      when Enumerable then v.each(&λ.curry[p])
      end
    end
  end

  ##############################################################################
  ### mapa
  def mapa_in_array root = nil, parent = nil
    λ = Proc.new

    map.with_index do |e, idx|
      p = [parent, idx].compact.join(DELIMITER)

      case e
      when Iteraptor then e.mapa(root, p, &λ)
      when Enumerable then e.map(&λ.curry[p])
      else yield p, e
      end
    end
  end
  alias mapa_in_enumerable mapa_in_array

  def mapa_in_hash root = nil, parent = nil
    λ = Proc.new

    map do |k, v|
      p = [parent, k].compact.join(DELIMITER)

      case v
      when Iteraptor then [k, v.mapa(root, p, &λ)]
      when Enumerable then [k, v.map(&λ.curry[p])]
      else yield p, [k, v]
      end
    end.to_h
  end

  ##############################################################################
  ### helpers
  def leaf? e
    [Iteraptor, Enumerable].none? { |c| e.is_a? c }
  end
end

require "iteraptor/greedy"
