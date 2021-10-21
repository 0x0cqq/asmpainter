.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include gdi32.inc

includelib user32.lib
includelib msvcrt.lib
includelib kernel32.lib
includelib comctl32.lib
includelib gdi32.lib
;---------------EQU��ֵ����-----------------
ID_NEW               EQU            40001
ID_OPEN              EQU            40002
ID_SAVE              EQU            40003
ID_SAVE_AS           EQU            40004
ID_QUIT              EQU            40005
ID_UNDO              EQU            40006
ID_CLEAR             EQU            40007
ID_TOOL              EQU            40008
ID_PEN               EQU            40009
ID_ERASER            EQU            40010
ID_FOR_COLOR         EQU            40012
ID_BACK_COLOR        EQU            40014
ID_ONE_PIXEL         EQU            40016
ID_TWO_PIXEL         EQU            40018
ID_FOUR_PIXEL        EQU            40019
ID_ERA_TOW_PIXEL     EQU            40025
ID_ERA_FOUR_PIXEL    EQU            40026
ID_ERA_EIGHT_PIXEL   EQU            40027
ID_ERA_SIXTEEN_PIXEL EQU            40028
ID_CANVAS_SIZE       EQU            40029

ID_STATUSBAR         EQU            100
IDR_MENU1            EQU            101
IDI_ICON1            EQU            102
IDB_CONTROLS         EQU            103

;-----------------����ԭ������-------------------
WinMain PROTO                                     ;������
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;���������е���Ϣ�������
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;�������������е���Ϣ�������
CreateCanvasWin PROTO
UpdateCanvasPos PROTO
printf PROTO C :PTR BYTE, :VARARG


.data
  hInstance         dd ?                   ;��ģ��ľ��
  hWinMain          dd ?                   ;���ھ��
  hCanvas           dd ?                   ;�������
  hMenu             dd ?                   ;�˵����
  hWinToolBar       dd ?                   ;������
  hWinStatusBar     dd ?                   ;״̬��
  hImageListControl dd ?

  stToolBar  equ   this byte  ;���幤������ť
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;�½�
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;��
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;���� 
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;����
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;��Ƥ
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle            db "��ͼ",0         ;�����ڱ���
  szWindowClassName            db "MainWindow",0      ;�˵�������
  szToolBarClassName           db "ToolbarWindow32",0         
  szStatusBarClassName         db "msctls_statusbar32",0       
  szCanvasClassName            db "����", 0
  lptbab                       TBADDBITMAP  <NULL,?>

  debugUINT  db "%u", 0Ah, 0Dh, 0
.code

; �궨��
m2m macro M1, M2  
	push M2
	pop M1
endm


return macro arg
	mov eax, arg
	ret
endm


Quit proc
  invoke DestroyWindow,hWinMain           ;ɾ������
  invoke PostQuitMessage,NULL             ;����Ϣ�����в���һ��WM_QUIT��Ϣ
  ret
Quit endp

; ������ proc
ProcWinCanvas proc hWnd, uMsg, wParam, lParam
    ; ��дһ�����ŵĹ���
  .if uMsg == WM_CREATE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_SIZE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_PAINT
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺���
    ret
  .else 
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺���
    ret 
  .endif
  xor eax,eax
	ret
ProcWinCanvas endp

; ������������
CreateCanvasWin proc
  ;invoke MessageBox, hWinMain,addr szClassName,NULL,MB_OK
  ;������������
  invoke CreateWindowEx,
    0,
    addr szCanvasClassName,
    NULL,
    WS_HSCROLL or WS_VSCROLL or WS_CHILD,
    0,0,400,300,
    hWinMain,
    NULL,
    hInstance,
    NULL
  mov hCanvas, eax
  invoke ShowWindow, hCanvas, SW_SHOW
  ret
CreateCanvasWin endp

