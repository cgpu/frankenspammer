// If gs:// or s3:// or https://, else it's local
fileSystem = params.dataLocation.contains(':') ? params.dataLocation.split(':')[0] : 'local'

// Header log info
log.info "\nPARAMETERS SUMMARY"
log.info "mainScript                            : ${params.mainScript}"
log.info "config                                : ${params.config}"
log.info "fileSystem                            : ${fileSystem}"
log.info "dataLocation                          : ${params.dataLocation}"
log.info "fileSuffix                            : ${params.fileSuffix}"
log.info "repsProcessA                          : ${params.repsProcessA}"
log.info "processAWriteToDiskMb                 : ${params.processAWriteToDiskMb}"
log.info "processATimeRange                     : ${params.processATimeRange}"
log.info "filesProcessA                         : ${params.filesProcessA}"
log.info "processATimeBetweenFileCreationInSecs : ${params.processATimeBetweenFileCreationInSecs}"
log.info "processBTimeRange                     : ${params.processBTimeRange}"
log.info "processBWriteToDiskMb                 : ${params.processBWriteToDiskMb}"
log.info "processCTimeRange                     : ${params.processCTimeRange}"
log.info "processDTimeRange                     : ${params.processDTimeRange}"
log.info "output                                : ${params.output}"
log.info "echo                                  : ${params.echo}"
log.info "cpus                                  : ${params.cpus}"
log.info "processA_cpus                         : ${params.processA_cpus}"
log.info "errorStrategy                         : ${params.errorStrategy}"
log.info "container                             : ${params.container}"
log.info "maxForks                              : ${params.maxForks}"
log.info "queueSize                             : ${params.queueSize}"
log.info "executor                              : ${params.executor}"
log.info "pre-script                            : ${params.pre_script}"
log.info "post-script                           : ${params.post_script}"
log.info "save-script                           : ${params.save_script}"
log.info "optional-log-file-pattern             : *${params.optional_log_pattern}*"

if(params.executor == 'awsbatch') {
log.info "aws_batch_cliPath                     : ${params.aws_batch_cliPath}"
log.info "aws_batch_fetchInstanceType           : ${params.aws_batch_fetchInstanceType}"
log.info "aws_batch_process_queue               : ${params.aws_batch_process_queue}"
log.info "aws_batch_docker_run_options          : ${params.aws_batch_docker_run_options}"
}
if(params.config == 'conf/aws_ignite.config') {
log.info "cloud_autoscale_enabled          : ${params.cloud_autoscale_enabled}"
log.info "cloud.autoscale.enabled          : cloud.autoscale.enabled"
log.info "cloud_autoscale_max_instances    : ${params.cloud_autoscale_max_instances}"
log.info "cloud.autoscale.maxInstances     : cloud.autoscale.maxInstances "
}
if(params.executor == 'google-lifesciences') {
log.info "gls_bootDiskSize                      : ${params.gls_bootDiskSize}"
log.info "gls_preemptible                       : ${params.gls_preemptible}"
log.info "gls_usePrivateAddress                 : ${params.gls_usePrivateAddress}"
log.info "zone                                  : ${params.zone}"
log.info "network                               : ${params.network}"
log.info "subnetwork                            : ${params.subnetwork}"
log.info "lifeSciences.usePrivateAddress        : ${params.gls_usePrivateAddress}"
log.info "google.lifeSciences.sshDaemon         : ${params.gls_sshDaemon}"
}
log.info ""

numberRepetitionsForProcessA = params.repsProcessA
numberFilesForProcessA = params.filesProcessA
processAWriteToDiskMb = params.processAWriteToDiskMb
processAInput = Channel.from([1] * numberRepetitionsForProcessA)
processAInputFiles = Channel.fromPath("${params.dataLocation}/**${params.fileSuffix}").take( numberRepetitionsForProcessA )

process processA {
	publishDir "${params.output}/${task.hash}/", mode: 'copy'
	tag "cpus: ${task.cpus}, cloud storage: ${cloud_storage_file}"

	input:
	val x from processAInput
	file(a_file) from processAInputFiles

	output:
	val x into processAOutput
	val x into processCInput
	val x into processDInput
	file "*.txt"
	file("command-logs") optional true

	script:
	"""
	# Simulate the time the processes takes to finish
	pwd=`basename \${PWD} | cut -c1-6`
	echo \$pwd
	timeToWait=\$(shuf -i ${params.processATimeRange} -n 1)
	for i in {1..${numberFilesForProcessA}};
	do echo test > "\${pwd}"_file_\${i}.txt
	sleep ${params.processATimeBetweenFileCreationInSecs}
	done;
	sleep \$timeToWait
	echo "task cpus: ${task.cpus}"

	${params.save_script}
	"""
}

process processB {

	input:
	val x from processAOutput
	publishDir "${params.outdir}/debug-logs/${task.process}/${task.hash}", mode: "copy", pattern: "${params.optional_log_pattern}"

	output:
	file("*${params.optional_log_pattern}*") optional true

	"""
	${params.pre_script}
	
    	# Simulate the time the processes takes to finish
    	timeToWait=\$(shuf -i ${params.processBTimeRange} -n 1)
    	sleep \$timeToWait
	dd if=/dev/urandom of=newfile bs=1M count=${params.processBWriteToDiskMb}
	
	${params.post_script}
	"""
}

process processC {

	input: 
	val x from processCInput

	"""
    	# Simulate the time the processes takes to finish
   	timeToWait=\$(shuf -i ${params.processCTimeRange} -n 1)
   	sleep \$timeToWait
	"""
}


process processD {

	input: 
	val x from processDInput

	"""
    	# Simulate the time the processes takes to finish
    	timeToWait=\$(shuf -i ${params.processDTimeRange} -n 1)
    	sleep \$timeToWait
	"""
}
