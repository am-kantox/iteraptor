require "iteraptor/version"

module Iteraptor
  DELIMITER = '.'.freeze

  def self.included base
    raise "This module might be included into Enumerables only" unless base.ancestors.include? Enumerable
  end

  def cada root = nil, parent = nil
    return enum_for(:cada) unless block_given?

    root ||= self

    case self
    when Hash then cada_in_hash(root, parent, &Proc.new)
    when Array then cada_in_array(root, parent, &Proc.new)
    else cada_in_enumerable(root, parent, &Proc.new)
    end
  end

  def mapa root = nil, parent = nil
    return enum_for(:mapa) unless block_given?

    root ||= self

    case self
    when Hash then mapa_in_hash(root, parent, &Proc.new)
    when Array then mapa_in_array(root, parent, &Proc.new)
    else mapa_in_enumerable(root, parent, &Proc.new)
    end
  end

  private

  ##############################################################################
  ### cada
  def cada_in_array root = nil, parent = nil
    each.with_index do |e, idx|
      yield(*[root, leaf?(e), parent, e])

      case e
      when Iteraptor then e.cada(root, [parent, idx].compact.join(DELIMITER), &Proc.new)
      when Enumerable then e.each(&Proc.new)
      end
    end
  end
  alias cada_in_enumerable cada_in_array

  def cada_in_hash root = nil, parent = nil
    each do |k, v|
      yield(*[root, leaf?(v), parent, [k, v]])

      case v
      when Iteraptor then v.cada(root, [parent, k].compact.join(DELIMITER), &Proc.new)
      when Enumerable then v.each(&Proc.new)
      end
    end
  end

  ##############################################################################
  ### mapa
  def mapa_in_array root = nil, parent = nil
    map.with_index do |e, idx|
      case e
      when Iteraptor then e.mapa(root, [parent, idx].compact.join(DELIMITER), &Proc.new)
      when Enumerable then e.map(&Proc.new)
      else yield(*[root, parent, e])
      end
    end
  end
  alias mapa_in_enumerable mapa_in_array

  def mapa_in_hash root = nil, parent = nil
    map do |k, v|
      case v
      when Iteraptor then [k, v.mapa(root, [parent, k].compact.join(DELIMITER), &Proc.new)]
      when Enumerable then [k, v.map(&Proc.new)]
      else yield(*[root, parent, [k, v]])
      end
    end.to_h
  end

  def leaf? e
    [Iteraptor, Enumerable].none? { |c| e.is_a? c }
  end

  [Array, Hash].each { |c| c.send :include, Iteraptor }
end
