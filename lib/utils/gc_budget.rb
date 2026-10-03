# frozen_string_literal: true

module Metanorma
  module Utils
    # Large metanorma compiles churn transients of hundreds of MB per
    # phase (macro rendering, XML cleanup, whole-document assembly) on
    # top of a multi-GB live set. The churn is malloc-side
    # (libxml/moxml/liquid/regexp), so the GC's heap-growth heuristics
    # fire too late under memory caps and the process dies thrashing.
    # Call gc_when_bloated! at phase boundaries: collect whenever
    # uncollected malloc has exceeded the budget.
    module GcBudget
      BUDGET_BYTES = 512 * (1 << 20)

      class << self
        def gc_when_bloated!
          GC.start if GC.stat(:malloc_increase_bytes) > BUDGET_BYTES
        end
      end
    end
  end
end
