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
;---------------EQU等值定义-----------------
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

;-----------------函数原型声明-------------------
WinMain PROTO                                     ;主窗口
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;窗口运行中的消息处理程序
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;画布窗口运行中的消息处理程序
CreateCanvasWin PROTO
UpdateCanvasPos PROTO
printf PROTO C :PTR BYTE, :VARARG


.data
  hInstance         dd ?                   ;本模块的句柄
  hWinMain          dd ?                   ;窗口句柄
  hCanvas           dd ?                   ;画布句柄
  hMenu             dd ?                   ;菜单句柄
  hWinToolBar       dd ?                   ;工具栏
  hWinStatusBar     dd ?                   ;状态栏
  hImageListControl dd ?

  stToolBar  equ   this byte  ;定义工具栏按钮
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;新建
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;打开
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;保存 
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;撤回
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;画笔
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;橡皮
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle            db "画图",0         ;主窗口标题
  szWindowClassName            db "MainWindow",0      ;菜单类名称
  szToolBarClassName           db "ToolbarWindow32",0         
  szStatusBarClassName         db "msctls_statusbar32",0       
  szCanvasClassName            db "画布", 0
  lptbab                       TBADDBITMAP  <NULL,?>

  debugUINT  db "%u", 0Ah, 0Dh, 0
.code

; 宏定义
m2m macro M1, M2  
	push M2
	pop M1
endm


return macro arg
	mov eax, arg
	ret
endm


Quit proc
  invoke DestroyWindow,hWinMain           ;删除窗口
  invoke PostQuitMessage,NULL             ;在消息队列中插入一个WM_QUIT消息
  ret
Quit endp

; 画布的 proc
ProcWinCanvas proc hWnd, uMsg, wParam, lParam
    ; 先写一个缩放的功能
  .if uMsg == WM_CREATE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_SIZE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_PAINT
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数
    ret
  .else 
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数
    ret 
  .endif
  xor eax,eax
	ret
ProcWinCanvas endp

; 创建画布窗口
CreateCanvasWin proc
  ;invoke MessageBox, hWinMain,addr szClassName,NULL,MB_OK
  ;创建画布窗口
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

; 更新画布的位置
UpdateCanvasPos proc uses ecx edx ebx
  local mWinRect:RECT
  local StatusBarRect:RECT
  local ToolBarRect:RECT
  local canvasRect: RECT
  ; 因为 Menu 不在 ClientRect 之中，只需要考虑 Status 和 ToolBar
  
  invoke GetClientRect,hWinMain,addr mWinRect ; 相对坐标
  invoke GetWindowRect,hWinStatusBar,addr StatusBarRect ;绝对坐标
  invoke GetWindowRect,hWinToolBar ,addr ToolBarRect    ;绝对坐标
  ; 计算横向长度
  mov ecx, mWinRect.right
  sub ecx, mWinRect.left
  ; 计算纵向长度
  mov edx, StatusBarRect.top
  sub edx, ToolBarRect.bottom
  ; 排除掉工具栏
  mov ebx, ToolBarRect.bottom
  sub ebx, ToolBarRect.top
  
  invoke SetWindowPos,hCanvas,HWND_TOP,mWinRect.left,ebx,ecx,edx,SWP_SHOWWINDOW  
  ret  
UpdateCanvasPos endp

