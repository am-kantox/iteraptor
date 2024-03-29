module Iteraptor
  class Delegator
    MAPPING = {
      each: :cada,
      map: :mapa,

      select: :escoger,
      reject: :rechazar,
      compact: :compactar,

      flatten: :aplanar,
      collect: :recoger,
      flat_map: :plana_mapa,

      bury!: :enterrar!
    }.freeze

    def initialize(receiver)
      @receiver = receiver
    end

    MAPPING.each do |m, delegate_to|
      define_method m do |*args, **kw, &λ|
        @receiver.send(delegate_to, *args, **kw, &λ)
      end
    end
  end
end
