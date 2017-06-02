/*!
*	The front-end responsible for injecting the coffee.dll into the target process. Uses a dib-frontend
*	for display. Allows user to select target process location and starts the process. Assumes 
*	the dll resides in the same directory as the injector.
*
*	The dib tunnel code is modified code originally written by atom0s.
*
*	Originally written on 2010/03/10 by attilathedud.
*/

/*!
*	The main file is primarily responsible for rendering the window and controls.
*/

#include <windows.h>
#include <cmath>
#include "inject.h"
#include "resource.h"
#include "ufmod.h"

#define WIN32_LEAN_AND_MEAN
#define PI 3.14159

// Device context used to blt pixels on screen.
HDC dc = 0;

// Represents the current spin of the start point of the tunnel.
int scroll = 0;

// A pointer to our screen buffer.
unsigned char* buffer;

// The path of the game and our dll
char gamePath[256] = {0}, path[256] = {0};
float sintable[360] = {0}, costable[360] = {0};

// Represents whether we will display the info or not.
bool nfo = false;

// Contains a coordinate for each pixel activated on screen.
struct STAR
{
	short int x;
	short int y;
	short int z;
};

// The active pixels for our background and the rotating tunnel.
STAR background[300] = {0, 0, 0}, tunnel[64] = {0, 0, 0};

OPENFILENAME ofn = {0};
PAINTSTRUCT ps = {0};

// The display coordinates for our text displays.
RECT rect = {100, 50, 70, 70}, rect2 = {0, 0, 400, 205};

// Our button handles.
HWND bStart = 0, bAbout = 0, bBack = 0, bExit = 0;

