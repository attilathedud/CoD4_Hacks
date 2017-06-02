/*!
*   The inject function takes a null-terminated string representing the path of the dll to be loaded
*   and the process_info of the target process.
*/
bool inject(char*, PROCESS_INFORMATION);

/*!
*   Start a target process with the given path.
*/
PROCESS_INFORMATION startProcess(char[]);