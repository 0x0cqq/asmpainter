.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib
;---------------EUQ等值定义-----------------
IDR_MENU1            EQU            101
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
;-----------------函数原型声明-------------------
WinMain PROTO                                     ;主窗口
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;窗口运行中的消息处理程序

.data
  hInstance         dd ?                   ;本模块的句柄
  hWinMain          dd ?                   ;窗口句柄
  hMenu             dd ?                   ;菜单句柄
  hSubMenu          dd ?
.const
  szMainWindowTitle db "Painter",0         ;主窗口标题
  szClassName db "菜单例",0                ;类名称，不知道为什么，先定义着
.code
Quit proc
  invoke DestroyWindow,hWinMain           ;删除窗口
  invoke PostQuitMessage,NULL             ;在消息队列中插入一个WM_QUIT消息
  ret
Quit endp

ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu

  mov eax,uMsg   ;消息
  .if eax==WM_CLOSE
     call Quit
  .else
     invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数 
     ret
     .endif
  xor eax,eax
  ret
ProcWinMain endp

WinMain proc 
  local @stWndClass:WNDCLASSEX
  local @stMsg:MSG
  local @hAccelerator

  invoke GetModuleHandle,NULL                      ;获取本模块句柄
  mov hInstance,eax
  invoke LoadMenu,hInstance,IDR_MENU1              ;装载主菜单，模块句柄，欲载入菜单的ID
  mov hMenu,eax
  invoke LoadAccelerators,hInstance,IDR_MENU1      ;装载加速键
  mov @hAccelerator,eax
  invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass ;内存清零
;  invoke LoadIcon,hInstance,ID_ICON              ;装载图标句柄
;  mov @stWndClass.hIcon,eax                       
;  mov @stWndClass.hIconSm,eax                    ;小图标
  invoke LoadCursor,0,IDC_ARROW                    ;获取光标句柄
  mov @stWndClass.hCursor,eax
  push hInstance
  pop @stWndClass.hInstance                        ;当前程序的句柄
  mov @stWndClass.cbSize,sizeof WNDCLASSEX         ;结构体的大小
  mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW   ;窗口风格：当移动或尺寸调整改变了客户区域的宽度/高度，则重绘整个窗口
  mov @stWndClass.lpfnWndProc,offset ProcWinMain   ;窗口过程的地址
  mov @stWndClass.hbrBackground,COLOR_WINDOW + 1   ;背景色
  mov @stWndClass.lpszClassName,offset szClassName ;类名称的地址
  invoke RegisterClassEx,addr @stWndClass          ;注册窗口
  ;注意：不要把下面函数调用的注释缩进改到与上下一致，否则将报错：line too long
  invoke CreateWindowEx, ;建立窗口
   WS_EX_CLIENTEDGE, ;扩展窗口风格
   offset szClassName,;指向类名字符串的指针
   offset szMainWindowTitle, ;指向窗口名称字符串的指针
   WS_OVERLAPPEDWINDOW,;窗口风格
   100,100,800,600,    ;x,y,窗口宽度,窗口高度
   NULL,  ;窗口所属的父窗口
   hMenu, ;窗口上将要出现的菜单的句柄
   hInstance, ;模块句柄
   NULL  ;指向一个欲传给窗口的参数的指针
  mov hWinMain,eax                                 ;返回窗口的句柄
  invoke ShowWindow,hWinMain,SW_SHOWNORMAL         ;激活并显示窗口
  invoke UpdateWindow,hWinMain                     ;刷新窗口客户区

  .while TRUE
     invoke GetMessage,                            ;从消息队列取消息
               addr @stMsg,                        ;消息结构的地址
               NULL,                               ;取本程序所属窗口的信息
               0,                                  ;获取所有编号的信息
               0                                   ;获取所有编号的信息

     .break .if eax==0                             ;没有消息，则退出
     invoke TranslateAccelerator,                      ;实现加速键功能
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