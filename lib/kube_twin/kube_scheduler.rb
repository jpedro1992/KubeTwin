require_relative './scheduling_plugins/strategies/deployment_strategies'

module KUBETWIN
  # the scheduler selects the nodes where to allocate pods
  class KubeScheduler
    # this class is inspired by the concepts described in here
    # here we ned a reference to the cluster
    def initialize(clusters, latency_manager)
      @clusters = clusters
      @latency_manager = latency_manager
      @all_nodes = []
      @filtered_nodes = []
      @filter_plugins = []
      @score_plugins = []
    end

    # Register filtering plugins
    def register_filter_plugin(plugin_proc)
      @filter_plugins << plugin_proc
    end

    # Register scoring plugins
    def register_score_plugin(plugin_proc)
      @score_plugins << plugin_proc
    end

    # Clear all registered filter plugins
    def clear_filters()
      @filter_plugins.clear
    end

    # Clear all registered score plugins
    def clear_scores()
      @score_plugins.clear
    end

    # information regarding requirements are available using the pod class
    def get_node(req_cpu, req_mem, node_affinity, selector, dependencies)
      # get the requirements (we should specify at least a requirement here,
      # CPU percentage)
      # filter available nodes
      # this should return a candidate node
      puts "[Scheduler] ---- Pod Scheduling Decision ----"
      puts "[Scheduler] Pod requirements - CPU: #{req_cpu}, MEM: #{req_mem}, NodeAffinity: #{node_affinity}, Selector: #{selector}, Dependencies: #{dependencies}"
      filter(req_cpu, req_mem, selector, dependencies)
      score(node_affinity)
    end

    def get_node_from_cluster(req_cpu, req_mem, cluster_id, selector, dependencies)
      puts "[Scheduler] ---- Pod Scheduling Decision ----"
      puts "[Scheduler] Pod requirements - CPU: #{req_cpu}, MEM: #{req_mem}, NodeAffinity: #{node_affinity}, Selector: #{selector}, Dependencies: #{dependencies}"
      filter(req_cpu, req_mem, selector, dependencies)
      # puts "Filtered nodes: #{@filtered_nodes.length} for cluster_id: #{cluster_id}"
      # filter the nodes by cluster_id
      if cluster_id == :none
        score(nil) # random cluster
      else
        # puts "Filtering nodes for cluster_id: #{cluster_id}"
        node = @filtered_nodes.select! { |n| n[:cluster_id] == cluster_id }
        return score(nil) if node.empty?

        # puts "No nodes available for cluster_id: #{cluster_id} with requirements: #{requirements_cpu} #{requirements_mem}"
        # random cluster

        # puts "Found node for cluster_id: #{cluster_id} with requirements: #{requirements_cpu} #{requirements_mem}"
        node[0][:node] # .first[:node]
      end
      # score(nil)
    end

    private

    # Main filter function
    def filter(req_cpu, req_mem, selector, dependencies)
      # reset filtered nodes --- do we need to call delete here?
      puts "[Scheduler] Starting Filter function..."
      nodes = []
      # here we could implement different policies
      # puts "Clusters: #{@clusters}"
      @clusters.values.each do |c|
        raise 'Ranking nodes from a nil cluster' if c.nil?
        c.nodes.values.each do |node|
          # puts "[Scheduler] node: #{node.inspect}"
          nodes << {node: node,
                    cluster: c,
                    cluster_id: c.cluster_id,
                    tier: c.tier,
                    price: c.fixed_hourly_cost_cpu,
                    requested_resources: node.requested_resources,
                    cpu_hourly_cost: c.fixed_hourly_cost_cpu,
                    mem_hourly_cost: c.fixed_hourly_cost_memory,
                    req_cpu: req_cpu,
                    req_mem: req_mem,
                    pod_to_deploy_selector: selector,
                    pod_dependencies: dependencies,
                    latency_manager: @latency_manager,
                    deployed_pods: node.pod_name_list,
                    deployed_pods_id_list: node.pod_id_list,
                    number_deployed_pods: node.pod_id_list.length
                    }
        end
      end

      @all_nodes = nodes

      # before_filtering_info = nodes.map do |entry|
      #  node = entry[:node]
      #  {
      #    node_id: node.node_id,
          # cluster_id: entry[:cluster_id],
          # tier: entry[:tier],
          # price: entry[:price],
          # requested_resources: node.requested_resources,
          # cpu_hourly_cost: entry[:cpu_hourly_cost],
          # mem_hourly_cost: entry[:mem_hourly_cost],
          # req_cpu: entry[:req_cpu],
          # req_mem: entry[:req_mem],
          # pod_to_deploy_selector: entry[:pod_to_deploy_selector],
          # pod_dependencies: entry[:pod_dependencies],
      #   deployed_pods: entry[:deployed_pods],
          # deployed_pods_id_list: entry[:deployed_pods_id_list],
          # number_deployed_pods: entry[:number_deployed_pods],
      #   }
      #end
      #puts "[Scheduler] Nodes: #{JSON.pretty_generate(before_filtering_info)}"

      # Apply all registered filter plugins in sequence
      @filter_plugins.each do |plugin|
        nodes = plugin.call(nodes, req_cpu, req_mem)
      end

      # filtered_info = nodes.map do |entry|
      #     node = entry[:node]
      #     {
      #         node_id: node.node_id,
              # cluster_id: entry[:cluster_id],
              # tier: entry[:tier],
              # price: entry[:price],
              # requested_resources: node.requested_resources,
              # cpu_hourly_cost: entry[:cpu_hourly_cost],
              # mem_hourly_cost: entry[:mem_hourly_cost],
              # req_cpu: entry[:req_cpu],
              # req_mem: entry[:req_mem],
              # pod_to_deploy_selector: entry[:pod_to_deploy_selector],
              # pod_dependencies: entry[:pod_dependencies],
      #        deployed_pods: entry[:deployed_pods],
              # deployed_pods_id_list: entry[:deployed_pods_id_list],
              # number_deployed_pods: entry[:number_deployed_pods],
      #     }
      #   end
      # puts "[Scheduler] FilteredNodes: #{JSON.pretty_generate(filtered_info)}"

      @filtered_nodes = nodes
    end

    # Main scoring function
    def score(node_affinity)
      puts "[Scheduler] Starting Score function..."
      # Run all score plugins; collect array of node scores from each plugin
      all_plugin_scores = @score_plugins.map { |plugin| plugin.call(@filtered_nodes, @all_nodes, node_affinity) }

      # Initialize combined scores map: node => total score
      combined_scores = Hash.new(0)

      all_plugin_scores.each do |plugin_scores|
        plugin_scores.each do |entry|
          combined_scores[entry[:node]] += entry[:score]
        end
      end

      # Normalize combined scores to 0-100
      min_score = combined_scores.values.min || 0
      max_score = combined_scores.values.max || 1  # avoid division by zero

      puts "[Scheduler] Normalizing scores..."

      normalized_scores = combined_scores.map do |node, score|
        normalized = if max_score == min_score
                       100
                     else
                       ((score - min_score).to_f / (max_score - min_score)) * 100
                     end
        puts "[Scheduler] Node: #{node.node_id} - Raw Score: #{score.round(2)} - Normalized Score: #{normalized.round(2)}"

        { node: node, score: normalized }
      end

      # Sort nodes descending by normalized score
      sorted = normalized_scores.sort_by { |e| -e[:score] }

      # Create a readable string with node IDs and scores
      # score_summary = sorted.map do |entry|
      #  node_id = entry[:node].node_id
      #  score = entry[:score].round(2)
      #  "n_id: #{node_id}, score: #{score}"
      #end.join(" | ")

      # puts "[Scheduler] Normalized Scores for pod: #{score_summary}"
      puts "[Scheduler] --------------------------------\n"

      # Return best node or nil if none
      sorted.empty? ? nil : sorted.first[:node]
    end
  end
end


