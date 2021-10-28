.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include gdi32.inc
include comdlg32.inc
include msvcrt.inc
include shell32.inc
include shlwapi.inc

includelib user32.lib
includelib msvcrt.lib
includelib kernel32.lib
includelib comctl32.lib
includelib gdi32.lib
includelib comdlg32.lib
includelib msvcrt.lib ;for debug
;---------------EQU等值定义-----------------
ID_NEW               EQU            40001
ID_OPEN              EQU            40002
ID_SAVE              EQU            40003
ID_SAVE_AS           EQU            40004
ID_QUIT              EQU            40005
ID_UNDO              EQU            40006
ID_CLEAR             EQU            40007
ID_TOOL              EQU            40008
ID_PEN               EQU            40010
ID_ERASER            EQU            40011
ID_BUCKET            EQU            40012
ID_DRAG              EQU            40013
ID_FOR_COLOR         EQU            40020
ID_BACK_COLOR        EQU            40021
ID_ONE_PIXEL         EQU            40030
ID_TWO_PIXEL         EQU            40031
ID_FOUR_PIXEL        EQU            40032
ID_ERA_TWO_PIXEL     EQU            40040
ID_ERA_FOUR_PIXEL    EQU            40041
ID_ERA_EIGHT_PIXEL   EQU            40042
ID_ERA_SIXTEEN_PIXEL EQU            40043
ID_CANVAS_SIZE       EQU            40099


ID_STATUSBAR         EQU            100
IDR_MENU1            EQU            101
IDI_ICON1            EQU            102
IDC_PEN              EQU            111
IDC_ERASER2          EQU            113
IDC_ERASER4          EQU            114
IDC_ERASER8          EQU            115
IDC_ERASER16         EQU            116
IDC_EMPTY			 EQU			117
IDD_DIALOG1          EQU            124
IDC_DRAG             EQU            126
IDB_CONTROLS         EQU            127
IDC_BUCKET           EQU            128
IDC_GRAB             EQU            199
IDC_GRABBING         EQU            198

IDC_WIDTH            EQU            1001
IDC_HEIGHT           EQU            1005
ID_OK                EQU            1008
ID_CANCEL            EQU            1009

;-----------------函数原型声明-------------------
WinMain PROTO                                     ;主窗口
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;窗口运行中的消息处理程序
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;画布窗口运行中的消息处理程序
CreateCanvasWin PROTO
UpdateCanvasPos PROTO
UpdateCanvasScrollBar PROTO
printf PROTO C :PTR BYTE, :VARARG
sprintf PROTO C :PTR BYTE, :PTR BYTE, :VARARG

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
  hCurBucket        dd ?                   ;油桶光标
  hCurHand          dd ?                   ;拖拽小手光标 ;用底下两个
  hCurGrab          dd ?                   ;拖拽光标
  hCurGrabbing      dd ?                   ;正在拖拽光标
  
  hCurEmpty    		dd ?					;给橡皮使用

  hCurEraser		HDC NULL					;修改之后的橡皮光标
  hEraserBitmap		dd NULL					;橡皮的图
  
  EraserSize		dword	20				;橡皮的边长
  SetEraser			dword	0				;是否是橡皮，是为1


  CursorPosition	POINT <0,0>			    	;光标逻辑位置
  CoordinateFormat	byte  "%d,%d",0			;显示坐标格式
  TextBuffer		byte  24 DUP(0)	     		;输出缓冲
  
  
  foregroundColor       dd 0                    ;前景色
  backgroundColor       dd 0ffffffh             ;背景色
  customColorBuffer     dd 16 dup(?)            ;颜色缓冲区，用于自定义颜色

  ; 画布所使用的变量
  ; 以下是实际像素
  canvasMargin            equ 5
  ; 以下的大小均为逻辑像素，而非屏幕上实际显示的单个像素
  defaultCanvasWidth      equ 800
  defaultCanvasHeight     equ 600
  maxCanvasZoomLevel      equ 10
  canvasOffsetStep        equ 10

  nowCanvasWidth          dd ?
  nowCanvasHeight         dd ? 
  nowCanvasOffsetX        dd 0
  nowCanvasOffsetY        dd 0
  nowCanvasZoomLevel      dd 1 ; 一个逻辑像素在屏幕上占据几个实际像素的宽度
  tempCanvasWidth         dd ?
  tempCanvasHeight        dd ?
  hBackgroundBrush       HBRUSH ?
  
  historyNums          equ 64      ;存储 64 条历史记录
  historyBitmap        mBitmap historyNums DUP(<>)  ;历史记录的位图
  historyBitmapIndex   dd  0       ;当前历史记录位图中即将拷贝进缓存区的位图索引
  ; baseDCBuf          HDC ?       ; 某次绘制位图的基础画板
  drawDCBuf            HDC ?       ; 绘制了当前绘制的画板
  undoMaxLimit         dd  0       ; 撤销次数上限
  startCanvasOffsetX   dd  0       ; LButtonDown 时候的 Offset，用在拖动
  startCanvasOffsetY   dd  0
  startCursorPosition     POINT <?,?> ; 某次 LButtonDown 时候的 Cursor Position
  lastCursorPosition      POINT <?,?> ; 上次 MouseMove 时候的 Cursor Position
  
  filePath             BYTE  '无标题.bmp',0 ;当前正在编辑的文件路径
  defaultPath          BYTE  '无标题.bmp',0 ;默认文件路径
  existFilePath        dd  0           ;判断filePath是否更新
  
  szFilename           db MAX_PATH DUP(?)
  stToolBar  equ   this byte  ;定义工具栏按钮
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;新建
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;打开
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;保存 
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;撤回
    TBBUTTON <3,ID_DRAG,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP,0,0,NULL>;拖拽小手
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL>;画笔
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP, 0, 0, NULL>;橡皮
    TBBUTTON <9,ID_BUCKET,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP,0,0,NULL>;油桶
    TBBUTTON <6,NULL,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,NULL>;分割线
    TBBUTTON <10,ID_FOR_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;前景色
    TBBUTTON <11,ID_BACK_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;背景色
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle     db "画图",0         ;主窗口标题
  szWindowClassName     db "MainWindow",0      ;菜单类名称
  szToolBarClassName    db "ToolbarWindow32",0         
  szStatusBarClassName  db "msctls_statusbar32",0       
  szCanvasClassName     db "画布", 0
  szFilter              db '位图(*.bmp)',0,'*.bmp',0;打开文件的文件名限制
  szDefExt              db 'bmp',0;保存的扩展名

  lptbab                TBADDBITMAP  <NULL,?>
  
;--------for debug---------
  szMouseMoveCanvas   db  "MouseMove in Canvas",0dh,0ah,0
  szLButtonDown       db  "LButtonDown in Canvas",0dh,0ah,0
  szLButtonUp         db  "LButtonUp in Canvas",0dh,0ah,0
  szOutput            db  "Load Bitmap From File",0dh,0ah,0
  szOpenCommand       db  "Received OpenCommand",0dh,0ah,0
 
;--------for debug---------
  debugUINT   db "%u", 0Ah, 0Dh, 0
  debugUINT2  db "%u %u", 0Ah, 0Dh, 0
  debugUINT4  db "%u %u %u %u", 0Ah, 0Dh, 0
  szFmt       db  'EAX=%d', 0ah,0dh,0
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

get_invoke macro dst , name, args: VARARG
  invoke name, args
  mov dst, eax
endm

