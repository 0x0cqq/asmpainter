.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include gdi32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib gdi32.lib
includelib comdlg32.lib
;---------------EUQ等值定义-----------------
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

.data
  hInstance         dd ?                   ;本模块的句柄
  hWinMain          dd ?                   ;窗口句柄
  hMenu             dd ?                   ;菜单句柄
  hWinToolBar       dd ?                   ;工具栏
  hWndStatusBar     dd ?                   ;状态栏
  hImageListControl dd ?
  hCurPen           dd ?                   ;鼠标光标
  hCurEraser_2      dd ?                   ;橡皮光标 2像素
  hCurEraser_4      dd ?
  hCurEraser_8      dd ?
  hCurEraser_16     dd ?
  
  foregroundColor       dd ?               ;前景色
  backgroundColor       dd ?               ;背景色
  customColorBuffer     dd 16 dup(?)       ;颜色缓冲区，用于自定义颜色

  stToolBar  equ   this byte  ;定义工具栏按钮
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;新建
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;打开
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;保存
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;撤回
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;画笔
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;橡皮
    TBBUTTON <10,ID_FOR_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;前景色
    TBBUTTON <11,ID_BACK_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;背景色
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle            db "画图",0         ;主窗口标题
  szWindowClassName            db "MainWindow",0      ;菜单类名称
  szToolBarClassName           db "ToolbarWindow32",0         
  szStatusBarClassName         db "msctls_statusbar32",0       

  lptbab                       TBADDBITMAP  <NULL,?>
.code
Quit proc
  invoke DestroyWindow,hWinMain           ;删除窗口
  invoke PostQuitMessage,NULL             ;在消息队列中插入一个WM_QUIT消息
  ret
Quit endp

SetColorInTool proc index:DWORD, color:DWORD
    ;TODO:该函数根据index(前/背景色)和color颜色
    ;     绘制工具栏上的按钮位图
    LOCAL @rect:RECT
    LOCAL @hdcW:HDC
    LOCAL @hdc:HDC
    LOCAL @hbmp:HBITMAP
    LOCAL @hbmpM:HBITMAP
    LOCAL @hbrush:HBRUSH
    LOCAL @hgraybrush:HBRUSH
 
    mov @rect.left,0
    mov @rect.right,32
    mov @rect.top,0
    mov @rect.bottom,32
    
    mov ebx,color
    .if index==0
       mov foregroundColor,ebx
    .else
       mov backgroundColor,ebx
    .endif

    invoke GetDC,hWinMain
    mov @hdcW,eax
    invoke CreateCompatibleDC,@hdcW
    mov @hdc,eax

    invoke CreateCompatibleBitmap,@hdcW,32,32
    mov @hbmp,eax
    invoke SelectObject,@hdc,@hbmp
    invoke CreateSolidBrush,color
    mov @hbrush,eax
    invoke FillRect,@hdc,addr @rect, @hbrush
    invoke DeleteObject,@hbrush
    invoke GetStockObject,GRAY_BRUSH
    mov @hgraybrush,eax
    invoke FrameRect,@hdc,addr @rect, @hgraybrush

    invoke CreateCompatibleBitmap,@hdcW,32,32
    mov @hbmpM,eax
    invoke SelectObject,@hdc,@hbmpM
    invoke GetStockObject,BLACK_BRUSH
    mov @hbrush,eax
    invoke FillRect,@hdc,addr @rect,@hbrush
   
    mov eax,index
    add eax,10
    mov index,eax

    invoke ImageList_Replace,hImageListControl,index,@hbmp,@hbmpM
    
    invoke DeleteDC,@hdc
    invoke DeleteObject,@hbmp
    invoke DeleteObject,@hbmpM
    invoke DeleteDC,@hdcW

    invoke InvalidateRect, hWinToolBar, NULL, FALSE
    ret
SetColorInTool endp

SetColor proc, index:DWORD
  ;TODO:该函数根据index设置前景色，背景色
  ;index=0,设置前景色
  ;index=1,设置背景色
  local @stcc:CHOOSECOLOR

  invoke RtlZeroMemory,addr @stcc,sizeof @stcc;用0填充stcc内存区域
  mov @stcc.lStructSize,sizeof @stcc
  push hWinMain
  pop @stcc.hwndOwner
  .if index==0
     mov eax,foregroundColor
  .elseif index==1
     mov eax,backgroundColor
  .endif
  mov @stcc.rgbResult,eax
  mov @stcc.Flags,CC_RGBINIT
  mov @stcc.lpCustColors,offset customColorBuffer
  invoke ChooseColor,addr @stcc
  invoke SetColorInTool,index,@stcc.rgbResult
  ret
SetColor endp

ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP

  mov eax,uMsg   ;消息
  .if eax==WM_CLOSE
     call Quit
  .elseif eax==WM_CREATE
  ;-----------------创建状态栏-------------------
     invoke  CreateStatusWindow,WS_CHILD OR WS_VISIBLE OR \
        SBS_SIZEGRIP,NULL,hWnd,ID_STATUSBAR
     mov hWndStatusBar,eax
  ;-----------------创建工具栏-------------------
     invoke CreateWindowEx, 0, addr szToolBarClassName, NULL, \
          CCS_NODIVIDER or WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS,\
          0, 0, 0, 0, hWnd, NULL, hInstance, NULL
     mov hWinToolBar,eax
     invoke ImageList_Create, 32, 32, ILC_COLOR24 or ILC_MASK,8, 0
     mov hImageListControl, eax
     invoke LoadBitmap,hInstance,IDB_CONTROLS
     mov @hBmp,eax
     invoke ImageList_AddMasked, hImageListControl,@hBmp, 0ffh
	 invoke DeleteObject,@hBmp
     invoke SetColorInTool,0,0
     invoke SetColorInTool,1,0ffffffh
     invoke SendMessage, hWinToolBar, TB_SETIMAGELIST, 0, hImageListControl
     invoke SendMessage, hWinToolBar, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
     invoke SendMessage, hWinToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
     invoke SendMessage, hWinToolBar, TB_ADDBUTTONS, ControlButtonNum, offset stToolBar
     invoke SendMessage, hWinToolBar, TB_AUTOSIZE, 0, 0
     ;在工具栏中添加前景色和背景色的选择

   ;------------------装载光标-------------------
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
     invoke SendMessage,hWndStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
  
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
     .elseif eax == ID_QUIT
         call Quit
     .elseif eax == ID_FOR_COLOR
         invoke SetColor,0
     .elseif eax == ID_BACK_COLOR
         invoke SetColor,1
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
  local @stMsg:MSG
  local @hAccelerator

  invoke GetModuleHandle,NULL                      ;获取本模块句柄
  mov hInstance,eax
  invoke LoadMenu,hInstance,IDR_MENU1              ;装载主菜单，模块句柄，欲载入菜单的ID
  mov hMenu,eax
  invoke LoadAccelerators,hInstance,IDR_MENU1      ;装载加速键
  mov @hAccelerator,eax
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
  mov hWinMain,eax                                 ;返回窗口的句柄
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