;主窗口 的 proc 
ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP
;  local @lptbab:TBADDBITMAP

  mov eax,uMsg   ;消息
  .if eax==WM_CLOSE
     call Quit
  .elseif eax==WM_CREATE
     m2m hWinMain, hWnd ; 因为这个时候 WinMain 还有可能没有被移到里面去
  ;-----------------创建状态栏-------------------
     invoke  CreateStatusWindow,WS_CHILD OR WS_VISIBLE OR \
        SBS_SIZEGRIP,NULL,hWnd,ID_STATUSBAR
     mov hWinStatusBar,eax
  ;-----------------创建工具栏-------------------
     invoke CreateWindowEx, 0, addr szToolBarClassName, NULL, \
          CCS_NODIVIDER or WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, 0, 0, 0, 0, \
          hWnd, NULL, hInstance, NULL
     mov hWinToolBar,eax
     invoke ImageList_Create, 32, 32, ILC_COLOR32 or ILC_MASK,8, 0
     mov hImageListControl, eax
     invoke LoadBitmap,hInstance,IDB_CONTROLS
     mov @hBmp,eax
     invoke ImageList_AddMasked, hImageListControl,@hBmp, 0ffh
  ;-----------------创建画布窗口-------------------
     invoke CreateCanvasWin
	 invoke DeleteObject,@hBmp
     invoke SendMessage, hWinToolBar, TB_SETIMAGELIST, 0, hImageListControl
     invoke SendMessage, hWinToolBar, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
     invoke SendMessage, hWinToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
     invoke SendMessage, hWinToolBar, TB_ADDBUTTONS, ControlButtonNum, offset stToolBar
     invoke SendMessage, hWinToolBar, TB_AUTOSIZE, 0, 0
   .elseif eax == WM_SIZE
     ;调整画布的位置
     invoke SendMessage,hCanvas,uMsg,wParam,lParam
     ;使状态栏和工具栏随缩放而缩放
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
  .else
     invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数 
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

  invoke GetModuleHandle,NULL                      ;获取本模块句柄
  mov hInstance,eax
  invoke LoadMenu,hInstance,IDR_MENU1              ;装载主菜单，模块句柄，欲载入菜单的ID
  mov hMenu,eax
  invoke LoadAccelerators,hInstance,IDR_MENU1      ;装载加速键
  mov @hAccelerator,eax

  ; 注册主窗口类
  invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass ;内存清零
  invoke LoadIcon,hInstance,IDI_ICON1              ;装载图标句柄
  mov @stWndClass.hIcon,eax                       
  mov @stWndClass.hIconSm,eax                    ;小图标
  invoke LoadCursor,0,IDC_ARROW                    ;获取光标句柄
  mov @stWndClass.hCursor,eax
  push hInstance
  pop @stWndClass.hInstance                        ;当前程序的句柄
  mov @stWndClass.cbSize,sizeof WNDCLASSEX         ;结构体的大小
  mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW   ;窗口风格：当移动或尺寸调整改变了客户区域的宽度/高度，则重绘整个窗口
  mov @stWndClass.lpfnWndProc,offset ProcWinMain   ;窗口过程的地址
  mov @stWndClass.hbrBackground,COLOR_WINDOW + 1   ;背景色
  mov @stWndClass.lpszClassName,offset szWindowClassName ;类名称的地址
  invoke RegisterClassEx,addr @stWndClass          ;注册窗口
  
  ; 注册画布窗口类 
  invoke RtlZeroMemory,addr @canvasWndClass,sizeof @canvasWndClass ;内存清零
  invoke LoadCursor,0,IDC_ARROW                    ;获取光标句柄
  mov @canvasWndClass.hCursor, eax
  m2m @canvasWndClass.hInstance, hInstance
  mov @canvasWndClass.cbSize, sizeof WNDCLASSEX
  mov @canvasWndClass.style, CS_HREDRAW or CS_VREDRAW
  mov @canvasWndClass.lpfnWndProc, offset ProcWinCanvas
  invoke CreateSolidBrush, 000000FFh
  mov @canvasWndClass.hbrBackground, eax
  mov @canvasWndClass.lpszClassName, offset szCanvasClassName
  invoke RegisterClassEx, addr @canvasWndClass


  ;注意：不要把下面函数调用的注释缩进改到与上下一致，否则将报错：line too long
  invoke CreateWindowEx, ;建立窗口
    WS_EX_CLIENTEDGE, ;扩展窗口风格
    offset szWindowClassName,;指向类名字符串的指针
    offset szMainWindowTitle, ;指向窗口名称字符串的指针
    WS_OVERLAPPEDWINDOW,;窗口风格
    100,100,800,600,    ;x,y,窗口宽度,窗口高度
    NULL,  ;窗口所属的父窗口
    hMenu, ;窗口上将要出现的菜单的句柄
    hInstance, ;模块句柄
    NULL  ;指向一个欲传给窗口的参数的指针
  mov hWinMain,eax                                 ;返回窗口的句柄（理论上前面做过了
  invoke ShowWindow,hWinMain,SW_SHOWNORMAL         ;激活并显示窗口
  invoke UpdateWindow,hWinMain                     ;刷新窗口客户区

  invoke  InitCommonControls                       ;初始化，保证系统加载comct32.dll库文件
  .while TRUE
     invoke GetMessage,                            ;从消息队列取消息
               addr @stMsg,                        ;消息结构的地址
               NULL,                               ;取本程序所属窗口的信息
               0,                                  ;获取所有编号的信息
               0                                   ;获取所有编号的信息

     .break .if eax==0                             ;没有消息，则退出
     invoke TranslateAccelerator,                  ;实现加速键功能
               hWinMain,                           ;窗口句柄
               @hAccelerator,                      ;加速键句柄
               addr @stMsg                         ;消息结构的地址
     .if eax==0
        invoke TranslateMessage,addr @stMsg        ;传送消息
        invoke DispatchMessage,addr @stMsg         ;不同消息窗口消息分配给不同的窗口过程
     .endif
  .endw
  ret
WinMain endp

start:
  call WinMain
  invoke ExitProcess,NULL
end start