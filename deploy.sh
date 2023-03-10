#!/bin/bash

commit_log=`date`
if [ ! -n $1 ];then
  commit_log=$1
fi

git pull origin master

git add .
git commit -m "$commit_log"
git push origin master

echo "开始更新文档"
ssh root@huawei << EOM
  cd /data/pig4cloud/mate-doc && git pull origin master
EOM
echo "部署成功"
