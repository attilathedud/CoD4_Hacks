/*!
*   All code related to injection. This should probably be encapsulated in a class, but that's
*   why you don't program as a teenager.
*
*   Originally written on 2010/03/10 by attilathedud.
*/
#include <windows.h>

/*!
*   Start a process with a given path. The process is created suspended and needs 
*   to be resumed by the callee. Returns the process_info structure populated by CreateProcess.
*/
PROCESS_INFORMATION startProcess(char gamePath[256])
{
    char gameDir[256] = {0};
    PROCESS_INFORMATION pI = {0};
    STARTUPINFO sUI = {0};

    strcpy(gameDir, gamePath);
    for(int i = strlen(gameDir); gameDir[i] != '\\'; i--)
        gameDir[i] = 0;
    sUI.cb = sizeof(sUI);

    CreateProcess(gamePath, 0, 0, 0, false, CREATE_SUSPENDED | NORMAL_PRIORITY_CLASS, 0, gameDir, &sUI, &pI);
    
    return pI;
}

/*!
*   Our injection function works by the following process:
*
*   1. Allocate and write our dlls path into the process' memory space.
*   2. Create a thread inside COD4 that will invoke LoadLibrary along with a parameter to our dll's name
*       inside the process.
*/
bool inject(char* dll, PROCESS_INFORMATION pI)
{
    DWORD exitCode, thread;
    void *lpBaseAddress;

    if(!pI.hProcess)
        return false;

    // Allocate the space for our dll name inside the process.
    if(!(lpBaseAddress =  VirtualAllocEx(pI.hProcess, NULL, strlen(dll) + 1, MEM_COMMIT, PAGE_READWRITE)))
        return false;

    // Write our dll's name inside the process.
    WriteProcessMemory(pI.hProcess, lpBaseAddress, dll, strlen(dll)+1, NULL);

    // Create our thread that will invoke LoadLibrary on our dll name.
    thread = (DWORD)CreateRemoteThread(pI.hProcess, 0, 0, (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA"), lpBaseAddress,0, 0);
    WaitForSingleObject((void*)thread, INFINITE);
    GetExitCodeThread((void*)thread, &exitCode);
    
    if(!exitCode)
        return false;

    // Free the memory we allocated and close active handles.
    VirtualFreeEx(pI.hProcess, 0, strlen(dll)+1, MEM_DECOMMIT);
    CloseHandle((void*)thread);

    return true;
}
