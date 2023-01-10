# Artifact Cruncher
Crunch artifacts found in Forensic Triage Images and ingest into a local hosted Splunk to enable searching and reporting.

* VM built using Vagrant and VirtualBox
* Parse and ingest logs from forensic triage images collected with CyLR

## Pre requisites
This projects requires the following minimum dependecies installed.
* Vagrant https://developer.hashicorp.com/vagrant/downloads
* Virtual Box https://www.virtualbox.org/wiki/Downloads

## Usage
```
git clone https://github.com/alexzorila/artifact-cruncher.git
cd artifact-cruncher
vagrant up
```
```
 ------------------------------------------------------------------------------
 Access Local Splunk via:

   Web Interface
     Url: https://192.168.56.105:8000
     User: admin
     Password: changeme

   CLI via SSH
     vagrant ssh
 ------------------------------------------------------------------------------
```
## Resources
* CyLR https://github.com/orlikoski/CyLR
* CDQR https://github.com/orlikoski/CDQR
* MFTECmd https://github.com/EricZimmerman/MFTECmd
* DetectionLab https://github.com/clong/detectionlab
* vagrant-splunk https://github.com/gallilama/vagrant-splunk
* Splunk https://www.splunk.com/en_us/download/splunk-enterprise.html