; 有界的修改
modifyWithBound proc var: PTR SDWORD , delta: SDWORD, lowBound : SDWORD , highBound :SDWORD 
  mov esi, [var]
  invoke crt_printf, CTEXT("%u",0Ah,0Dh), esi
  mov eax, [esi]
  sub eax, delta
  mov [esi], eax
  .if eax < lowBound
    m2m [esi], lowBound
  .endif
  .if eax > highBound
    m2m [esi], highBound
  .endif 
  ret 
modifyWithBound endp

; Windows 像素坐标的 offset 是
; 是 Canvas 逻辑坐标的

; 将相对于 Canvas Windows Client Area 的像素坐标转换成为 Canvas 的逻辑坐标
CoordWindowToCanvas proc coordWindow: PTR POINT
  ; invoke crt_printf, CTEXT("before transformation: ")
  mov esi, coordWindow

  sub (POINT PTR [esi]).x, canvasMargin
  sub (POINT PTR [esi]).y, canvasMargin
  mov ebx, nowCanvasZoomLevel
  ; x 坐标
  mov eax, (POINT PTR [esi]).x
  mov edx, 0
  div ebx
  add eax, nowCanvasOffsetX
  mov (POINT PTR [esi]).x, eax
  ; y 坐标
  mov eax, (POINT PTR [esi]).y
  mov edx, 0
  div ebx
  add eax, nowCanvasOffsetY
  mov (POINT PTR [esi]).y, eax
  ret 
CoordWindowToCanvas endp

; 将 Canvas 的逻辑坐标转换成为相对于 Canvas Windows Client Area 的像素坐标
CoordCanvasToWindow proc coordCanvas: PTR POINT
  ; 如果不在画布左上角的右下方会出问题
  mov esi, coordCanvas
  mov ebx, nowCanvasZoomLevel
  ; x 坐标
  mov eax, (POINT PTR [esi]).x
  sub eax, nowCanvasOffsetX
  mov edx, 0
  mul ebx
  add eax, canvasMargin
  mov (POINT PTR [esi]).x, eax
  ; y 坐标
  mov eax, (POINT PTR [esi]).y
  sub eax, nowCanvasOffsetY
  mov edx, 0
  mul ebx
  add eax, canvasMargin
  mov (POINT PTR [esi]).y, eax
  ret   
CoordCanvasToWindow endp

Quit proc
  invoke DestroyWindow,hWinMain           ;删除窗口
  invoke PostQuitMessage,NULL             ;在消息队列中插入一个WM_QUIT消息
  ret
Quit endp

; 画出一块橡皮
CreateEraser proc
  local hdc:HDC
  local eraserWidth:dword
  local pen:HPEN
  local brush:HBRUSH
  invoke GetDC, hCanvas
  mov hdc, eax
  invoke CreateCompatibleDC, hdc
  mov hCurEraser, eax
  mov eax, EraserSize
  mov ebx, nowCanvasZoomLevel
  mul ebx
  mov eraserWidth, eax
  invoke CreateCompatibleBitmap, hdc, eraserWidth, eraserWidth
  mov hEraserBitmap, eax
  invoke SelectObject, hCurEraser, hEraserBitmap
  
  invoke CreatePen, PS_SOLID, 1, 0
  mov pen, eax
  invoke SelectObject, hCurEraser, pen
  invoke CreateSolidBrush, backgroundColor
  mov brush, eax
  invoke SelectObject, hCurEraser, brush
  
  invoke Rectangle, hCurEraser, 0, 0, eraserWidth, eraserWidth
    
  invoke DeleteObject, pen
  invoke DeleteObject, brush
  invoke ReleaseDC, hCanvas, hdc
  ret
CreateEraser endp

; 删除橡皮，置零句柄
DestoryEraser proc
    invoke DeleteObject, hEraserBitmap
    mov hEraserBitmap, NULL
    invoke DeleteDC, hCurEraser
    mov hCurEraser, NULL
    ret
DestoryEraser endp

; 更新橡皮图像
UpdateEraser proc
    .if hCurEraser != NULL
        invoke DestoryEraser
    .endif
    invoke CreateEraser
    ret
UpdateEraser endp

; 获取鼠标逻辑坐标
; 放到 cursorPos 里面
GetCursorPosition proc cursorPos : PTR POINT
  local point:POINT
  local rect:RECT
  local ifout:dword		;是否超出画布域外
  invoke GetCursorPos, addr point
  invoke GetClientRect, hCanvas, addr rect
  
  ; 变换坐标
  invoke ScreenToClient, hCanvas, addr point
  
  ; 判断超出区域
  ; 这里的 rect 是相对与 Client 的，需要先变换坐标

  mov ifout, 0
  mov ebx, point.x
  .if ebx > rect.right
    mov ifout, 1
  .elseif ebx < rect.left
    mov ifout, 1
  .endif
  mov ebx, point.y
  .if ebx < rect.top
    mov ifout, 1
  .elseif ebx > rect.bottom
    mov ifout, 1
  .endif
  invoke CoordWindowToCanvas, addr point
  mov edi, cursorPos
  mov ebx, point.x
  mov (POINT PTR [edi]).x, ebx
  mov ebx, point.y
  mov (POINT PTR [edi]).y, ebx
  .if ifout == 1
    mov (POINT PTR [edi]).x, 0
    mov (POINT PTR [edi]).y, 0
  .endif
  ret
GetCursorPosition endp

; 显示鼠标的逻辑坐标
ShowCursorPosition proc
  pushad
  invoke GetCursorPosition, offset CursorPosition
  popad
  invoke sprintf, addr TextBuffer, offset CoordinateFormat, CursorPosition.x, CursorPosition.y ; 格式化输出到字符串
  invoke SendMessage, hWinStatusBar, SB_SETTEXT, 0, addr TextBuffer ; 显示坐标
  ret
ShowCursorPosition endp

; 画出位图
DrawEraser proc hdc:HDC
	local point:POINT
    local eraserLeftCanvas:DWORD
    local eraserTopCanvas:DWORD
    local eraserFromX:DWORD
    local eraserFromY:DWORD
    local eraserToX:DWORD
    local eraserToY:DWORD
    local eraserWidth:DWORD
    local eraserHeight:DWORD
    local canvasFromX:DWORD
    local canvasFromY:DWORD
    
	; 获取橡皮起始坐标
	invoke GetCursorPosition, addr point
	invoke sprintf, addr TextBuffer, offset CoordinateFormat, point.x, point.y
	invoke SendMessage, hWinStatusBar, SB_SETTEXT, 0, addr TextBuffer
    mov eax, EraserSize
    shr eax, 1
    mov edx, point.x
    sub edx, eax
    mov eraserLeftCanvas, edx
    .if SDWORD PTR edx > 0
        mov eraserFromX, edx
    .else
        mov eraserFromX, 0
    .endif
    mov edx, point.y
    sub edx, eax
    mov eraserTopCanvas, edx
    .if SDWORD PTR edx > 0
        mov eraserFromY, edx
    .else
        mov eraserFromY, 0
    .endif
	
	; 获取结束坐标
    mov edx, point.x
    add edx, eax
    .if SDWORD PTR edx < nowCanvasWidth
        mov eraserToX, edx
    .else
        mov edx, nowCanvasWidth
        mov eraserToX, edx
    .endif
    mov edx, point.y
    add edx, eax
    .if SDWORD PTR edx < nowCanvasHeight
        mov eraserToY, edx
    .else
        mov edx, nowCanvasHeight
        mov eraserToY, edx
    .endif
    
	; 坐标变换
    mov eax, eraserLeftCanvas
	mov point.x, eax
	mov eax, eraserTopCanvas
	mov point.y, eax
	invoke CoordCanvasToWindow, addr point
	mov eax, point.x
    mov eraserLeftCanvas, eax
    mov eax, point.y
    mov eraserTopCanvas, eax
    
	mov eax, eraserFromX
	mov point.x, eax
	mov eax, eraserFromY
	mov point.y, eax
	invoke CoordCanvasToWindow, addr point
	mov eax, point.x
    mov eraserFromX, eax
    mov canvasFromX, eax
	mov eax, point.y
    mov eraserFromY, eax
    mov canvasFromY, eax
	
	mov eax, eraserToX
	mov point.x, eax
	mov eax, eraserToY
	mov point.y, eax
	invoke CoordCanvasToWindow, addr point
	mov eax, point.x
    mov eraserToX, eax
    mov eax, point.y
    mov eraserToY, eax
    
    mov eax, eraserToX
    sub eax, eraserFromX
    mov eraserWidth, eax
    
    mov eax, eraserFromX
    sub eax, eraserLeftCanvas
    mov eraserFromX, eax
    
    mov eax, eraserToY
    sub eax, eraserFromY
    mov eraserHeight, eax
    mov eax, eraserFromY
    sub eax, eraserTopCanvas
    mov eraserFromY, eax
    
	; 画在橡皮上
    invoke BitBlt, hdc, canvasFromX, canvasFromY, eraserWidth, eraserHeight, hCurEraser, eraserFromX, eraserFromY, SRCCOPY
    
    ret
