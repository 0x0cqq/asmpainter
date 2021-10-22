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
ID_ERA_TWO_PIXEL     EQU            40025
ID_ERA_FOUR_PIXEL    EQU            40026
ID_ERA_EIGHT_PIXEL   EQU            40027
ID_ERA_SIXTEEN_PIXEL EQU            40028
ID_CANVAS_SIZE       EQU            40029

ID_STATUSBAR         EQU            100
IDR_MENU1            EQU            101
IDI_ICON1            EQU            102
IDB_CONTROLS         EQU            103
IDC_PEN              EQU            111
IDC_ERASER2          EQU            113
IDC_ERASER4          EQU            114
IDC_ERASER8          EQU            115
IDC_ERASER16         EQU            116
;-----------------函数原型声明-------------------
WinMain PROTO                                     ;主窗口
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;窗口运行中的消息处理程序
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;画布窗口运行中的消息处理程序
CreateCanvasWin PROTO
UpdateCanvasPos PROTO
printf PROTO C :PTR BYTE, :VARARG

mBitmap STRUCT
  bitmap HBITMAP ?
  nWidth DWORD ?
  nHeight DWORD ?
mBitmap ENDS


.data
  hInstance         dd ?                   ;本模块的句柄
  hWinMain          dd ?                   ;窗口句柄
  hCanvas           dd ?                   ;画布句柄
  hMenu             dd ?                   ;菜单句柄
  hWinToolBar       dd ?                   ;工具栏
  hWinStatusBar     dd ?                   ;状态栏
  hImageListControl dd ?
  hCurPen           dd ?                   ;鼠标光标
  hCurEraser_2      dd ?                   ;橡皮光标 2像素
  hCurEraser_4      dd ?
  hCurEraser_8      dd ?
  hCurEraser_16     dd ?

  ;主要为画布所使用的变量
  ; 以下的大小均为逻辑像素，而非屏幕上实际显示的单个像素
  defaultCanvasWidth      equ 800
  defaultCanvasHeight     equ 600
  nowCanvasWidth          dd ?
  nowCanvasHeight         dd ? 
  nowCanvasOffsetX        dd ?
  nowCanvasOffsetY        dd ?
  nowCanvasZoomLevel      dd 1 ; 一个逻辑像素在屏幕上占据几个实际像素的宽度

  historyNums       equ 50                             ;存储 50 条历史记录
  historyBitmap     mBitmap historyNums DUP(<>)  ;历史记录的位图
  ; baseDCBuf        HDC ? ; 某次绘制位图的基础画板
  drawDCBuf        HDC ?   ; 绘制了当前绘制的画板


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

CStr macro text
  local text_var
    .const                           ; Open the const section
  text_var db text,0                 ; Add the text to text_var
    .code                            ; Reopen the code section
  exitm                              ; Return the offset of test_var address
endm


CTEXT MACRO y:VARARG
  LOCAL sym
  CONST segment
  IFIDNI <y>,<>
    sym db 0
  ELSE
    sym db y,0
  ENDIF
  CONST ends
  EXITM <OFFSET sym>
ENDM

; 将相对于 Canvas Windows Client Area 的像素坐标转换成为 Canvas 的逻辑坐标
CoordWindowToCanvas proc coordWindows:POINT, coordCanvas: PTR POINT
  ;TODO
CoordWindowToCanvas endp

; 将 Canvas 的逻辑坐标相对于 Canvas Windows Client Area 的像素坐标转换成为 
CoordCanvasToWindow proc coordCanvas:POINT, coordWindow : PTR POINT
  ;TODO
CoordCanvasToWindow endp

Quit proc
  invoke DestroyWindow,hWinMain           ;删除窗口
  invoke PostQuitMessage,NULL             ;在消息队列中插入一个WM_QUIT消息
  ret
Quit endp

; 复制 HistoryBitmap 最后的一个到DrawBuf
UpdateDrawBufFromHistoryBitmap proc

UpdateDrawBufFromHistoryBitmap endp