; ���»�����λ��
UpdateCanvasPos proc uses ecx edx ebx
  local mWinRect:RECT
  local StatusBarRect:RECT
  local ToolBarRect:RECT
  local canvasRect: RECT
  ; ��Ϊ Menu ���� ClientRect ֮�У�ֻ��Ҫ���� Status �� ToolBar
  
  invoke GetClientRect,hWinMain,addr mWinRect ; �������
  invoke GetWindowRect,hWinStatusBar,addr StatusBarRect ;��������
  invoke GetWindowRect,hWinToolBar ,addr ToolBarRect    ;��������
  ; ������򳤶�
  mov ecx, mWinRect.right
  sub ecx, mWinRect.left
  ; �������򳤶�
  mov edx, StatusBarRect.top
  sub edx, ToolBarRect.bottom
  ; �ų���������
  mov ebx, ToolBarRect.bottom
  sub ebx, ToolBarRect.top
  
  invoke SetWindowPos,hCanvas,HWND_TOP,mWinRect.left,ebx,ecx,edx,SWP_SHOWWINDOW  
  ret  
UpdateCanvasPos endp

;������ �� proc 
ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP
;  local @lptbab:TBADDBITMAP

  mov eax,uMsg   ;��Ϣ
  .if eax==WM_CLOSE
     call Quit
  .elseif eax==WM_CREATE
     m2m hWinMain, hWnd ; ��Ϊ���ʱ�� WinMain ���п���û�б��Ƶ�����ȥ
  ;-----------------����״̬��-------------------
     invoke  CreateStatusWindow,WS_CHILD OR WS_VISIBLE OR \
        SBS_SIZEGRIP,NULL,hWnd,ID_STATUSBAR
     mov hWinStatusBar,eax
  ;-----------------����������-------------------
     invoke CreateWindowEx, 0, addr szToolBarClassName, NULL, \
          CCS_NODIVIDER or WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, 0, 0, 0, 0, \
          hWnd, NULL, hInstance, NULL
     mov hWinToolBar,eax
     invoke ImageList_Create, 32, 32, ILC_COLOR32 or ILC_MASK,8, 0
     mov hImageListControl, eax
     invoke LoadBitmap,hInstance,IDB_CONTROLS
     mov @hBmp,eax
     invoke ImageList_AddMasked, hImageListControl,@hBmp, 0ffh
  ;-----------------������������-------------------
     invoke CreateCanvasWin
	 invoke DeleteObject,@hBmp
     invoke SendMessage, hWinToolBar, TB_SETIMAGELIST, 0, hImageListControl
     invoke SendMessage, hWinToolBar, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
     invoke SendMessage, hWinToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
     invoke SendMessage, hWinToolBar, TB_ADDBUTTONS, ControlButtonNum, offset stToolBar
     invoke SendMessage, hWinToolBar, TB_AUTOSIZE, 0, 0
   .elseif eax == WM_SIZE
     ;����������λ��
     invoke SendMessage,hCanvas,uMsg,wParam,lParam
     ;ʹ״̬���͹����������Ŷ�����
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
  .else
     invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺��� 
     ret
     .endif 
  xor eax,eax
  ret
ProcWinMain endp