DrawEraser endp

; 复制 HistoryBitmap 最后的一个到DrawDCBuf，同时要更新画布的宽和高
UpdateDrawBufFromHistoryBitmap proc
; 构造辅助的hTempDC
; 先将historyBitmap的最后一个绑定到临时HDC，
; 再把临时HDC复制给新HDC
  LOCAL @hTempDC:HDC
  LOCAL @hCanvasDC:HDC
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @nWidth: DWORD
  LOCAL @nHeight: DWORD
  local @newDrawBufBitmap: HBITMAP

  pushad
  ; 从 history 中取来最后一个
  mov eax, historyBitmapIndex
  mov edx, 0
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx
  m2m @hTempBitmap,(mBitmap PTR [esi]).bitmap
  m2m @nWidth,(mBitmap PTR [esi]).nWidth
  m2m @nHeight,(mBitmap PTR [esi]).nHeight
  invoke crt_printf, CTEXT("history map", 0Ah,0Dh)
  invoke crt_printf, addr debugUINT2, @nWidth, @nHeight

  invoke GetDC,hCanvas
  mov @hCanvasDC,eax
  invoke CreateCompatibleDC,@hCanvasDC
  mov @hTempDC,eax
  invoke SelectObject,@hTempDC,@hTempBitmap

  ; 新建一个画布
  invoke CreateCompatibleBitmap, @hCanvasDC, @nWidth, @nHeight
  mov @newDrawBufBitmap, eax ; 不删，留给三行后删
  invoke SelectObject, drawDCBuf, @newDrawBufBitmap
  invoke DeleteObject, eax ;删掉老的 Bitmap
  
  invoke ReleaseDC, hCanvas,@hCanvasDC 
  invoke BitBlt,drawDCBuf,0,0,@nWidth,@nHeight,@hTempDC,0,0,SRCCOPY
  invoke DeleteDC,@hTempDC

  m2m nowCanvasWidth, @nWidth
  m2m nowCanvasHeight, @nHeight

  popad
  ret
UpdateDrawBufFromHistoryBitmap endp

;将当前drawDCBuf转换为Bitmap并存在HistoryBitmap中
UpdateHistoryBitmapFromDrawBuf proc, nWidth:DWORD,nHeight:DWORD
;输入参数为当前drawDCBuf的宽度和高度
;实现过程：
;       先将historyBitmapIndex+1作为新位图的索引
;       但是要旋转着用啊
;       将原来该位置句柄对应的位图释放（因此初始化时一定要将创建64个空位图对应到historyBitmap?）
;       再将drawDCBuf复制到创建的新DC上，然后保存位图句柄到historyBitmap
;注：此函数中没有判断是否增加撤销上限，调用该函数时需要在后面补充
  LOCAL @hTempDC:HDC
  LOCAL @hCanvasDC:HDC
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @tempWidth: DWORD
  LOCAL @tempHeight: DWORD
  
  pushad
  mov eax,historyBitmapIndex
  inc eax
  .if eax>=64
    sub eax,64
  .endif
  mov historyBitmapIndex,eax
  mov edx, 0
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx

  invoke DeleteObject, (mBitmap PTR [esi]).bitmap

  mov eax,nowCanvasHeight
  .if nHeight < eax
     m2m @tempHeight,nHeight
  .else
     m2m @tempHeight,nowCanvasHeight
  .endif
  mov eax,nowCanvasWidth
  .if nWidth < eax
     m2m @tempWidth,nWidth
  .else
     m2m @tempWidth,nowCanvasWidth
  .endif
  

  invoke GetDC,hCanvas
  mov @hCanvasDC,eax
  invoke CreateCompatibleDC, @hCanvasDC
  mov @hTempDC, eax
  invoke CreateCompatibleBitmap, @hCanvasDC, @tempWidth, @tempHeight
  mov @hTempBitmap, eax
  invoke ReleaseDC, hCanvas,@hCanvasDC 
  invoke SelectObject,@hTempDC, @hTempBitmap
  invoke BitBlt, @hTempDC, 0, 0, @tempWidth, @tempHeight, drawDCBuf, 0, 0, SRCCOPY
  invoke DeleteDC,@hTempDC

  mov eax, historyBitmapIndex
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx
  m2m (mBitmap PTR [esi]).bitmap,@hTempBitmap
  m2m (mBitmap PTR [esi]).nWidth,@tempWidth
  m2m (mBitmap PTR [esi]).nHeight,@tempHeight
  popad
  ret
UpdateHistoryBitmapFromDrawBuf endp

; 重置整个历史，并且把参数的 bitmap 放到第一个位置上
InitHistory proc bitmap: HBITMAP, nWidth: DWORD, nHeight:DWORD

  lea esi, historyBitmap
  m2m (mBitmap PTR [esi]).bitmap ,bitmap
  m2m (mBitmap PTR [esi]).nWidth ,nWidth
  m2m (mBitmap PTR [esi]).nHeight,nHeight

  mov historyBitmapIndex,0
  mov undoMaxLimit,0
  ret
InitHistory endp

; 处理画布创建
; 理论上最开始的时候调用一次
HandleCanvasCreate proc
  local hCanvasDC : HDC
  local hTempDC   : HDC
  local initBitmap: HBITMAP
  local hTempBrush: HBRUSH
  local tempRect  : RECT
  
  invoke UpdateCanvasPos ; 更新位置

  ; 新建一个默认的画布
  invoke GetDC, hCanvas
  mov hCanvasDC, eax
  invoke CreateCompatibleDC, hCanvasDC
  mov drawDCBuf, eax
  invoke CreateCompatibleBitmap, hCanvasDC, defaultCanvasWidth, defaultCanvasHeight  
  mov initBitmap, eax ;不能删这个，交给 historyBitmap 数组去管理
  invoke CreateCompatibleDC, hCanvasDC
  mov hTempDC, eax
  invoke ReleaseDC, hCanvas, hCanvasDC

  ; 涂上全部背景色
  invoke SelectObject, hTempDC, initBitmap
  invoke CreateSolidBrush, backgroundColor
  mov hTempBrush, eax
  mov tempRect.top, 0
  mov tempRect.left, 0
  mov tempRect.right, defaultCanvasWidth
  mov tempRect.bottom, defaultCanvasHeight
  invoke FillRect, hTempDC, addr tempRect, hTempBrush
  ; 初始化到 historyBitmap 里面
  invoke InitHistory, initBitmap, defaultCanvasWidth, defaultCanvasHeight  
  invoke DeleteObject, hTempBrush
  invoke DeleteDC, hTempDC
  
  invoke UpdateDrawBufFromHistoryBitmap       ; 将 historyBitmap 牵引到 DrawBuf 里面去
  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect 掉整个画布，让 WM_PAINT 去更新
  ret
