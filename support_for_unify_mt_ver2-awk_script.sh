#!/bin/bash

### USAGE
# ./hoge.sh
# if ClassNumber is not 9, you should edit "print $9"
# class_averages.star is made from autopick goodclasses selection job

id_list=$(cat class_averages.star | awk 'NF == 9 {print $9}' | awk '{if (NR == 1) {printf("%s", $0)} else {printf(",%s", $0)}}')
awk -v GoodClassId=$id_list -v border_score=0.5 -f hoge.awk ../../Class2D/sk_autopick/run_it025_data.star > ../../Class2D/sk_autopick/run_it025_data_unify.star