; 重置整个历史，并且把参数的 bitmap 放到第一个位置上
InitHistory proc bitmap: HBITMAP

InitHistory endp

; 处理画布创建
; 理论上最开始的时候调用一次
HandleCanvasCreate proc
  invoke UpdateCanvasPos ; 更新位置
  ;在 HistoryBitmap 中插入一个“空白Bitmap” InitHistory
  ; UpdateDrawBufFromHistoryBitmap
  ; invalidaterect 掉整个矩形，或者想办法发一个 WM_PAINT
  ; 反正需要调用 RenderBitmap函数，但最好别直接调用
HandleCanvasCreate endp

; 从文件加载
LoadBitmapFromFile proc

LoadBitmapFromFile endp

;保存到文件
SaveBitmapToFile proc

SaveBitmapToFile endp

; 处理左键按下，也就是开始画图
HandleLButtonDown proc wParam:DWORD, lParam:DWORD
  ;TODO
  ; 标记左键按下
  ; 复制 HistoryBitmap 到 Buffer 中
  ; 需要记录最开始的点
  xor eax, eax
  ret
HandleLButtonDown endp

; 处理左键抬起，也就是结束画图
HandleLButtonUp proc wParam:DWORD, lParam:DWORD
  ; 标记左键抬起
  ; 把 DrawBuf 的 Bitmap 放置到 HistoryBitmap 中 
  ; Repaint 
  xor eax, eax
  ret
HandleLButtonUp endp

; 处理鼠标移动，也就是正在画图
HandleMouseMove proc wParam:DWORD, lParam:DWORD
  ; 判断一下当前是什么移动（需要用一个全局变量维护一下状态栏里面的选取）
  ; 如果不是笔和橡皮这种连续的，就重新复制 HistoryBitmap 到 Buffer 中
  ; 获取当前的鼠标位置（窗口的逻辑坐标），需要利用坐标系变换转换到画布的逻辑坐标
  ; 然后利用这个去画矩形。圆角矩形之类的
  ; 对于笔和橡皮，需要更新“最新的鼠标的位置”
  ; 对于笔和橡皮，可以认为两个 MouseMove 之间的时间很短，因此直接连直线
  xor eax, eax
  ret
HandleMouseMove endp

; 处理鼠标移动开画板，目前没想到没什么要做的？
HandleMouseLeave proc wParam:DWORD, lParam:DWORD
  xor eax,eax
  ret
HandleMouseLeave endp


; 将 drawDCBuf 按照合适的比例和偏移复制到 hCanvas 的 DC 上面
RenderBitmap proc
  ; 计算范围
  ; 将计算后的范围利用 StretchBlt 复制到 一个temp 的buffer上面
  ; 将 tempbuffer 移动到 Buffer 上面
RenderBitmap endp

; 画布的 proc
ProcWinCanvas proc hWnd, uMsg, wParam, lParam
  .if uMsg == WM_CREATE
    m2m hCanvas, hWnd
    invoke HandleCanvasCreate
  .elseif uMsg == WM_LBUTTONDOWN
    invoke HandleLButtonDown, wParam, lParam 
  .elseif uMsg == WM_LBUTTONUP
    invoke HandleLButtonUp, wParam, lParam
  .elseif uMsg == WM_MOUSEMOVE
    invoke HandleMouseMove, wParam, lParam
  .elseif uMsg == WM_MOUSELEAVE
    invoke HandleMouseLeave, wParam, lParam
  .elseif uMsg == WM_MOUSEWHEEL
    ;default 
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数
    ret
  .elseif uMsg == WM_SIZE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_PAINT
    invoke RenderBitmap
  .else 
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数
    ret ; 这个地方必须要 ret ，因为要返回 DefWindowProc 的返回值
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

DrawTextonCanvas proc 
  local hdc: HDC
  local rect: RECT
  local ps : PAINTSTRUCT
  invoke BeginPaint, hCanvas, addr ps
  mov hdc, eax
  invoke GetClientRect, hCanvas, addr rect
  invoke DrawText, hdc, CTEXT("test"), -1, addr rect , DT_SINGLELINE or DT_CENTER or DT_VCENTER
 
  invoke EndPaint, hCanvas, addr ps
  ret