HandleCanvasCreate endp

; 从文件加载
LoadBitmapFromFile proc
; TODO:将路径filePath中的位图更新到DrawBuf
;      并将句柄加载到historyBitmap对应Index
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @hWinDC:HDC
  LOCAL @hTempDC:HDC

  invoke crt_printf,addr szOutput
  ;将路径filePath中的位图更新到DrawBuf
  invoke LoadImage,NULL,addr filePath,IMAGE_BITMAP,0,0,LR_LOADFROMFILE
  mov @hTempBitmap,eax
  invoke GetDC,hWinMain
  mov @hWinDC,eax
  invoke CreateCompatibleDC, @hWinDC
  mov @hTempDC, eax
  invoke ReleaseDC, hWinMain,@hWinDC 
  invoke SelectObject,@hTempDC, @hTempBitmap
  invoke BitBlt,drawDCBuf, 0, 0,nowCanvasWidth,nowCanvasHeight,@hTempDC , 0, 0, SRCCOPY
  invoke DeleteDC,@hTempDC

  ;将DrawBuf中的位图更新historyBitmap当前Index
  ;调用UpdateHistoryBitmapFromDrawBuf会更新到Index+1的位置
  ;所以先将historyBitmapIndex减少1
  mov eax,historyBitmapIndex
  dec eax
  mov historyBitmapIndex,eax
  invoke UpdateHistoryBitmapFromDrawBuf,nowCanvasWidth,nowCanvasHeight
  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
LoadBitmapFromFile endp

CreateBitmapInfoStruct proc hBmp:HBITMAP
  local @bmp:BITMAP
  local @pbmi:PTR
  local @cClrBits:DWORD
  ;检索位图颜色格式、宽度和高度
  invoke GetObject,hBmp,sizeof BITMAP,addr @bmp
  movzx eax,@bmp.bmPlanes
  movzx ebx,@bmp.bmBitsPixel
  mul ebx
  mov @cClrBits,eax
  ;将颜色格式转换为位数
  .if @cClrBits == 1
     mov @cClrBits,1 
  .elseif @cClrBits <= 4
     mov @cClrBits,4
  .elseif @cClrBits <= 8
     mov @cClrBits,8
  .elseif @cClrBits <=16
     mov @cClrBits,16
  .elseif @cClrBits <=24
     mov @cClrBits,24
  .else
     mov @cClrBits,32
  .endif
  ;为 BITMAPIINFO 结构分配内存
  ;包含一个 BITMAPINFOHEADER 结构和一个 RGBQUAD 数组
  .if @cClrBits < 24
     mov eax,1
     mov ecx,@cClrBits
     shl eax,cl
     mov ecx,sizeof RGBQUAD
     mul ecx
     add eax,sizeof BITMAPINFOHEADER
     invoke LocalAlloc,LMEM_FIXED or LMEM_ZEROINIT,eax
     mov @pbmi,eax
  ;每像素 24 位或每像素 32 位的格式没有RGBQUAD
  .else
     invoke LocalAlloc,LMEM_FIXED or LMEM_ZEROINIT,sizeof BITMAPINFOHEADER
     mov @pbmi,eax
  .endif
  ;初始化 BITMAPIINFO 结构中的字段
  mov esi,@pbmi
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biSize,sizeof BITMAPINFOHEADER
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biWidth,@bmp.bmWidth
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biHeight,@bmp.bmHeight
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biPlanes,@bmp.bmPlanes
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biBitCount,@bmp.bmBitsPixel
  .if @cClrBits <24
     mov eax,1
     mov ecx,@cClrBits
     shl eax,cl
     mov (BITMAPINFO PTR [esi]).bmiHeader.biClrUsed,eax
  .endif
  ;如果位图未压缩，则设置 BI_RGB 标志
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biCompression,BI_RGB
  ;计算颜色数组中的字节数索引并将结果存储在 biSizeImage 中
  ;pbmi->bmiHeader.biSizeImage=((pbmi->bmiHeader.biWidth * cClrBits +31)&~31)/8\ 
  ;                             * pbmi->bmiHeader.biHeight;
  mov eax,(BITMAPINFO PTR [esi]).bmiHeader.biWidth
  mov ebx,@cClrBits
  mul ebx
  add eax,31
  and eax,0ffffffe0h
  mov ebx,8
  mov edx,0
  div ebx
  mov ebx,(BITMAPINFO PTR [esi]).bmiHeader.biHeight
  mul ebx
  mov (BITMAPINFO PTR [esi]).bmiHeader.biSizeImage,eax
  mov (BITMAPINFO PTR [esi]).bmiHeader.biClrImportant,0
  mov eax,@pbmi
  ret
CreateBitmapInfoStruct endp

;保存到文件
SaveBitmapToFile proc
;TODO:将historyBitmap最后一张保存到路径filePath
  local @hf:HANDLE
  local @hdr:BITMAPFILEHEADER
  local @pbih:PTR  ;pointer to bitmapinfoheader
  local @pbi:PTR  ;pointer to bitmapinfo
  local @lpBits:LPBYTE
  local @dwTotal:DWORD
  local @cb:DWORD
  local @hp:PTR
  local @dwTmp:DWORD
  local @hbmp:HBITMAP

  mov eax, historyBitmapIndex
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx
  m2m @hbmp,(mBitmap PTR [esi]).bitmap
  invoke CreateBitmapInfoStruct,@hbmp
  mov @pbi,eax
  mov @pbih,eax
  mov esi,@pbih
  invoke GlobalAlloc,GMEM_FIXED, (BITMAPINFOHEADER PTR [esi]).biSizeImage
  mov @lpBits,eax
  invoke GetDIBits,drawDCBuf,@hbmp,0,(BITMAPINFOHEADER PTR [esi]).biHeight,@lpBits,\
           @pbi, DIB_RGB_COLORS
  invoke CreateFile, addr filePath, GENERIC_READ or GENERIC_WRITE, 0, NULL, \
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
  mov @hf,eax
  mov @hdr.bfType, 4d42h
  ;Compute the size of the entire file.
  mov eax, SIZEOF RGBQUAD
  mov ecx, (BITMAPINFOHEADER PTR [esi]).biClrUsed
  mul ecx
  add eax, SIZEOF BITMAPFILEHEADER
  add eax,(BITMAPINFOHEADER PTR [esi]).biSize
  add eax,(BITMAPINFOHEADER PTR [esi]).biSizeImage
  mov @hdr.bfSize,eax
  mov @hdr.bfReserved1,0
  mov @hdr.bfReserved2,0
  ;Compute the offset of the array of color indices
  sub eax,(BITMAPINFOHEADER PTR [esi]).biSizeImage
  mov @hdr.bfOffBits,eax
  ;Copy the BitmapFileHeader into the .BMP file
  invoke WriteFile,@hf,addr @hdr,sizeof BITMAPFILEHEADER,addr @dwTmp,NULL
  ;Copy the BitmapInfoHeader and RGBQUAD array into the file
  mov ebx,sizeof RGBQUAD
  mov ecx,(BITMAPINFOHEADER PTR [esi]).biClrUsed
  mul ecx
  add ebx,sizeof BITMAPINFOHEADER
  invoke WriteFile,@hf,@pbih,ebx,addr @dwTmp,NULL
  ;Copy the array of color indices into the .BMP file
  m2m @dwTotal,(BITMAPINFOHEADER PTR [esi]).biSizeImage
  m2m @cb,(BITMAPINFOHEADER PTR [esi]).biSizeImage
  m2m @hp,@lpBits
  invoke WriteFile,@hf,@hp,@cb,addr @dwTmp,NULL
  invoke CloseHandle,@hf
  invoke GlobalFree,@lpBits
  invoke LocalFree,@pbi
  ret