WinMain proc 
  local @stWndClass:WNDCLASSEX
  local @canvasWndClass:WNDCLASSEX
  local @stMsg:MSG
  local @hAccelerator

  invoke GetModuleHandle,NULL                      ;��ȡ��ģ����
  mov hInstance,eax
  invoke LoadMenu,hInstance,IDR_MENU1              ;װ�����˵���ģ������������˵���ID
  mov hMenu,eax
  invoke LoadAccelerators,hInstance,IDR_MENU1      ;װ�ؼ��ټ�
  mov @hAccelerator,eax

  ; ע����������
  invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass ;�ڴ�����
  invoke LoadIcon,hInstance,IDI_ICON1              ;װ��ͼ����
  mov @stWndClass.hIcon,eax                       
  mov @stWndClass.hIconSm,eax                    ;Сͼ��
  invoke LoadCursor,0,IDC_ARROW                    ;��ȡ�����
  mov @stWndClass.hCursor,eax
  push hInstance
  pop @stWndClass.hInstance                        ;��ǰ����ľ��
  mov @stWndClass.cbSize,sizeof WNDCLASSEX         ;�ṹ��Ĵ�С
  mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW   ;���ڷ�񣺵��ƶ���ߴ�����ı��˿ͻ�����Ŀ��/�߶ȣ����ػ���������
  mov @stWndClass.lpfnWndProc,offset ProcWinMain   ;���ڹ��̵ĵ�ַ
  mov @stWndClass.hbrBackground,COLOR_WINDOW + 1   ;����ɫ
  mov @stWndClass.lpszClassName,offset szWindowClassName ;�����Ƶĵ�ַ
  invoke RegisterClassEx,addr @stWndClass          ;ע�ᴰ��
  
  ; ע�ử�������� 
  invoke RtlZeroMemory,addr @canvasWndClass,sizeof @canvasWndClass ;�ڴ�����
  invoke LoadCursor,0,IDC_ARROW                    ;��ȡ�����
  mov @canvasWndClass.hCursor, eax
  m2m @canvasWndClass.hInstance, hInstance
  mov @canvasWndClass.cbSize, sizeof WNDCLASSEX
  mov @canvasWndClass.style, CS_HREDRAW or CS_VREDRAW
  mov @canvasWndClass.lpfnWndProc, offset ProcWinCanvas
  invoke CreateSolidBrush, 000000FFh
  mov @canvasWndClass.hbrBackground, eax
  mov @canvasWndClass.lpszClassName, offset szCanvasClassName
  invoke RegisterClassEx, addr @canvasWndClass


  ;ע�⣺��Ҫ�����溯�����õ�ע�������ĵ�������һ�£����򽫱���line too long
  invoke CreateWindowEx, ;��������
    WS_EX_CLIENTEDGE, ;��չ���ڷ��
    offset szWindowClassName,;ָ�������ַ�����ָ��
    offset szMainWindowTitle, ;ָ�򴰿������ַ�����ָ��
    WS_OVERLAPPEDWINDOW,;���ڷ��
    100,100,800,600,    ;x,y,���ڿ��,���ڸ߶�
    NULL,  ;���������ĸ�����
    hMenu, ;�����Ͻ�Ҫ���ֵĲ˵��ľ��
    hInstance, ;ģ����
    NULL  ;ָ��һ�����������ڵĲ�����ָ��
  mov hWinMain,eax                                 ;���ش��ڵľ����������ǰ��������
  invoke ShowWindow,hWinMain,SW_SHOWNORMAL         ;�����ʾ����
  invoke UpdateWindow,hWinMain                     ;ˢ�´��ڿͻ���

  invoke  InitCommonControls                       ;��ʼ������֤ϵͳ����comct32.dll���ļ�
  .while TRUE
     invoke GetMessage,                            ;����Ϣ����ȡ��Ϣ
               addr @stMsg,                        ;��Ϣ�ṹ�ĵ�ַ
               NULL,                               ;ȡ�������������ڵ���Ϣ
               0,                                  ;��ȡ���б�ŵ���Ϣ
               0                                   ;��ȡ���б�ŵ���Ϣ

     .break .if eax==0                             ;û����Ϣ�����˳�
     invoke TranslateAccelerator,                  ;ʵ�ּ��ټ�����
               hWinMain,                           ;���ھ��
               @hAccelerator,                      ;���ټ����
               addr @stMsg                         ;��Ϣ�ṹ�ĵ�ַ
     .if eax==0
        invoke TranslateMessage,addr @stMsg        ;������Ϣ
        invoke DispatchMessage,addr @stMsg         ;��ͬ��Ϣ������Ϣ�������ͬ�Ĵ��ڹ���
     .endif
  .endw
  ret
WinMain endp

start:
  call WinMain
  invoke ExitProcess,NULL
end start