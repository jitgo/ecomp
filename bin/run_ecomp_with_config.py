#!/usr/bin/python
import sys
import os
import subprocess

def printUsage():
	print "Usage: "+os.path.basename(sys.argv[0])+" git_repository_url"

def svnEarliestRevision(repo):
	proc = subprocess.Popen(["svn", "log", "-r1:HEAD", "-l", "1", repo], stdout=subprocess.PIPE)
	proc.wait()
	if proc.returncode != 0:
		print "Failed to get starting revision for SVN repository"
		sys.exit(-1)

	proc.stdout.readline()
	revision = proc.stdout.readline().split(' ')[0].strip('r')
	return revision

def svnLatestRevision(repo):
	proc = subprocess.Popen(["svn", "log", "-l", "1", repo], stdout=subprocess.PIPE)
	proc.wait()
	if proc.returncode != 0:
		print "Failed to get ending revision for SVN repository"
		sys.exit(-1)

	proc.stdout.readline()
	revision = proc.stdout.readline().split(' ')[0].strip('r')
	return revision

def gitSvnCheckout(repo, outputDirectory):
	startRevision = svnEarliestRevision(repo)
	endRevision = svnLatestRevision(repo)
	if subprocess.call(["git", "svn", "clone", "-r"+startRevision+":"+endRevision, repo, outputDirectory]):
		print "Could not git svn clone the project"
		sys.exit(-1)

def gitSvnRebase(projectDir):
	if subprocess.call(["git", "checkout", "-f", "master"]) != 0:
		print "There were errors checking out master"
		sys.exit(-1)
	if subprocess.call(["git", "clean", "-x", "-f", "-d"]) != 0:
		print "There were errors cleaning the project working directory"
		sys.exit(-1)
	if subprocess.call(["git", "svn", "rebase"]):
		print "There were errors git svn rebasing the project"
		sys.exit(-1)

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
	if (repo.endswith(".git")):
		return os.path.basename(repo)[:-4]
	else:
		return os.path.basename(repo)

def constructMetricsCommand(reportDirectory, inclusionList, exclusionList):
	return ["metrics", reportDirectory] + inclusionList + exclusionList

if len(sys.argv) != 2:
	printUsage()
	sys.exit(-1)


gitRepoUrl = sys.argv[1]
projectName = projectNameFromRepositoryUrl(gitRepoUrl)
projectDirectory = projectName + ".ecomp"
reportDirectory = "../" + projectName + ".ecompreport"

print "Project name: " + projectName
print "Project checkout directory: " + projectDirectory
print "Report directory: " + reportDirectory

if not gitRepoUrl.startswith("https://repo.dev.bbc.co.uk"):
	print "Using git repository '" + gitRepoUrl + "'"
	if not os.path.exists(projectDirectory):
		print "Attempting to clone " + gitRepoUrl
		gitCheckout(gitRepoUrl, projectDirectory)
		os.chdir(projectDirectory)
	else:
		os.chdir(projectDirectory)
		print "Pulling latest changes from " + gitRepoUrl
		gitUpdate(projectDirectory)
else:
	print "Using SVN repository '" + gitRepoUrl + "'"
	if not os.path.exists(projectDirectory):
		print "Attempting to svn-git clone " + gitRepoUrl
		gitSvnCheckout(gitRepoUrl, projectDirectory)
		os.chdir(projectDirectory)
	else:
		os.chdir(projectDirectory)
		print "SVN rebasing latest changes from " + gitRepoUrl
		gitSvnRebase(projectDirectory)




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