SaveBitmapToFile endp

; 处理左键按下，也就是开始画图
HandleLButtonDown proc wParam:DWORD, lParam:DWORD
  ; 复制 HistoryBitmap 到 Buffer 中
  invoke UpdateDrawBufFromHistoryBitmap
  ; 需要记录最开始的点
  invoke GetCursorPosition, offset startCursorPosition
  m2m lastCursorPosition.x, startCursorPosition.x
  m2m lastCursorPosition.y, startCursorPosition.y
  m2m startCanvasOffsetX, nowCanvasOffsetX
  m2m startCanvasOffsetY, nowCanvasOffsetY
  ; TODO : 如果是拖动的话要更改光标
  invoke GetMenuState,hMenu,ID_DRAG,MF_BYCOMMAND
  .if eax & MF_CHECKED
     invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrabbing
  .endif  
  invoke InvalidateRect, hCanvas, NULL, FALSE
  xor eax, eax
  ret
HandleLButtonDown endp


; 处理左键抬起，也就是结束画图
HandleLButtonUp proc wParam:DWORD, lParam:DWORD
  ; 标记左键抬起
  ; 把 DrawBuf 的 Bitmap 放置到 HistoryBitmap 中
  ; 撤销上限+1
  ; 油漆在这里涂
  local nowCursorPos : POINT
  invoke GetMenuState,hMenu,ID_DRAG,MF_BYCOMMAND
  .if eax & MF_CHECKED
     invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrab
  .endif 
  invoke GetMenuState,hMenu,ID_BUCKET,MF_BYCOMMAND
  .if eax & MF_CHECKED
    invoke CreateSolidBrush, foregroundColor ; 增加笔刷
    invoke SelectObject, drawDCBuf, eax
    invoke DeleteObject, eax

    invoke GetCursorPosition, addr nowCursorPos
    invoke GetPixel, drawDCBuf, nowCursorPos.x, nowCursorPos.y

    invoke ExtFloodFill, drawDCBuf, nowCursorPos.x, nowCursorPos.y, eax, FLOODFILLSURFACE
  .endif
  invoke UpdateHistoryBitmapFromDrawBuf, nowCanvasWidth, nowCanvasHeight
  invoke InvalidateRect, hCanvas, NULL, FALSE
  .if undoMaxLimit < 64
    mov eax,undoMaxLimit
    inc eax
    mov undoMaxLimit,eax
  .endif
  xor eax, eax
  ret
HandleLButtonUp endp

; 获取笔的宽度
; 在返回值中返回笔的宽度
GetPenWidth proc
  invoke GetMenuState, hMenu, ID_ONE_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 1
    jmp return_width
  .endif
  invoke GetMenuState, hMenu, ID_TWO_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 2
    jmp return_width
  .endif
  invoke GetMenuState, hMenu, ID_FOUR_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 4
    jmp return_width
  .endif
return_width:
  ret
GetPenWidth endp

; 获取橡皮的宽度
; 在返回值中获取橡皮的宽度
GetEraserWidth proc
  invoke GetMenuState, hMenu, ID_ERA_TWO_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 2
    jmp return_eraser_width
  .endif
  invoke GetMenuState, hMenu, ID_ERA_FOUR_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 4
    jmp return_eraser_width
  .endif
  invoke GetMenuState, hMenu, ID_ERA_EIGHT_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 8
    jmp return_eraser_width
  .endif
  invoke GetMenuState, hMenu, ID_ERA_SIXTEEN_PIXEL, MF_BYCOMMAND
  .if eax & MF_CHECKED
    mov eax, 16
    jmp return_eraser_width
  .endif
return_eraser_width:
  ret
GetEraserWidth endp

; 处理鼠标移动，也就是正在画图
HandleMouseMove proc wParam:DWORD, lParam:DWORD
  local nowCursor : POINT
  ; 如果左键没有按下，那没事了
  ; 如果左键没有按下，那没事了
  .if !(wParam & MK_LBUTTON)
    jmp final
  .endif
  invoke ShowCursorPosition ; 显示当前坐标
  
  invoke GetCursorPosition, addr nowCursor; 更新当前鼠标位置

  ; 处理连续变化，也就是可以增量绘制的部分
  ; 对于笔和橡皮，需要更新“最新的鼠标的位置”
  ; 对于笔和橡皮，可以认为两个 MouseMove 之间的时间很短，因此直接连直线
  invoke GetMenuState, hMenu, ID_PEN, MF_BYCOMMAND  
  .if eax & MF_CHECKED ; 选择的是 PEN
    invoke MoveToEx, drawDCBuf, lastCursorPosition.x, lastCursorPosition.y, NULL
    invoke GetPenWidth
    invoke CreatePen, PS_SOLID, eax, foregroundColor
    invoke SelectObject, drawDCBuf, eax
    invoke LineTo, drawDCBuf, nowCursor.x, nowCursor.y
    m2m lastCursorPosition.x, nowCursor.x
    m2m lastCursorPosition.y, nowCursor.y
    jmp final
  .endif
  invoke GetMenuState, hMenu, ID_ERASER, MF_BYCOMMAND  
  .if eax & MF_CHECKED ; 选择的是 ERASER
    invoke MoveToEx, drawDCBuf, lastCursorPosition.x, lastCursorPosition.y, NULL
    invoke GetEraserWidth
    invoke CreatePen, PS_SOLID, eax, backgroundColor
    invoke SelectObject, drawDCBuf, eax
    invoke LineTo, drawDCBuf, nowCursor.x, nowCursor.y
    m2m lastCursorPosition.x, nowCursor.x
    m2m lastCursorPosition.y, nowCursor.y
    jmp final
  .endif
  ; TODO: 判断一下是否是拖动 目前认为凡是没选中的都是拖动
  invoke GetMenuState, hMenu, ID_DRAG, MF_BYCOMMAND  
  .if eax & MF_CHECKED
    m2m nowCanvasOffsetX, startCanvasOffsetX
    m2m nowCanvasOffsetY, startCanvasOffsetY
    invoke GetCursorPosition, addr nowCursor; 在旧坐标下计算当前鼠标位置
    mov eax, nowCursor.x
    sub eax, startCursorPosition.x
    invoke modifyWithBound, addr nowCanvasOffsetX, eax, 0, nowCanvasWidth
    mov eax, nowCursor.y
    sub eax, startCursorPosition.y
    invoke modifyWithBound, addr nowCanvasOffsetY, eax, 0, nowCanvasHeight 
    
    jmp final
  .endif
  invoke UpdateDrawBufFromHistoryBitmap    
  ; 如果不是笔和橡皮这种连续的，就重新复制 HistoryBitmap 到 Buffer 中
  ; 获取当前的鼠标位置（窗口的逻辑坐标），需要利用坐标系变换转换到画布的逻辑坐标
  ; 然后利用这个去画矩形。圆角矩形之类的


