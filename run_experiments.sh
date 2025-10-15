#!/bin/bash

# Define testing variables here
TEST="cuttlefish_ramp_up_15min.conf"
BASE_DIR="experiments/cuttlefish/ramp_up_15min_v2"

STRATEGIES=(
  "BALANCED_WITH_TOPOLOGY"
  "BALANCED"
  "DIKTYO"
  "NODE_AFFINITY"
  "TRIMARAN_LOW_RISK"
  "TOPOLOGY_AWARE"
  "LEAST_ALLOCATABLE"
  "MOST_ALLOCATABLE"
  "RESOURCE_AVAILABILITY"
  "COST_AWARE"
  "DIKTYO_COST"
  "DIKTYO_RISK"
  "DIKTYO_TOPOLOGY"
)

# Number of repetitions
REPEAT=5

for ((i=1; i<=REPEAT; i++)); do
    TEST_DIR="$BASE_DIR/run_$i"
    mkdir -p "$TEST_DIR"
    echo "-------------- Starting Run $i----------------------"
    for STRATEGY in "${STRATEGIES[@]}"; do
        sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
        echo "-------------- Running experiment with scheduling strategy: $STRATEGY ----------------------"
        bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/${STRATEGY,,}.txt"
    done
done