// A helper function to place pixels in the buffer with their coordinating colors. Coordinates 
// are accessed in the buffer by: loc = ( y * 400[ width of window ] ) + x. 
void placePixel(int x, int y, unsigned char r, unsigned char g, unsigned char b)
{
	register int loc = 0;
	
	if(x >= 0 && x <= 400 && y >= 0 && y <= 205)
	{
		loc = (y * 400) + x;
		buffer[loc*4] = b;
		buffer[loc*4+1] = g;
		buffer[loc*4+2] = r;
	}
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch(msg)
    {
		/*!
		*	On window creation, place our buttons, start our music, and then start our dib effects.
		*
		*	The end effect is a tunnel in which the start point rotates around in a circle.
		*/
        case WM_CREATE:
            bStart = CreateWindow("button", "Start Game", WS_VISIBLE | WS_CHILD, 25, 281, 100, 20, hWnd, (HMENU)1, NULL, NULL);
            bAbout = CreateWindow("button", "About", WS_VISIBLE | WS_CHILD, 150, 281, 100, 20, hWnd, (HMENU)3, NULL, NULL);
            bExit = CreateWindow("button", "Exit", WS_VISIBLE | WS_CHILD, 275, 281, 100, 20, hWnd, (HMENU)2, NULL, NULL);
			bBack = CreateWindow("button", "Back", WS_CHILD, 150, 281, 100, 20, hWnd, (HMENU)4, NULL, NULL);
			uFMOD_PlaySong("#1337", 0, XM_RESOURCE);
			SetTimer(hWnd, 4, 10, 0);
			for(int i = 0; i < 360; i++)
			{
				if(i < 64)
					tunnel[i].z = 512-i*8;
				if(i <300)
				{
					background[i].x = rand()%400;
					background[i].y = rand()%200+1;
				}
				sintable[i] = (float)sin(PI/180*i);
				costable[i] = (float)cos(PI/180*i);
			}
            break;
		case WM_PAINT:
			BitBlt(BeginPaint(hWnd, &ps), 0, 69, 400, 205, dc, 0, 0, SRCCOPY);
			EndPaint(hWnd, &ps);
			break;
        case WM_COMMAND:
            switch(LOWORD(wParam))
            {
				// On inject, get our current path and open a file select dialog for the user
				// to select the target process.
                case 1:
                    ZeroMemory(&ofn, sizeof(ofn));
                    ofn.lStructSize = sizeof(ofn);
                    ofn.lpstrFile = gamePath;
                    ofn.lpstrFile[0] = '\0';
                    ofn.nMaxFile = sizeof(gamePath);
                    ofn.lpstrFilter = ".Exe\0*.EXE\0";
                    ofn.lpstrTitle = "Please Locate Game";
                    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
                    
                    if(GetOpenFileName(&ofn))
                    {
                        GetModuleFileName(NULL, path, sizeof(path));
                        for(i = strlen(path); path[i] != '\\'; i--)
                            path[i] = 0;
                        strcat(path, "coffee.dll");
                    
                        PROCESS_INFORMATION pI = startProcess(gamePath);
                        inject(path, pI);

                        ResumeThread(pI.hThread);
                        CloseHandle(pI.hThread);
                        PostQuitMessage(0);
                    }
                    break;
                case 2:
                    PostQuitMessage(0);
                    break;
				// On About, toggle the info to display
                case 3:
					ShowWindow(bStart, SW_HIDE);
					ShowWindow(bAbout, SW_HIDE);
					ShowWindow(bExit, SW_HIDE);
					ShowWindow(bBack, SW_SHOW);
					nfo = true;
					break;
				// On Back from About, toggle the info off
				case 4:
					ShowWindow(bStart, SW_SHOW);
					ShowWindow(bAbout, SW_SHOW);
					ShowWindow(bExit, SW_SHOW);
					ShowWindow(bBack, SW_HIDE);
					nfo = false;
			}
            break;
		// On each tick of our timer, calculate the new location of all the pixels for the tunnel effect.
		case WM_TIMER:
			memset(buffer, 0, 328000);
			
			for(int i = 0; i < 400; i++)
			{
				if(i < 300)
					placePixel(background[i].x, background[i].y, 100, 100, 100);

				placePixel(i, 0, 250, 250, 250);
			}

			for(int i = 0; i < 64; i++)
			{
				tunnel[i].x = short int((sintable[(tunnel[i].z + scroll)%360] * sintable[(tunnel[i].z/2+scroll)%360]) * 50);
				tunnel[i].y = short int(costable[(tunnel[i].z + scroll)%360] * 35 - costable[scroll%360]);
				tunnel[i].z -= 2;
			
				if(tunnel[i].z <= 0)
					tunnel[i].z = 512;
				for( int j = 0; j < 360; j += 10 )
					placePixel( (int)(128 * (tunnel[i].x + sintable[j%360] * 100) / tunnel[i].z + 200 - tunnel[i].x * 3),  
								(int)(128 * (tunnel[i].y + costable[j%360] * 100) / tunnel[i].z + 150 - tunnel[i].y * 3 ), 
								75, 125, 256 - tunnel[i].z /2);
			}
			if(scroll++ >= 360)
				scroll = 0;
			
			if(nfo == false)
				DrawText(dc, "     = coffee :: Call Of Duty 4 =\n   Code..................attilathedud\n   Graphics............................L.\n   Tune.........................A-Move", 152, &rect, DT_NOCLIP);
			else
				DrawText(dc, "                            DoxCoding.com presents:\n\n                             coffee.dll by attilathedud\n----------------------------------------------------------------------------------------------------\n Thanks to:                                     Keys:\n|         atom0s - for his   |              |        F3 - Toggle Menu        |\n|         tunnel code and   |              | Up/Down - Toggle Position|\n|         his constant help.|              | Left/Right - Toggle Option  |\n----------------------------------------------------------------------------------------------------\n\n Shout-Outs: \n    pandas, STN, King_Orgy, deadnesser, Sun, nh2, KsBunker", 664, &rect2, DT_NOCLIP);

			RedrawWindow(hWnd, 0, 0, RDW_INVALIDATE);
			break;
		case WM_LBUTTONDOWN:
			SendMessage(hWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
			break;
		case WM_KEYDOWN:
			if(wParam == VK_ESCAPE)
				PostQuitMessage(0);
			break;
        case WM_DESTROY:
			KillTimer(hWnd, 4);
            PostQuitMessage(0);
    }

    return DefWindowProc(hWnd, msg, wParam, lParam);
}

// WinMain's only responsibility is to create our window and device context and then listen for messages.
int __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
{
    HWND hwnd;
    WNDCLASS wc = {0};
    MSG msg = {0};
	BITMAPINFO plane = {0};

	plane.bmiHeader.biSize = 40;
	plane.bmiHeader.biWidth = 400;
	plane.bmiHeader.biHeight = -205;
	plane.bmiHeader.biPlanes = 1;
	plane.bmiHeader.biBitCount = 32;

    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ID_ICON));
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.lpszClassName = "TrainerEngine";
    wc.hbrBackground = CreatePatternBrush(LoadBitmap(hInstance, (char*)ID_BACK));

    RegisterClass(&wc);
    
    hwnd = CreateWindow(wc.lpszClassName, "Coffee <3", WS_POPUP,  (GetSystemMetrics(SM_CXSCREEN)-400)/2, (GetSystemMetrics(SM_CYSCREEN)-303)/2, 400, 303, NULL, NULL, hInstance, NULL);

	dc = CreateCompatibleDC(GetDC(hwnd));
	SelectObject(dc, CreateDIBSection(dc, &plane, 0, (void**)&buffer, 0, 0)); 
	SetBkMode(dc, TRANSPARENT);
	SetTextColor(dc, 0xffffff);

	ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    UnregisterClass("TrainerEngine", hInstance);

    while(1)
    {
        GetMessage(&msg, NULL, 0, 0);

        if(msg.message == WM_QUIT)
            break;
        else
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return 0;
}