final:
  invoke InvalidateRect, hCanvas,NULL,FALSE
  xor eax, eax
  ret
HandleMouseMove endp

; 处理鼠标移动开画板，目前没想到没什么要做的？
HandleMouseLeave proc wParam:DWORD, lParam:DWORD
  mov TextBuffer, 0
  invoke SendMessage, hWinStatusBar, SB_SETTEXT, 0, addr TextBuffer ; 消除坐标，但没法用？
  
  xor eax,eax
  ret
HandleMouseLeave endp

;处理鼠标滚轮
; 按下 Ctrl 时候，对应缩放操作
; 没有 Ctrl 的时候，对应上下移动操作
HandleMouseWheel proc wParam:DWORD, lParam:DWORD
  local dist: SDWORD

  mov ax, SWORD PTR [wParam+2] ; 取出来高字节
  movsx eax, ax
  cdq
  mov ecx, 120
  idiv ecx
  mov dist, eax
  ; invoke crt_printf, CTEXT("key state:%d",0Ah,0Dh), dist


  .if wParam & 08h
    ; control 键按下了：缩放
    invoke modifyWithBound, addr nowCanvasZoomLevel, dist, 1, maxCanvasZoomLevel
    
  .else
    mov eax, dist
    mov ecx, canvasOffsetStep
    imul ecx
    cdq
    mov ecx, nowCanvasZoomLevel
    idiv ecx
    mov dist, eax
    ; control 键没有按下：移动
    invoke modifyWithBound, addr nowCanvasOffsetY, dist, 0, nowCanvasHeight
  .endif

  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect 掉整个画布，让 WM_PAINT 去更新
  xor eax, eax
  ret
HandleMouseWheel endp


; 当人为滚动滚动条的时候
HandleScroll proc 
  local scrollInfo : SCROLLINFO
  ; 垂直
  mov scrollInfo.cbSize, SIZEOF SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL 
  invoke GetScrollInfo, hCanvas, SB_VERT, addr scrollInfo
  m2m nowCanvasOffsetY, scrollInfo.nTrackPos
  
  ; 水平
  mov scrollInfo.cbSize, SIZEOF SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL 
  invoke GetScrollInfo, hCanvas, SB_HORZ, addr scrollInfo
  m2m nowCanvasOffsetX, scrollInfo.nTrackPos

  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
HandleScroll endp


