module KUBETWIN
  class PodTopologySpreadConstraint
    # config example
    DEFAULT_CONFIG = {
      maxSkew: 2,
      topologyKey: "location_id",   # or "tier"
      whenUnsatisfiable: "DoNotSchedule",
      replicaSelector: "my_solver"
    }

    def self.run(nodes, _node_affinity = nil, opts = {})
      opts = {} unless opts.is_a?(Hash)

      max_skew = opts.fetch(:maxSkew, DEFAULT_CONFIG[:maxSkew])
      topology_key = opts.fetch(:topologyKey, DEFAULT_CONFIG[:topologyKey])
      when_unsatisfiable = opts.fetch(:whenUnsatisfiable, DEFAULT_CONFIG[:whenUnsatisfiable])
      replica_selector = opts.fetch(:replicaSelector, DEFAULT_CONFIG[:replicaSelector])

      puts "[Scheduler] Starting PodTopologySpreadConstraint with configuration: maxSkew=#{max_skew}, topologyKey=#{topology_key}, whenUnsatisfiable=#{when_unsatisfiable}, replicaSelector='#{replica_selector}'"

      existing_pods = build_existing_pods(nodes)

      pod_counts = count_matching_pods_per_domain(existing_pods, replica_selector, topology_key)
      #puts "[Scheduler] Pod counts per domain: #{pod_counts}"

      filtered_nodes = nodes.select do |entry|
        node = entry[:node]

        domain = node_topology_value(entry, topology_key)
        if domain.nil?
          #puts "[Scheduler] Skipping node #{node.node_id} missing topology key '#{topology_key}'"
          next false
        end

        domain_pod_count = pod_counts[domain] || 0
        new_skew = compute_skew(domain_pod_count, pod_counts.values)

        # puts "[Scheduler] Node #{node.node_id} in domain=#{domain} has pod_count=#{domain_pod_count} resulting in skew=#{new_skew}"

        if new_skew > max_skew
          if when_unsatisfiable == "ScheduleAnyway"
            # puts "[Scheduler] Node #{node.node_id} skew #{new_skew} above maxSkew #{max_skew}, but scheduling anyway"
            true
          else
            # puts "[Scheduler] Node #{node.node_id} skew #{new_skew} above maxSkew #{max_skew}, filtering out"
            false
          end
        else
          # puts "[Scheduler] Node #{node.node_id} skew #{new_skew} within maxSkew #{max_skew}, allowing"
          true
        end
      end

      puts "[Scheduler] PodTopologySpreadConstraint filtered nodes: #{filtered_nodes.map { |n| n[:node].node_id }}"
      filtered_nodes
    end

    private_class_method

    def self.build_existing_pods(nodes)
      existing_pods = []
      nodes.each do |entry|
        node = entry[:node]
        cluster = entry[:cluster]
        deployed_pods = entry[:deployed_pods] || []

        #puts "[Scheduler] Node #{node.node_id} in cluster #{cluster&.location_id || 'nil'} has deployed pods #{deployed_pods}"

        deployed_pods.each do |pod_name|
          unless pod_name.is_a?(String)
            #puts "[Scheduler] Pod name invalid, skipping"
            next
          end

          selector = extract_selector_from_name(pod_name)

          #puts "[Scheduler] Extracted selector '#{selector}' from pod name '#{pod_name}'"

          existing_pods << { node: node, cluster: cluster, selector: selector }
        end
      end
      puts "[Scheduler] Total existing pods gathered: #{existing_pods.size}"
      existing_pods
    end

    def self.extract_selector_from_name(pod_name)
      pod_name.sub(/_\d+$/, '')
    end

    def self.count_matching_pods_per_domain(existing_pods, replica_selector, topology_key)
      counts = Hash.new(0)
      existing_pods.each do |pod|
        next unless pod_matches_selector?(pod[:selector], replica_selector)

        domain = node_topology_value(pod, topology_key)  # pass whole pod hash
        counts[domain] += 1 if domain
      end
      counts
    end

    def self.pod_matches_selector?(pod_selector, replica_selector)
      return false if pod_selector.nil? || replica_selector.nil?
      pod_selector.start_with?(replica_selector)
    end

    def self.node_topology_value(entry, topology_key)
      cluster = entry[:cluster]
      return nil unless cluster

      case topology_key
      when "location_id"
        cluster.location_id if cluster.respond_to?(:location_id)
      when "tier"
        cluster.tier if cluster.respond_to?(:tier)
      else
        nil
      end
    end

    def self.compute_skew(domain_count, all_counts)
      min_count = all_counts.min || 0
      (domain_count + 1) - min_count  # +1 for placing pod here
    end
  end
end
