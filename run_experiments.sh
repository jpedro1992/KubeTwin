#!/bin/bash

# bundle exec bin/kube_twin <other_config.conf> > <other_output.txt>
STRATEGY="BALANCED_WITH_TOPOLOGY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/balanced_with_topology.txt

STRATEGY="BALANCED"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/balanced.txt

STRATEGY="DIKTYO"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/diktyo.txt

STRATEGY="NODE_AFFINITY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/node_affinity.txt

STRATEGY="TRIMARAN_LOW_RISK"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/trimaran.txt

STRATEGY="TOPOLOGY_AWARE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/topology.txt

STRATEGY="LEAST_ALLOCATABLE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/least_allocatable.txt

STRATEGY="MOST_ALLOCATABLE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/most_allocatable.txt

STRATEGY="RESOURCE_AVAILABILITY"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/resource_availability.txt

STRATEGY="COST_AWARE"
sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/test_img_rec.conf
bundle exec bin/kube_twin examples/test_img_rec.conf > experiments/test_img/hpa/cost.txt