module KUBETWIN
  # NodeAffinityScore plugin
  # Scores nodes based on whether they match the specified node affinity (tier)
  class NodeAffinityScore
    def self.run(nodes, node_affinity)
      # Compute scores based on node tier matching affinity
      result = nodes.map do |entry|
        score = (entry[:tier] == node_affinity) ? 100 : 0

        puts "[Scheduler] NodeAffinityScore: Node #{entry[:node].node_id} score: #{score.round(2)}"

        { node: entry[:node], score: score }
      end

      result
    end
  end
end

