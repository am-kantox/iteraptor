module Iteraptor
  def attach_to klazz
    klazz.send :include, Iteraptor
  end
  module_function :attach_to

  [Array, Hash].each { |c| Iteraptor.attach_to c }
end
