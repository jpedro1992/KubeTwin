#!/bin/bash

# Define testing variables here
TEST="fc_img_rec_random_bursts_15min.conf"
BASE_DIR="experiments/fog-cloud/img_rec/random_bursts_15min"

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
REPEAT=10

for ((i=1; i<=REPEAT; i++)); do
    if [ ! -d "$BASE_DIR" ]; then
        echo "Creating base directory: $BASE_DIR"
        mkdir -p "$BASE_DIR"
    fi

    TEST_DIR="$BASE_DIR/run_$i"
    if [ ! -d "$TEST_DIR" ]; then
        echo "Creating test directory: $TEST_DIR"
        mkdir -p "$TEST_DIR"
    fi

    export KUBETWIN_SEED=$RANDOM

    echo "-------------- Starting Run $i----------------------"
    echo "-------------- Using Seed $KUBETWIN_SEED ----------------------"
    for STRATEGY in "${STRATEGIES[@]}"; do
        STRATEGY_LOWER_CASE=$(echo "$STRATEGY" | tr '[:upper:]' '[:lower:]')

        # Update the strategy in the config file
        sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST

        # Update the seed in the config file
        sed -i "s/seed 12345/seed $KUBETWIN_SEED/" examples/$TEST

        OUT_FILE="$TEST_DIR/$STRATEGY_LOWER_CASE.txt"
        # ensure file exists before redirect
        # touch "$OUT_FILE"

        echo "-------------- Running experiment with scheduling strategy: $STRATEGY ----------------------"
        bundle exec bin/kube_twin "examples/$TEST" > "$OUT_FILE"
    done
done