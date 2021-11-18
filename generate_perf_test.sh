#!/bin/bash

Log() {
  echo $1
  echo `date`:$1 >> ${outfile}
}

Usage() {
  Log "Usage: $(basename $0) <bootstrap_server> <driver> <workload_dir>"
  exit 1
}

curr_dir=$(dirname $0)

outfile=${curr_dir}/$(basename $0).log
touch ${outfile}

bootstrap_server=$1
driver=$2
workload_dir=$3

[ -z "${bootstrap_server}" ] && echo "bootstrap_server (arg1) is required. Exiting." && Usage
[ -z "${driver}" ] && echo "driver (arg2) is required. Exiting." && Usage
[ -z "${workload_dir}" ] && echo "workload_dir (arg3) is required. Exiting." && Usage

[ ! -f ${driver} ] && echo "${driver} does not exists. Exiting." && Usage
[ ! -d ${workload_dir} ] && echo "${workload_dir} does not exists. Exiting." && Usage

mkdir -p ${curr_dir}/bak

Log "Using Bootstrap Server: ${bootstrap_server}"
Log "Using Driver: ${driver}"
Log "Using Workload Dir: ${workload_dir}"

for file in `ls -1 ${workload_dir}/*.yaml`
do
  Log "Started workload ${file} ..."

  workload=${file}
  scenario=`basename ${workload} | sed 's/.yaml$//g'`

  json_wild_output="${scenario}-Kafka"

  mv ${scenario}* ${curr_dir}/bak 2> /dev/null

  ${curr_dir}/bin/benchmark --drivers ${driver} ${workload}
  json_output=`ls -1 ${json_wild_output}*.json`
  Log "JSON wildcard ${json_wild_output}"
  Log "JSON output file ${json_output}"

  Log "Deleting topics from workload ${workload} ..."
  for topic in `kafka-topics --bootstrap-server ${bootstrap_server} --list|grep "^test-topic-"`
  do
    kafka-topics --bootstrap-server ${bootstrap_server} -delete --topic $topic
  done

  Log "Creating charts for workload ${workload} ..."
  python3 ${curr_dir}/bin/create_charts.py ${json_output}

  Log "Cooling down after workload ${workload} for 20 seconds ..."
  sleep 20
done
Log "Completed Run"
