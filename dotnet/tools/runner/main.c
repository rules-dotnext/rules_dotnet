#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef _MSC_VER
#include <windows.h>
#include <Shlwapi.h>
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

static void ReadManifest()
{
	char buffer[64*1024];
	FILE *f;
	char *p;
	int line = 0;
	struct Entry *entry;

	/* read manifest file */
	f = fopen("MANIFEST", "r");
	if (f == NULL) {
		getcwd(buffer, sizeof(buffer));
		printf("Can't open file MANIFEST in %s\n", buffer);
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
static void LinkFiles() {
	const struct Entry *p = g_Entries;
	const char *basename;
	BOOL result;
	DWORD error;
	DWORD flag;

	while(p != NULL) {
		basename = strrchr(p->Key, '/');
		if (basename == NULL)
			basename = p->Key;
		else 
			++basename;

		/* Check if destination file exists */
		if (!PathFileExists(p->Path)) {
			printf("File %s does not exist\n", p->Path);
			exit(-1);			
		}

		flag = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
		retry:
		result = CreateSymbolicLink(basename, p->Path, flag);
		if (!result) {
			error = GetLastError();
			if (error == 87 && flag!=0) {
				printf("SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE seems not supported\n");
				flag = 0;
				goto retry;
			}
			if (error != ERROR_ALREADY_EXISTS) {
				printf("Error %d on linking %s\n", error, p->Path);
				exit(-1);
			}
		}
		p = p->Next;
	}
}
#else
static void LinkFiles() {
	const struct Entry *p = g_Entries;
	const char *basename;
	int result, error;

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

		result = symlink(p->Path, basename);
		if (result!=0) {
			error = errno;
			if (error != EEXIST) {
				printf("Error %d on linking %s\n", error, p->Path);
				exit(-1);
			}
		}
		p = p->Next;
	}
}
#endif

static void RunExe() {
#ifndef _MSC_VER
	char actualpath[64*1024];
	char *path;
#endif
	/* Find Exe's real path */
	const char *found = strrchr(Exe, '/');
	if (found == NULL) {
		found = Exe;
	} else {
		++found;
	}
#ifdef _MSC_VER
	if (execl(found, found, NULL) == -1) {
		printf("Couldn't execute %s\n", found);
		exit(-1);				
	}
#else
	path = realpath("./mono", actualpath);
	if (path == NULL) {
		printf("Can't resolve ./mono path\n");
		exit(-1);						
	}
	if (execl(path, path, found, NULL) == -1) {
		printf("Couldn't execute %s, (%d)\n", found, errno);
		exit(-1);				
	}
#endif
}

int main(int argc, char *argv[], char *envp[])
{
#ifndef _MSC_VER
  /* I don't know, why it's needed on Linux. The current directory is one way down of .runfiles dir */
  chdir("..");
#endif
  printf("Launcher running %s\n", Exe);
  if (strlen(Exe) > 32*1024) {
	  printf("File path %s too long\n", Exe);
	  return -1;
  }
  ReadManifest();
  LinkFiles();
  RunExe();

  return 0;
}