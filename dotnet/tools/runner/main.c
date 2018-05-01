#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef _MSC_VER
#include <direct.h>
#include <windows.h>
#include <Shlwapi.h>
#include <io.h>
#define F_OK 0
#pragma comment(lib, "shlwapi.lib")
#else
#include <unistd.h>
#include <errno.h>
#endif

extern const char * Exe;

struct Entry {
	const char *Key;
	const char *Path;
	const struct Entry* Next; 
};

struct Entry* g_Entries = NULL;

static void ReadManifest(const char *manifestDir)
{
	char buffer[64*1024];
	FILE *f;
	char *p;
	int line = 0;
	struct Entry *entry;

	strcpy(buffer, manifestDir);
	strcat(buffer, "/MANIFEST");
	/* read manifest file */
	f = fopen(buffer, "r");
	if (f == NULL) {
		p = getcwd(buffer, sizeof(buffer));
		printf("Can't open file MANIFEST in %s\n", p);
		exit(-1);
	}
	while (fgets(buffer, sizeof(buffer), f) != NULL ) 
	{
		++line;
		p = strchr(buffer, '\n');
		if (p != NULL) 
			*p = '\0';
		p = strchr(buffer, '\r');
		if (p != NULL) 
			*p = '\0';
			
		p = strchr(buffer, ' ');
		if (p == NULL) {
			printf("Line %d is malformatted (no space)\n", line);
			exit(-1);			
		}
		*p = '\0';
		entry = (struct Entry*) malloc(sizeof(struct Entry));
		entry->Key = strdup(buffer);
		entry->Path = strdup(p+1);
		entry->Next = g_Entries;
		g_Entries = entry;
	}
	fclose (f);
}

#ifdef _MSC_VER
static void LinkFiles(const char *manifestDir) {
	const struct Entry *p = g_Entries;
	const char *basename;
	BOOL result;
	DWORD error;
	DWORD flag;
	char toCreate[64*1024];

	while(p != NULL) {
		basename = strrchr(p->Key, '/');
		if (basename == NULL)
			basename = p->Key;
		else 
			++basename;

		sprintf(toCreate, "%s/%s", manifestDir, basename);

		/* Check if destination file exists */
		if (!PathFileExists(p->Path)) {
			printf("File %s does not exist\n", p->Path);
			exit(-1);			
		}

		flag = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
		retry:
		result = CreateSymbolicLink(toCreate, p->Path, flag);
		if (!result) {
			error = GetLastError();
			if (error == 87 && flag!=0) {
				printf("SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE seems not supported\n");
				flag = 0;
				goto retry;
			}
			if (error != ERROR_ALREADY_EXISTS) {
				printf("Error %d on linking %s to %s\n", error, toCreate, p->Path);
				exit(-1);
			}
		}
		p = p->Next;
	}
}
#else
static void LinkFiles(const char *manifestDir) {
	const struct Entry *p = g_Entries;
	const char *basename;
	int result, error;
	char toCreate[64*1024];

	while(p != NULL) {
		basename = strrchr(p->Key, '/');
		if (basename == NULL)
			basename = p->Key;
		else 
			++basename;

		/* Check if destination file exists */
		if (access(p->Path, F_OK)==-1) {
			printf("File %s does not exist\n", p->Path);
			exit(-1);			
		}

		sprintf(toCreate, "%s/%s", manifestDir, basename);

		result = symlink(p->Path, toCreate);
		if (result!=0) {
			error = errno;
			if (error != EEXIST) {
				printf("Error %d on linking %s to %s\n", error, toCreate, p->Path);
				exit(-1);
			}
		}
		p = p->Next;
	}
}
#endif

static void RunExe(const char *manifestDir, int argc, char **argv) {
	char fullpath[64*1024];
	char **args;
	int i;

#ifndef _MSC_VER
	char monofullpath[64*1024];
#endif
	/* Find Exe's real path */
	const char *found = strrchr(Exe, '/');
	if (found == NULL) {
		found = Exe;
	} else {
		++found;
	}
#ifdef _MSC_VER
	sprintf(fullpath, "%s/%s", manifestDir, found);
	args = malloc( (argc) * sizeof(char*));
	args[0] = fullpath;
	for(i = 1; i < argc; ++i) {
		args[i] = argv[i];
	}
	args[i] = NULL;
	if (execvp(fullpath, args) == -1) {
		printf("Couldn't execute %s\n", fullpath);
		exit(-1);				
	}
#else
	sprintf(monofullpath, "%s/mono", manifestDir);
	sprintf(fullpath, "%s/%s", manifestDir, found);

	args = malloc( (argc+1) * sizeof(char*));
	args[0] = monofullpath;
	args[1] = fullpath;
	for(i = 1; i < argc; ++i) {
		args[i+1] = argv[i];
	}
	args[i+1] = NULL;

	if (execvp(monofullpath, args) == -1) {
		printf("Couldn't execute %s, (%d)\n", found, errno);
		exit(-1);				
	}
#endif
}

/* I didn't find an easy way to locate MANIFEST file. 
   Until now, I have identified the following cases:
   1. Current directory (run on Windows).
   2. Parrent directory (run on Linux and osx).
   3. <currentdir>/<launcher>.runfiles (when used as a tool and launcher is this program)
   This function tries to locate the MANIFEST file and returns
   an absolute path to directory with it.
*/
const char *GetManifestDir() {
	static char buffer[64*1024];
	char *p;
	p = getcwd(buffer, sizeof(buffer));
	if (access("MANIFEST", F_OK)!=-1)
		return buffer;

	strcat(buffer, "/../MANIFEST");
	if (access(buffer, F_OK)!=-1) {
		p = strrchr(buffer, '/');
		*(p+1) = '\0';
		return buffer;
	}

	p = getcwd(buffer, sizeof(buffer));
	strcat(buffer, "/");
	strcat(buffer, Exe);
	/* We have to convert Exe name to this launcher name (by removing _exe suffix and possibly .exe 
	   on non-Windows platforms) */
	p = strrchr(buffer, '_');
	#ifdef _MSC_VER
	strcpy(p, p+4);
	#else
	strcpy(p, p+8);
	#endif	
	strcat(buffer, ".runfiles/MANIFEST");
	printf("Checking %s\n", buffer);
	if (access(buffer, F_OK)!=-1) {
		p = strrchr(buffer, '/');
		*(p+1) = '\0';
		return buffer;
	}
	
	printf("Couldn't find MANIFEST file\n");
	exit(-1);
}

int main(int argc, char *argv[], char *envp[])
{
	const char *manifestDir;
	printf("Launcher running %s\n", Exe);
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