DrawTextonCanvas endp

; 更新画布的位置
UpdateCanvasPos proc uses ecx edx ebx
  local mWinRect:RECT
  local StatusBarRect:RECT
  local ToolBarRect:RECT
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

  ;invoke DrawTextonCanvas
  ret  
UpdateCanvasPos endp


;主窗口 的 proc 
ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP

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
   ;--------------------装载光标-------------------
     invoke LoadCursor,hInstance,IDC_PEN
     mov hCurPen,eax
     invoke LoadCursor,hInstance,IDC_ERASER2
     mov hCurEraser_2,eax
     invoke LoadCursor,hInstance,IDC_ERASER4
     mov hCurEraser_4,eax
     invoke LoadCursor,hInstance,IDC_ERASER8
     mov hCurEraser_8,eax
     invoke LoadCursor,hInstance,IDC_ERASER16
     mov hCurEraser_16,eax

   .elseif eax == WM_SIZE
     ;使状态栏和工具栏随缩放而缩放
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
     ;调整画布的位置
     invoke SendMessage,hCanvas,uMsg,wParam,lParam
  .elseif eax == WM_COMMAND
     mov eax,wParam
     movzx eax,ax
     ;菜单栏/工具栏点击铅笔/橡皮按钮，进行选中并改变光标
     .if eax>=ID_PEN && eax<= ID_ERASER
        mov ebx,eax
        push ebx
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_ERASER,eax,MF_BYCOMMAND
        pop ebx
        mov eax,ebx
        .if eax == ID_PEN
            invoke SetClassLong,hWnd,GCL_HCURSOR,hCurPen
         .elseif eax == ID_ERASER
            invoke GetMenuState,hMenu,ID_ERA_TWO_PIXEL,MF_BYCOMMAND
            .if eax & MF_CHECKED
               invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_2
            .endif
             invoke GetMenuState,hMenu,ID_ERA_FOUR_PIXEL,MF_BYCOMMAND
            .if eax & MF_CHECKED
               invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_4
            .endif
             invoke GetMenuState,hMenu,ID_ERA_EIGHT_PIXEL,MF_BYCOMMAND
            .if eax & MF_CHECKED
               invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_8
            .endif
             invoke GetMenuState,hMenu,ID_ERA_SIXTEEN_PIXEL,MF_BYCOMMAND
            .if eax & MF_CHECKED
               invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_16
            .endif
         .endif
     ;菜单栏改变笔/橡皮的像素大小，进行选中
     .elseif eax>=ID_ONE_PIXEL && eax<=ID_FOUR_PIXEL
         invoke CheckMenuRadioItem,hMenu,ID_ONE_PIXEL,ID_FOUR_PIXEL,eax,MF_BYCOMMAND
     .elseif eax>=ID_ERA_TWO_PIXEL && eax<=ID_ERA_SIXTEEN_PIXEL
         mov ebx,eax
         push ebx
         invoke CheckMenuRadioItem,hMenu,ID_ERA_TWO_PIXEL,ID_ERA_SIXTEEN_PIXEL,eax,MF_BYCOMMAND
         pop ebx
         mov eax,ebx
         .if eax==ID_ERA_TWO_PIXEL
            invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_2
         .elseif eax==ID_ERA_FOUR_PIXEL
            invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_4
         .elseif eax==ID_ERA_EIGHT_PIXEL
            invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_8
         .elseif eax==ID_ERA_SIXTEEN_PIXEL
            invoke SetClassLong,hWnd,GCL_HCURSOR,hCurEraser_16
         .endif
     ;菜单栏退出功能
     .elseif eax ==ID_QUIT
         call Quit
     .endif  
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
  mov @stWndClass.hIconSm,eax                      ;小图标
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
  invoke CreateSolidBrush, 0abababh
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