; 将 drawDCBuf 按照合适的比例和偏移复制到 hCanvas 的 DC 上面
; 同时也重新绘制滚动条 & 更新pos
RenderBitmap proc
  ; 计算范围
  local tarRect : RECT
  local cRBP : POINT ; (canvas Right Bottom Point)
  local wRBP : POINT ; (window RIght Bottom Point)
  local hCanvasDC : HDC
  local hTempDC : HDC
  local hTempBrush : HBRUSH
  local hTempBitmap : HBITMAP
  local paintStruct : PAINTSTRUCT ; 似乎不太需要
  
  invoke GetDC, hCanvas ; 获取 DC 
  mov hCanvasDC, eax
  invoke CreateCompatibleDC, hCanvasDC ; 和创建 Buffer
  mov hTempDC, eax

  invoke GetClientRect, hCanvas, addr tarRect ; 获取显示范围
  invoke CreateCompatibleBitmap, hCanvasDC, tarRect.right, tarRect.bottom ;创建 画布大小的 Bitmap 一定要是 hCanvasDC
  mov hTempBitmap, eax
  invoke SelectObject, hTempDC, hTempBitmap
  invoke FillRect, hTempDC, addr tarRect, hBackgroundBrush ;这个是窗口的背景
  invoke DeleteObject, hTempBrush
  invoke ReleaseDC, hCanvas, hCanvasDC

  ; 伸缩，拷贝到画布上面
  m2m cRBP.x, tarRect.right
  m2m cRBP.y, tarRect.bottom
  invoke CoordWindowToCanvas, addr cRBP ; 获得绘制范围的逻辑坐标
  ; 绘制范围不能超过画布本身的大小
  mov eax, cRBP.x
  .if eax  >= nowCanvasWidth
    m2m cRBP.x, nowCanvasWidth
  .endif
  mov eax, cRBP.y
  .if eax >= nowCanvasHeight
    m2m cRBP.y, nowCanvasHeight
  .endif
  ; 在画布上实际要画的范围，从 (nowCanvasOffsetX, nowCanvasOfffsetY) 到 cRBP(原来的
  m2m wRBP.x, cRBP.x
  m2m wRBP.y, cRBP.y
  
  invoke CoordCanvasToWindow, addr wRBP ;转换为在画布窗口上实际的逻辑坐标
  sub wRBP.x, canvasMargin
  sub wRBP.y, canvasMargin ; 刨除边缘成为宽高

  mov ecx, cRBP.x
  mov edx, cRBP.y
  sub ecx, nowCanvasOffsetX 
  sub edx, nowCanvasOffsetY ; 刨除边缘变成宽高

  ; 按照缩放比例伸缩
  invoke StretchBlt,  hTempDC,     canvasMargin,     canvasMargin, wRBP.x, wRBP.y,\
                    drawDCBuf, nowCanvasOffsetX, nowCanvasOffsetY,    ecx,    edx,\
                     SRCCOPY
  ; 画橡皮
  .IF SetEraser == 1
    invoke GetEraserWidth
	mov EraserSize, eax
	invoke UpdateEraser
	invoke DrawEraser, hTempDC
  .ENDIF 
  
  ; 拷贝
  invoke BeginPaint, hCanvas, addr paintStruct
  mov hCanvasDC, eax
  invoke BitBlt, hCanvasDC, 0, 0, tarRect.right, tarRect.bottom,\
                 hTempDC, 0, 0, \
                 SRCCOPY 
  invoke EndPaint, hCanvas, addr paintStruct
  invoke ShowCursorPosition ;更新鼠标坐标
  ; 释放 / 删除创建的 DC 和 hDC 
  invoke DeleteDC, hTempDC
  invoke DeleteObject, hTempBitmap
  invoke UpdateCanvasScrollBar ; 因为可能有 Offset/大小的改变都需要重新绘制
  xor eax,eax
  ret 
RenderBitmap endp

; 画布的 proc
ProcWinCanvas proc hWnd, uMsg, wParam, lParam
  ;invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;窗口过程中不予处理的消息，传递给此函数
  ; ret
  mov eax, uMsg
  .if eax == WM_CREATE
    invoke crt_printf, CTEXT("create.")
    m2m hCanvas, hWnd
    invoke HandleCanvasCreate
  .elseif eax == WM_LBUTTONDOWN
    invoke HandleLButtonDown, wParam, lParam
;    invoke crt_printf,addr szLButtonDown
  .elseif eax == WM_LBUTTONUP
    invoke HandleLButtonUp, wParam, lParam
;    invoke crt_printf,addr szLButtonUp
  .elseif eax == WM_MOUSEMOVE
    invoke HandleMouseMove, wParam, lParam
;    invoke crt_printf,addr szMouseMoveCanvas
  .elseif eax == WM_MOUSELEAVE
    invoke HandleMouseLeave, wParam, lParam
  .elseif eax == WM_MOUSEWHEEL
    invoke HandleMouseWheel, wParam, lParam
  .elseif eax == WM_SIZE
    invoke UpdateCanvasPos
  .elseif eax == WM_PAINT
    invoke RenderBitmap
  .elseif eax == WM_ERASEBKGND
  .elseif eax == WM_HSCROLL 
    invoke HandleScroll
    ; invoke crt_printf, CTEXT("HSCROLL")
  .elseif eax == WM_VSCROLL
    invoke HandleScroll
    ; invoke crt_printf, CTEXT("VSCROLL")
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

  invoke SetWindowPos,hCanvas,HWND_TOP,mWinRect.left,ebx,ecx,edx,SWP_NOREDRAW
  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect 掉整个画布，让 WM_PAINT 去更新

  ret  
UpdateCanvasPos endp


; 在画布的范围和大小改变之后，更新滚动条的横纵范围和位置
UpdateCanvasScrollBar proc
  local canvasRect: RECT
  local scrollInfo: SCROLLINFO 

  ; 垂直
  mov scrollInfo.cbSize, sizeof SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL
  m2m scrollInfo.nMin, 0
  m2m scrollInfo.nPage, 5

  m2m scrollInfo.nMax, nowCanvasHeight
  m2m scrollInfo.nPos, nowCanvasOffsetY
  invoke SetScrollInfo , hCanvas, SB_VERT, addr scrollInfo, TRUE
  ; 水平
  mov scrollInfo.cbSize, sizeof SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL
  m2m scrollInfo.nMin, 0
  m2m scrollInfo.nPage, 5

  m2m scrollInfo.nMax, nowCanvasWidth
  m2m scrollInfo.nPos, nowCanvasOffsetX
  invoke SetScrollInfo , hCanvas, SB_HORZ, addr scrollInfo, TRUE
  ret 
UpdateCanvasScrollBar endp

UpdateCanvasScrollBar_backup proc
  local canvasRect: RECT
  local Pos : DWORD
  local Maximum : DWORD
  local scrollInfo: SCROLLINFO 

  invoke GetClientRect, hCanvas, addr canvasRect

  ; 垂直
  mov eax, nowCanvasHeight
  mov edx, 0
  mov ebx, nowCanvasZoomLevel
  mul ebx
  add eax, canvasMargin
  add eax, canvasMargin
  mov Maximum, eax

  mov edx, 0
  mov eax, nowCanvasOffsetY
  mov ebx, nowCanvasZoomLevel
  mul ebx
  add eax, canvasMargin
  mov Pos,eax


  mov scrollInfo.cbSize, sizeof SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL or SIF_DISABLENOSCROLL
  m2m scrollInfo.nMin, 0
  m2m scrollInfo.nPage, canvasRect.bottom

  m2m scrollInfo.nMax, Maximum
  m2m scrollInfo.nPos, Pos
  invoke SetScrollInfo , hCanvas, SB_VERT, addr scrollInfo, TRUE
  ; 水平
  mov eax, nowCanvasWidth
  mov edx, 0
  mov ebx, nowCanvasZoomLevel
  mul ebx
  add eax, canvasMargin
  add eax, canvasMargin
  mov Maximum, eax

  mov edx, 0
  mov eax, nowCanvasOffsetX
  mov ebx, nowCanvasZoomLevel
  mul ebx
  add eax, canvasMargin
  mov Pos,eax


  mov scrollInfo.cbSize, sizeof SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL or SIF_DISABLENOSCROLL
  m2m scrollInfo.nMin, 0
  m2m scrollInfo.nPage, canvasRect.right

  m2m scrollInfo.nMax, Maximum
  m2m scrollInfo.nPos, Pos
  invoke SetScrollInfo , hCanvas, SB_HORZ, addr scrollInfo, TRUE
  ret 
UpdateCanvasScrollBar_backup endp


; 当滚动条被滚动的时候
SetCanvasOffsetFromScrollBar proc
  local scrollInfo: SCROLLINFO 
  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
SetCanvasOffsetFromScrollBar endp

ResizeCanvas proc tempWidth:DWORD, tempHeight:DWORD
;TODO:调整画布大小
;调用UpdateHistoryBitmapFromDrawBuf函数将画布缩放拷贝到历史记录中
;增加撤销次数
;调用UpdateDrawBufFromHistoryBitmap再将Bitmap拷贝到缓冲区
;更新到hCanvas
  invoke UpdateHistoryBitmapFromDrawBuf,tempWidth,tempHeight
  invoke InvalidateRect, hCanvas, NULL, FALSE
  .if undoMaxLimit<64
    mov eax,undoMaxLimit
    inc eax
    mov undoMaxLimit,eax
  .endif
  invoke UpdateDrawBufFromHistoryBitmap
  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
ResizeCanvas endp

SetColorInTool proc index:DWORD, color:DWORD
    ; 绘制工具栏上的按钮位图
    ; 该函数根据index(前/背景色)和color颜色
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
  mov eax, @stcc.rgbResult
  .if index==0
     mov foregroundColor, eax
  .elseif index==1
     mov backgroundColor, eax
  .endif
  ret
SetColor endp

Undo proc
;TODO:撤销上一步操作
;将画板恢复到historyBitmapIndex-1的状态
 .if undoMaxLimit>0
   mov eax,undoMaxLimit
   dec eax
   mov undoMaxLimit,eax
   mov eax,historyBitmapIndex
   add eax,63
   .if eax>=64
      sub eax,64
   .endif
   mov historyBitmapIndex,eax
   invoke UpdateDrawBufFromHistoryBitmap
   invoke InvalidateRect, hCanvas, NULL, FALSE
 .endif
 ret
Undo endp

OpenFileFromDisk proc
  local @stOpenFile:OPENFILENAME

  invoke RtlZeroMemory,addr @stOpenFile,sizeof @stOpenFile
  mov @stOpenFile.lStructSize,sizeof @stOpenFile
  m2m @stOpenFile.hwndOwner,hWinMain
  mov @stOpenFile.lpstrFilter,offset szFilter
  mov @stOpenFile.lpstrFile,offset filePath
  mov @stOpenFile.nMaxFile,MAX_PATH
  mov @stOpenFile.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
  invoke GetOpenFileName,addr @stOpenFile
;---test for debug---
  ;.if eax
  ;    invoke MessageBox,hWinMain,addr filePath,\
  ;          addr szMainWindowTitle,MB_OK
  ;.endif
;---test for debug---
  ret
OpenFileFromDisk endp

SaveBitmapAs proc
  local @stOpenFile:OPENFILENAME

  invoke RtlZeroMemory,addr @stOpenFile,sizeof @stOpenFile
  mov @stOpenFile.lStructSize,sizeof @stOpenFile
  m2m @stOpenFile.hwndOwner,hWinMain
  mov @stOpenFile.lpstrFilter,offset szFilter
  mov @stOpenFile.lpstrFile,offset filePath
  mov @stOpenFile.nMaxFile,MAX_PATH
  mov @stOpenFile.Flags,OFN_PATHMUSTEXIST
  mov @stOpenFile.lpstrDefExt,offset szDefExt
  invoke GetSaveFileName,addr @stOpenFile
;------test for debug------
  ;.if eax
  ;   invoke MessageBox,hWinMain,addr filePath,\
  ;         addr szMainWindowTitle,MB_OK
  ;.endif
;------test for debug------
  ret 
SaveBitmapAs endp

;对话框的 proc
DialogProc proc hWnd,uMsg,wParam,lParam
   mov eax,uMsg
   .if eax == WM_INITDIALOG
      invoke SetDlgItemInt,hWnd,IDC_WIDTH,nowCanvasWidth,FALSE
      invoke SetDlgItemInt,hWnd,IDC_HEIGHT,nowCanvasHeight,FALSE
   .elseif eax == WM_COMMAND
      .if wParam == ID_OK
         invoke GetDlgItemInt,hWnd,IDC_WIDTH,NULL,FALSE
         mov tempCanvasWidth,eax
         invoke GetDlgItemInt,hWnd,IDC_HEIGHT,NULL,FALSE
         mov tempCanvasHeight,eax
         invoke EndDialog,hWnd,1
      .elseif wParam ==ID_CANCEL
         invoke EndDialog,hWnd,0
      .endif
   .elseif eax == WM_CLOSE
      invoke EndDialog,hWnd,0
   .endif
   xor eax,eax
   ret
DialogProc endp


ClearCanvas proc
;TODO:清空画板为背景色
  LOCAL @hTempDC:HDC
  LOCAL @hCanvasDC:HDC
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @tempRect:RECT
  LOCAL @hTempBrush:HBRUSH
  pushad
  mov eax,historyBitmapIndex
  inc eax
  .if eax>=64
    sub eax,64
  .endif
  mov historyBitmapIndex,eax
  mov edx, 0
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx

  invoke DeleteObject, (mBitmap PTR [esi]).bitmap

  invoke GetDC,hCanvas
  mov @hCanvasDC,eax
  invoke CreateCompatibleDC, @hCanvasDC
  mov @hTempDC, eax
  invoke CreateCompatibleBitmap, @hCanvasDC, nowCanvasWidth, nowCanvasHeight
  mov @hTempBitmap, eax
  invoke ReleaseDC, hCanvas,@hCanvasDC 
  invoke SelectObject,@hTempDC, @hTempBitmap
  invoke CreateSolidBrush, backgroundColor
  mov @hTempBrush, eax
  mov @tempRect.top, 0
  mov @tempRect.left, 0
  m2m @tempRect.right, nowCanvasWidth
  m2m @tempRect.bottom, nowCanvasHeight
  invoke FillRect,@hTempDC, addr @tempRect,@hTempBrush
  invoke DeleteDC,@hTempDC

  mov eax, historyBitmapIndex
  mov ebx, SIZEOF mBitmap ; 这个结构体的字节数
  mul ebx
  mov esi, eax
  lea ebx, historyBitmap
  add esi, ebx
  m2m (mBitmap PTR [esi]).bitmap,@hTempBitmap
  m2m (mBitmap PTR [esi]).nWidth,nowCanvasWidth
  m2m (mBitmap PTR [esi]).nHeight,nowCanvasHeight

  invoke UpdateDrawBufFromHistoryBitmap
  invoke InvalidateRect, hCanvas, NULL, FALSE
  popad
  ret
ClearCanvas endp

CreateNewFile proc
;TODO:新建一个画布
;将原来的路径改为默认
;将existFilePath置0
   mov backgroundColor,0ffffffh
   invoke SetColorInTool,1,backgroundColor
   mov foregroundColor,0
   invoke SetColorInTool,0,foregroundColor
   mov existFilePath,0
   invoke crt_strcpy,addr filePath,addr defaultPath
   invoke HandleCanvasCreate
   ret
CreateNewFile endp

ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
;TODO:主窗口的proc 
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
     invoke DeleteObject,@hBmp
     invoke SetColorInTool,0,foregroundColor        ; 黑色
     invoke SetColorInTool,1,backgroundColor        ; 白色
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
     invoke LoadCursor,hInstance,IDC_DRAG
     mov hCurHand,eax
     invoke LoadCursor,hInstance,IDC_GRAB
     mov hCurGrab,eax
     invoke LoadCursor,hInstance,IDC_GRABBING
     mov hCurGrabbing,eax
     invoke LoadCursor,hInstance,IDC_BUCKET
     mov hCurBucket,eax
	 invoke LoadCursor,hInstance,IDC_EMPTY
     mov hCurEmpty,eax
  ;-----------------创建画布窗口--------------------
     invoke CreateCanvasWin
	 
	 invoke ShowCursorPosition
   .elseif eax == WM_SIZE
     ;使状态栏和工具栏随缩放而缩放
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
     ;调整画布的位置
     invoke UpdateCanvasPos
     ;invoke SendMessage,hCanvas,uMsg,wParam,lParam
  .elseif eax == WM_COMMAND
     mov eax,wParam
     movzx eax,ax
     ;菜单栏/工具栏点击铅笔/橡皮按钮，进行选中并改变光标
     .if eax == ID_PEN || eax == ID_ERASER
        mov ebx,eax
        push ebx
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_DRAG,eax,MF_BYCOMMAND
        pop ebx
        mov eax,ebx
        .if eax == ID_PEN
			mov SetEraser, 0
            invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurPen
        .elseif eax == ID_ERASER
			mov SetEraser, 1
			invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurEmpty
         .endif
     ;菜单栏/工具栏选中油桶
     .elseif eax == ID_BUCKET
		mov SetEraser, 0
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_DRAG,eax,MF_BYCOMMAND
        invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurBucket
     .elseif eax == ID_DRAG
		mov SetEraser, 0
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_DRAG,eax,MF_BYCOMMAND
        invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrab
     ;菜单栏改变笔/橡皮的像素大小，进行选中
     .elseif eax>=ID_ONE_PIXEL && eax<=ID_FOUR_PIXEL
         invoke CheckMenuRadioItem,hMenu,ID_ONE_PIXEL,ID_FOUR_PIXEL,eax,MF_BYCOMMAND
     .elseif eax>=ID_ERA_TWO_PIXEL && eax<=ID_ERA_SIXTEEN_PIXEL
         mov ebx,eax
         push ebx
         invoke CheckMenuRadioItem,hMenu,ID_ERA_TWO_PIXEL,ID_ERA_SIXTEEN_PIXEL,eax,MF_BYCOMMAND
         pop ebx
         mov eax,ebx
     ;菜单栏退出功能
     .elseif eax == ID_FOR_COLOR
         invoke SetColor,0
     .elseif eax == ID_BACK_COLOR
         invoke SetColor,1
     .elseif eax == ID_QUIT
         call Quit
     .elseif eax == ID_UNDO
         invoke Undo
     .elseif eax == ID_CANVAS_SIZE
         invoke DialogBoxParam,hInstance,IDD_DIALOG1,hWinMain,offset DialogProc,0
         .if eax
            .if tempCanvasWidth>0 && tempCanvasHeight>0
               invoke ResizeCanvas,tempCanvasWidth,tempCanvasHeight
            .endif
         .endif
     .elseif eax == ID_OPEN
         invoke OpenFileFromDisk
         .if eax
           invoke LoadBitmapFromFile
         .endif
     .elseif eax == ID_SAVE_AS
         invoke SaveBitmapAs
         .if eax
           invoke SaveBitmapToFile
           mov existFilePath,1
         .endif
     .elseif eax == ID_SAVE
         .if existFilePath == 0
             invoke SaveBitmapAs
             .if eax
                invoke SaveBitmapToFile
                mov existFilePath,1
             .endif
         .else
             invoke SaveBitmapToFile
         .endif
     .elseif eax == ID_CLEAR
         invoke ClearCanvas
     .elseif eax == ID_NEW
         invoke CreateNewFile
     .endif 
  .elseif eax == WM_MOUSEMOVE

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
  mov hBackgroundBrush,eax
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