#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <direct.h>
#include <windows.h>
#include <Shlwapi.h>
#include <io.h>
#include <process.h>
#define F_OK 0
#pragma comment(lib, "shlwapi.lib")

#include "dotnet/tools/common/manifest.h"

extern const char * Exe;
extern const char * Nunit;



static void RunExe(const char *manifestDir, int argc, char **argv) {
	char fullpath[64*1024];
	char **args;
	int i, c;
    int test = strlen(Nunit) > 0;
	char runnerfullpath[64*1024];

	getcwd(fullpath, sizeof(fullpath));
	printf("cwd %s\n", fullpath);

	/* Find Exe's real path */
	const char *found = strrchr(Exe, '/');
	if (found == NULL) {
		found = Exe;
	} else {
		++found;
	}

	c = argc+2;
	if (test) c = c + 2;
	args = malloc( (c) * sizeof(char*));
	c = 0;
	if (test) {
		sprintf(fullpath, "%s/xunit.console.dll_exe.exe", manifestDir);
		args[c++] = strdup(fullpath);
	}
	sprintf(fullpath, "%s/%s", manifestDir, found);
	args[c++] = strdup(fullpath);
	if (test) {
		args[c++] = "-xml";
		sprintf(fullpath, "%s", getenv("XML_OUTPUT_FILE"));
		args[c++] = strdup(fullpath);
	}
	for(i = 1; i < argc; ++i) {
		args[c++] = argv[i];
	}
	args[c] = NULL;
	i = _spawnvp(_P_WAIT, args[0], args);
	if (i != 0) {
		printf("Couldn't execute %s or returned status code != 0\n", fullpath);
		exit(-1);				
	}
}


int main(int argc, char *argv[], char *envp[])
{
	const char *manifestDir;
	char buffer[64*1024];
    int test = strlen(Nunit) > 0;

	printf("Launcher running %s (%s)\n", Exe, Nunit);
	if (strlen(Exe) > 32*1024) {
		printf("File path %s too long\n", Exe);
		return -1;
	}
	manifestDir = GetManifestDir();
	ReadManifest(manifestDir);
	LinkFiles(manifestDir);
	RunExe(manifestDir, argc, argv);

	return 0;
}