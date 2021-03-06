#!/bin/bash

. ./cmd.sh
. ./path.sh

dir_2=exp/nnet3/lstm_lang_raw_cell_1024/egs
dir=exp/nnet3/lstm_lang_raw_cell_1024_dim5/egs
mkdir -p $dir

if true; then

 cmvn_opts
echo "--- cmvn_opts ---"
cp $dir_2/cmvn_opts $dir

# info
echo "--- info ---"
cp -rf $dir_2/info $dir

# egs in dir_2, output -> output2
echo "--- egs in dir_2, dim=4 -> dim=5 ---"
i=0
for egs in $dir_2/*egs $dir_2/*ark; do
  (
  nnet3-copy-egs ark:$egs ark,t:${egs}.output.txt || exit 1
  sed -i 's/dim=4/dim=5/g' ${egs}.output.txt
  base=`basename $egs`
  nnet3-copy-egs ark:${egs}.output.txt ark:$dir/$base || exit 1
  rm ${egs}.output.txt
  ) &
  i=$[i+1]
  if [ $i -eq 8 ]; then
    wait;
    i=0
  fi
done
wait;


exit 0;


# merge egs, output and output2
echo "--- merge egs, output and output2 ---"
#nnet3-shuffle-egs --srand=1 "ark:cat $dir_1/combine.egs $dir_2/combine.egs.output2 |" ark:$dir/combine.egs || exit 1
cp $dir_1/combine.egs $dir/combine_1.egs
cp $dir_2/combine.egs $dir/combine_2.egs # keep the name "output"
cat $dir_1/train_diagnostic.egs $dir_2/train_diagnostic.egs.output2 > $dir/train_diagnostic.egs
cat $dir_1/valid_diagnostic.egs $dir_2/valid_diagnostic.egs.output2 > $dir/valid_diagnostic.egs

# merge egs.*.ark
num_1=`cat $dir_1/info/num_archives`
num_2=`cat $dir_2/info/num_archives`
num=`cat $dir/info/num_archives`
num_1_p=1 # to process
num_2_p=1
num_p=1
i=0
while [ $num_p -le $num ]; do
  t=$[$RANDOM%2]
  # cp dir_1
  if [ $t -eq 0  -a  $num_1_p -le $num_1 ]; then
    ( cp $dir_1/egs.${num_1_p}.ark $dir/egs.${num_p}.ark ) &
    echo "$dir_1/egs.${num_1_p}.ark $dir/egs.${num_p}.ark"
    num_1_p=$[num_1_p + 1]
    num_p=$[num_p + 1]
    i=$[i+1]
  fi
  # cp dir_2
  if [ $t -eq 1  -a  $num_2_p -le $num_2 ]; then
    ( cp $dir_2/egs.${num_2_p}.ark.output2 $dir/egs.${num_p}.ark ) &
    echo "$dir_2/egs.${num_2_p}.ark.output2 $dir/egs.${num_p}.ark"
    num_2_p=$[num_2_p + 1]
    num_p=$[num_p + 1]
    i=$[i+1]
  fi

  if [ $i -eq 8 ]; then
    wait;
    i=0
  fi

done
wait;


exit 0;  # not egs level shuffle, just archive level



fi



num=`cat $dir/info/num_archives`
if [ $[$num%10] -eq 0 ]; then # 10 egs as a group to shuffle
  group=$[$num/10]
  even=0
else
  group=$[$num/10+1]
  even=1
for i in `seq $group`; do
    base=$[i*10-10]  # 0, 10, ...
    egs_list_r=
    egs_list_w=
  if [ $i -eq $group  -a  $even -eq 1 ]; then
    for j in `seq $[$num%10]`; do
      egs_list_r="$egs_list_r $dir/egs.$[$base+$j].ark"
      egs_list_w="$egs_list_w ark:$dir/egs.$[$base+$j].ark.new"
    done
    nnet3-shuffle-egs --srand=1 "ark:cat $egs_list_r |" ark:- | \
    nnet3-copy-egs ark:- $egs_list_w || exit 1
    echo "$egs_list_r ---------------- $egs_list_w"
  else
    for j in `seq 10`; do
      egs_list_r="$egs_list_r $dir/egs.$[$base+$j].ark"
      egs_list_w="$egs_list_w ark:$dir/egs.$[$base+$j].ark.new"
    done
    nnet3-shuffle-egs --srand=1 "ark:cat $egs_list_r |" ark:- | \
    nnet3-copy-egs ark:- $egs_list_w || exit 1
    echo "$egs_list_r ---------------- $egs_list_w"
  fi
done
 
fi # already done ---------------------

num=`cat $dir/info/num_archives`
for i in `seq $num`; do 
  mv $dir/egs.${i}.ark.new $dir/egs.${i}.ark
done
  

exit 0












