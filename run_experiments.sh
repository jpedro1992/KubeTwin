#!/bin/bash

# Define testing variables here
TEST="test_img_rec_v3.conf"
TEST_DIR="experiments/test_img/hpa_v3"

# bundle exec bin/kube_twin <other_config.conf> > <other_output.txt>
STRATEGY="BALANCED_WITH_TOPOLOGY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/balanced_with_topology.txt"

STRATEGY="BALANCED"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/balanced.txt"

STRATEGY="DIKTYO"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/diktyo.txt"

STRATEGY="NODE_AFFINITY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/node_affinity.txt"

STRATEGY="TRIMARAN_LOW_RISK"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/trimaran.txt"

STRATEGY="TOPOLOGY_AWARE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/topology.txt"

STRATEGY="LEAST_ALLOCATABLE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/least_allocatable.txt"

STRATEGY="MOST_ALLOCATABLE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/most_allocatable.txt"

STRATEGY="RESOURCE_AVAILABILITY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/resource_availability.txt"

STRATEGY="COST_AWARE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/cost.txt"

STRATEGY="DIKTYO_COST"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/diktyo_cost.txt"

STRATEGY="DIKTYO_RISK"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/diktyo_risk.txt"

STRATEGY="DIKTYO_TOPOLOGY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$TEST
echo "--------------Running experiment with scheduling strategy: $STRATEGY----------------------"
bundle exec bin/kube_twin "examples/$TEST" > "$TEST_DIR/diktyo_topology.txt"