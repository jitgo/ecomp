#!/usr/bin/python
import sys
import os
import subprocess

def printUsage():
	print "Usage: "+os.path.basename(sys.argv[0])+" git_repository_url"

def gitCheckout(repo, outputDirectory):
	if subprocess.call(["git", "clone", repo, outputDirectory]) != 0:
		print "There were errors cloning the project, please fix this before continuing"
		print "The command used to checkout the repository was:"
		print "git clone "+repo+" "+outputDirectory
		sys.exit(-1)

def gitUpdate(projectDir):
	if subprocess.call(["git", "checkout", "-f", "master"]) != 0:
		print "There were errors checking out master"
		sys.exit(-1)
	if subprocess.call(["git", "clean", "-x", "-f", "-d"]) != 0:
		print "There were errors cleaning the project working directory"
		sys.exit(-1)
	if subprocess.call(["git", "pull"]) != 0:
		print "There were errors updating the project, please fix this before continuing"
		sys.exit(-1)

def readFileContentsToList(fileName):
	returnList = []
	with open(fileName, "r") as openedFile:
		for line in openedFile:
			returnList.append(line.rstrip())
	return returnList

def projectNameFromRepositoryUrl(repo):
	return os.path.basename(repo)[:-4]

def constructMetricsCommand(reportDirectory, inclusionList, exclusionList):
	return ["metrics", reportDirectory] + inclusionList + exclusionList

if len(sys.argv) != 2:
	printUsage()
	sys.exit(-1)

gitRepoUrl=sys.argv[1]
projectName=projectNameFromRepositoryUrl(gitRepoUrl)
projectDirectory=projectName+".ecomp"
reportDirectory="../"+projectName+".ecompreport"

print "Using git repository '"+gitRepoUrl+"'"
print "Project name: "+ projectName
print "Project checkout directory: "+projectDirectory
print "Report directory: "+reportDirectory

if not os.path.exists(projectDirectory):
	print "Attempting to clone "+gitRepoUrl
	gitCheckout(gitRepoUrl, projectDirectory)
	os.chdir(projectDirectory)
else:
	os.chdir(projectDirectory)
	print "Pulling latest changes from "+gitRepoUrl
	gitUpdate(projectDirectory)

print "Parsing .ecompconfig"
if not os.path.exists(".ecompconfig"):
	print "There is no .ecompconfig, please create one and commit it before continuing"
	sys.exit(-1)

inclusionList = readFileContentsToList(".ecompconfig")
exclusionList = []
if os.path.exists(".ecompignore"):
	print "Parsing .ecompignore file for exclusion list"
	exclusionList = readFileContentsToList(".ecompignore")

if len(inclusionList) < 1:
	print "There were no file globs specified by .ecompconfig file"
	print "No report can be generated"
	sys.exit(-1)

print "Including files that match:"
for includedFile in inclusionList:
	print "+ "+includedFile

exclusionCommandLineList = []
if len(exclusionList) > 0:
	print "Excluding files that match:"
	for excludedFile in exclusionList:
		print "- "+excludedFile
		exclusionCommandLineList.append("-e")
		exclusionCommandLineList.append(excludedFile)

metricsCommand = constructMetricsCommand(reportDirectory, inclusionList, exclusionCommandLineList)

print "Running command: " + ' '.join(metricsCommand)
subprocess.call(metricsCommand)




