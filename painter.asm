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
;---------------EQU��ֵ����-----------------
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

;-----------------����ԭ������-------------------
WinMain PROTO                                     ;������
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;���������е���Ϣ�������
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;�������������е���Ϣ�������
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
  hInstance         dd ?                   ;��ģ��ľ��
  hWinMain          dd ?                   ;���ھ��
  hCanvas           dd ?                   ;�������
  hMenu             dd ?                   ;�˵����
  hWinToolBar       dd ?                   ;������
  hWinStatusBar     dd ?                   ;״̬��
  hImageListControl dd ?
  hCurPen           dd ?                   ;�����
  hCurEraser_2      dd ?                   ;��Ƥ��� 2����
  hCurEraser_4      dd ?
  hCurEraser_8      dd ?
  hCurEraser_16     dd ?
  hCurBucket        dd ?                   ;��Ͱ���
  hCurHand          dd ?                   ;��קС�ֹ�� ;�õ�������
  hCurGrab          dd ?                   ;��ק���
  hCurGrabbing      dd ?                   ;������ק���
  
  hCurEmpty    		dd ?					;����Ƥʹ��

  hCurEraser		HDC NULL					;�޸�֮�����Ƥ���
  hEraserBitmap		dd NULL					;��Ƥ��ͼ
  
  EraserSize		dword	20				;��Ƥ�ı߳�
  SetEraser			dword	0				;�Ƿ�����Ƥ����Ϊ1


  CursorPosition	POINT <0,0>			    	;����߼�λ��
  CoordinateFormat	byte  "%d,%d",0			;��ʾ�����ʽ
  TextBuffer		byte  24 DUP(0)	     		;�������
  
  
  foregroundColor       dd 0                    ;ǰ��ɫ
  backgroundColor       dd 0ffffffh             ;����ɫ
  customColorBuffer     dd 16 dup(?)            ;��ɫ�������������Զ�����ɫ

  ; ������ʹ�õı���
  ; ������ʵ������
  canvasMargin            equ 5
  ; ���µĴ�С��Ϊ�߼����أ�������Ļ��ʵ����ʾ�ĵ�������
  defaultCanvasWidth      equ 800
  defaultCanvasHeight     equ 600
  maxCanvasZoomLevel      equ 10
  canvasOffsetStep        equ 10

  nowCanvasWidth          dd ?
  nowCanvasHeight         dd ? 
  nowCanvasOffsetX        dd 0
  nowCanvasOffsetY        dd 0
  nowCanvasZoomLevel      dd 1 ; һ���߼���������Ļ��ռ�ݼ���ʵ�����صĿ��
  tempCanvasWidth         dd ?
  tempCanvasHeight        dd ?
  hBackgroundBrush       HBRUSH ?
  
  historyNums          equ 64      ;�洢 64 ����ʷ��¼
  historyBitmap        mBitmap historyNums DUP(<>)  ;��ʷ��¼��λͼ
  historyBitmapIndex   dd  0       ;��ǰ��ʷ��¼λͼ�м�����������������λͼ����
  ; baseDCBuf          HDC ?       ; ĳ�λ���λͼ�Ļ�������
  drawDCBuf            HDC ?       ; �����˵�ǰ���ƵĻ���
  undoMaxLimit         dd  0       ; ������������
  startCanvasOffsetX   dd  0       ; LButtonDown ʱ��� Offset�������϶�
  startCanvasOffsetY   dd  0
  startCursorPosition     POINT <?,?> ; ĳ�� LButtonDown ʱ��� Cursor Position
  lastCursorPosition      POINT <?,?> ; �ϴ� MouseMove ʱ��� Cursor Position
  
  filePath             BYTE  '�ޱ���.bmp',0 ;��ǰ���ڱ༭���ļ�·��
  defaultPath          BYTE  '�ޱ���.bmp',0 ;Ĭ���ļ�·��
  existFilePath        dd  0           ;�ж�filePath�Ƿ����
  
  szFilename           db MAX_PATH DUP(?)
  stToolBar  equ   this byte  ;���幤������ť
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;�½�
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;��
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;���� 
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����
    TBBUTTON <3,ID_DRAG,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP,0,0,NULL>;��קС��
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL>;����
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP, 0, 0, NULL>;��Ƥ
    TBBUTTON <9,ID_BUCKET,TBSTATE_ENABLED,TBSTYLE_CHECKGROUP,0,0,NULL>;��Ͱ
    TBBUTTON <6,NULL,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,NULL>;�ָ���
    TBBUTTON <10,ID_FOR_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;ǰ��ɫ
    TBBUTTON <11,ID_BACK_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����ɫ
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle     db "��ͼ",0         ;�����ڱ���
  szWindowClassName     db "MainWindow",0      ;�˵�������
  szToolBarClassName    db "ToolbarWindow32",0         
  szStatusBarClassName  db "msctls_statusbar32",0       
  szCanvasClassName     db "����", 0
  szFilter              db 'λͼ(*.bmp)',0,'*.bmp',0;���ļ����ļ�������
  szDefExt              db 'bmp',0;�������չ��

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

; �궨��
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

; �н���޸�
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

; Windows ��������� offset ��
; �� Canvas �߼������

; ������� Canvas Windows Client Area ����������ת����Ϊ Canvas ���߼�����
CoordWindowToCanvas proc coordWindow: PTR POINT
  ; invoke crt_printf, CTEXT("before transformation: ")
  mov esi, coordWindow

  sub (POINT PTR [esi]).x, canvasMargin
  sub (POINT PTR [esi]).y, canvasMargin
  mov ebx, nowCanvasZoomLevel
  ; x ����
  mov eax, (POINT PTR [esi]).x
  mov edx, 0
  div ebx
  add eax, nowCanvasOffsetX
  mov (POINT PTR [esi]).x, eax
  ; y ����
  mov eax, (POINT PTR [esi]).y
  mov edx, 0
  div ebx
  add eax, nowCanvasOffsetY
  mov (POINT PTR [esi]).y, eax
  ret 
CoordWindowToCanvas endp

; �� Canvas ���߼�����ת����Ϊ����� Canvas Windows Client Area ����������
CoordCanvasToWindow proc coordCanvas: PTR POINT
  ; ������ڻ������Ͻǵ����·��������
  mov esi, coordCanvas
  mov ebx, nowCanvasZoomLevel
  ; x ����
  mov eax, (POINT PTR [esi]).x
  sub eax, nowCanvasOffsetX
  mov edx, 0
  mul ebx
  add eax, canvasMargin
  mov (POINT PTR [esi]).x, eax
  ; y ����
  mov eax, (POINT PTR [esi]).y
  sub eax, nowCanvasOffsetY
  mov edx, 0
  mul ebx
  add eax, canvasMargin
  mov (POINT PTR [esi]).y, eax
  ret   
CoordCanvasToWindow endp

Quit proc
  invoke DestroyWindow,hWinMain           ;ɾ������
  invoke PostQuitMessage,NULL             ;����Ϣ�����в���һ��WM_QUIT��Ϣ
  ret
Quit endp

; ����һ����Ƥ
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

; ɾ����Ƥ��������
DestoryEraser proc
    invoke DeleteObject, hEraserBitmap
    mov hEraserBitmap, NULL
    invoke DeleteDC, hCurEraser
    mov hCurEraser, NULL
    ret
DestoryEraser endp

; ������Ƥͼ��
UpdateEraser proc
    .if hCurEraser != NULL
        invoke DestoryEraser
    .endif
    invoke CreateEraser
    ret
UpdateEraser endp

; ��ȡ����߼�����
; �ŵ� cursorPos ����
GetCursorPosition proc cursorPos : PTR POINT
  local point:POINT
  local rect:RECT
  local ifout:dword		;�Ƿ񳬳���������
  invoke GetCursorPos, addr point
  invoke GetClientRect, hCanvas, addr rect
  
  ; �任����
  invoke ScreenToClient, hCanvas, addr point
  
  ; �жϳ�������
  ; ����� rect ������� Client �ģ���Ҫ�ȱ任����

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

; ��ʾ�����߼�����
ShowCursorPosition proc
  pushad
  invoke GetCursorPosition, offset CursorPosition
  popad
  invoke sprintf, addr TextBuffer, offset CoordinateFormat, CursorPosition.x, CursorPosition.y ; ��ʽ��������ַ���
  invoke SendMessage, hWinStatusBar, SB_SETTEXT, 0, addr TextBuffer ; ��ʾ����
  ret
ShowCursorPosition endp

; ����λͼ
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
    
	; ��ȡ��Ƥ��ʼ����
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
	
	; ��ȡ��������
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
    
	; ����任
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
    
	; ������Ƥ��
    invoke BitBlt, hdc, canvasFromX, canvasFromY, eraserWidth, eraserHeight, hCurEraser, eraserFromX, eraserFromY, SRCCOPY
    
    ret
DrawEraser endp

; ���� HistoryBitmap ����һ����DrawDCBuf��ͬʱҪ���»����Ŀ�͸�
UpdateDrawBufFromHistoryBitmap proc
; ���츨����hTempDC
; �Ƚ�historyBitmap�����һ���󶨵���ʱHDC��
; �ٰ���ʱHDC���Ƹ���HDC
  LOCAL @hTempDC:HDC
  LOCAL @hCanvasDC:HDC
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @nWidth: DWORD
  LOCAL @nHeight: DWORD
  local @newDrawBufBitmap: HBITMAP

  pushad
  ; �� history ��ȡ�����һ��
  mov eax, historyBitmapIndex
  mov edx, 0
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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

  ; �½�һ������
  invoke CreateCompatibleBitmap, @hCanvasDC, @nWidth, @nHeight
  mov @newDrawBufBitmap, eax ; ��ɾ���������к�ɾ
  invoke SelectObject, drawDCBuf, @newDrawBufBitmap
  invoke DeleteObject, eax ;ɾ���ϵ� Bitmap
  
  invoke ReleaseDC, hCanvas,@hCanvasDC 
  invoke BitBlt,drawDCBuf,0,0,@nWidth,@nHeight,@hTempDC,0,0,SRCCOPY
  invoke DeleteDC,@hTempDC

  m2m nowCanvasWidth, @nWidth
  m2m nowCanvasHeight, @nHeight

  popad
  ret
UpdateDrawBufFromHistoryBitmap endp

;����ǰdrawDCBufת��ΪBitmap������HistoryBitmap��
UpdateHistoryBitmapFromDrawBuf proc, nWidth:DWORD,nHeight:DWORD
;�������Ϊ��ǰdrawDCBuf�Ŀ�Ⱥ͸߶�
;ʵ�ֹ��̣�
;       �Ƚ�historyBitmapIndex+1��Ϊ��λͼ������
;       ����Ҫ��ת���ð�
;       ��ԭ����λ�þ����Ӧ��λͼ�ͷţ���˳�ʼ��ʱһ��Ҫ������64����λͼ��Ӧ��historyBitmap?��
;       �ٽ�drawDCBuf���Ƶ���������DC�ϣ�Ȼ�󱣴�λͼ�����historyBitmap
;ע���˺�����û���ж��Ƿ����ӳ������ޣ����øú���ʱ��Ҫ�ں��油��
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
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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

; ����������ʷ�����ҰѲ����� bitmap �ŵ���һ��λ����
InitHistory proc bitmap: HBITMAP, nWidth: DWORD, nHeight:DWORD

  lea esi, historyBitmap
  m2m (mBitmap PTR [esi]).bitmap ,bitmap
  m2m (mBitmap PTR [esi]).nWidth ,nWidth
  m2m (mBitmap PTR [esi]).nHeight,nHeight

  mov historyBitmapIndex,0
  mov undoMaxLimit,0
  ret
InitHistory endp

; ����������
; �������ʼ��ʱ�����һ��
HandleCanvasCreate proc
  local hCanvasDC : HDC
  local hTempDC   : HDC
  local initBitmap: HBITMAP
  local hTempBrush: HBRUSH
  local tempRect  : RECT
  
  invoke UpdateCanvasPos ; ����λ��

  ; �½�һ��Ĭ�ϵĻ���
  invoke GetDC, hCanvas
  mov hCanvasDC, eax
  invoke CreateCompatibleDC, hCanvasDC
  mov drawDCBuf, eax
  invoke CreateCompatibleBitmap, hCanvasDC, defaultCanvasWidth, defaultCanvasHeight  
  mov initBitmap, eax ;����ɾ��������� historyBitmap ����ȥ����
  invoke CreateCompatibleDC, hCanvasDC
  mov hTempDC, eax
  invoke ReleaseDC, hCanvas, hCanvasDC

  ; Ϳ��ȫ������ɫ
  invoke SelectObject, hTempDC, initBitmap
  invoke CreateSolidBrush, backgroundColor
  mov hTempBrush, eax
  mov tempRect.top, 0
  mov tempRect.left, 0
  mov tempRect.right, defaultCanvasWidth
  mov tempRect.bottom, defaultCanvasHeight
  invoke FillRect, hTempDC, addr tempRect, hTempBrush
  ; ��ʼ���� historyBitmap ����
  invoke InitHistory, initBitmap, defaultCanvasWidth, defaultCanvasHeight  
  invoke DeleteObject, hTempBrush
  invoke DeleteDC, hTempDC
  
  invoke UpdateDrawBufFromHistoryBitmap       ; �� historyBitmap ǣ���� DrawBuf ����ȥ
  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect �������������� WM_PAINT ȥ����
  ret
HandleCanvasCreate endp

; ���ļ�����
LoadBitmapFromFile proc
; TODO:��·��filePath�е�λͼ���µ�DrawBuf
;      ����������ص�historyBitmap��ӦIndex
  LOCAL @hTempBitmap:HBITMAP
  LOCAL @hWinDC:HDC
  LOCAL @hTempDC:HDC

  invoke crt_printf,addr szOutput
  ;��·��filePath�е�λͼ���µ�DrawBuf
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

  ;��DrawBuf�е�λͼ����historyBitmap��ǰIndex
  ;����UpdateHistoryBitmapFromDrawBuf����µ�Index+1��λ��
  ;�����Ƚ�historyBitmapIndex����1
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
  ;����λͼ��ɫ��ʽ����Ⱥ͸߶�
  invoke GetObject,hBmp,sizeof BITMAP,addr @bmp
  movzx eax,@bmp.bmPlanes
  movzx ebx,@bmp.bmBitsPixel
  mul ebx
  mov @cClrBits,eax
  ;����ɫ��ʽת��Ϊλ��
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
  ;Ϊ BITMAPIINFO �ṹ�����ڴ�
  ;����һ�� BITMAPINFOHEADER �ṹ��һ�� RGBQUAD ����
  .if @cClrBits < 24
     mov eax,1
     mov ecx,@cClrBits
     shl eax,cl
     mov ecx,sizeof RGBQUAD
     mul ecx
     add eax,sizeof BITMAPINFOHEADER
     invoke LocalAlloc,LMEM_FIXED or LMEM_ZEROINIT,eax
     mov @pbmi,eax
  ;ÿ���� 24 λ��ÿ���� 32 λ�ĸ�ʽû��RGBQUAD
  .else
     invoke LocalAlloc,LMEM_FIXED or LMEM_ZEROINIT,sizeof BITMAPINFOHEADER
     mov @pbmi,eax
  .endif
  ;��ʼ�� BITMAPIINFO �ṹ�е��ֶ�
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
  ;���λͼδѹ���������� BI_RGB ��־
  m2m (BITMAPINFO PTR [esi]).bmiHeader.biCompression,BI_RGB
  ;������ɫ�����е��ֽ���������������洢�� biSizeImage ��
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

;���浽�ļ�
SaveBitmapToFile proc
;TODO:��historyBitmap���һ�ű��浽·��filePath
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
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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

; ����������£�Ҳ���ǿ�ʼ��ͼ
HandleLButtonDown proc wParam:DWORD, lParam:DWORD
  ; ���� HistoryBitmap �� Buffer ��
  invoke UpdateDrawBufFromHistoryBitmap
  ; ��Ҫ��¼�ʼ�ĵ�
  invoke GetCursorPosition, offset startCursorPosition
  m2m lastCursorPosition.x, startCursorPosition.x
  m2m lastCursorPosition.y, startCursorPosition.y
  m2m startCanvasOffsetX, nowCanvasOffsetX
  m2m startCanvasOffsetY, nowCanvasOffsetY
  ; TODO : ������϶��Ļ�Ҫ���Ĺ��
  invoke GetMenuState,hMenu,ID_DRAG,MF_BYCOMMAND
  .if eax & MF_CHECKED
     invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrabbing
  .endif  
  invoke InvalidateRect, hCanvas, NULL, FALSE
  xor eax, eax
  ret
HandleLButtonDown endp


; �������̧��Ҳ���ǽ�����ͼ
HandleLButtonUp proc wParam:DWORD, lParam:DWORD
  ; ������̧��
  ; �� DrawBuf �� Bitmap ���õ� HistoryBitmap ��
  ; ��������+1
  ; ����������Ϳ
  local nowCursorPos : POINT
  invoke GetMenuState,hMenu,ID_DRAG,MF_BYCOMMAND
  .if eax & MF_CHECKED
     invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrab
  .endif 
  invoke GetMenuState,hMenu,ID_BUCKET,MF_BYCOMMAND
  .if eax & MF_CHECKED
    invoke CreateSolidBrush, foregroundColor ; ���ӱ�ˢ
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

; ��ȡ�ʵĿ��
; �ڷ���ֵ�з��رʵĿ��
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

; ��ȡ��Ƥ�Ŀ��
; �ڷ���ֵ�л�ȡ��Ƥ�Ŀ��
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

; ��������ƶ���Ҳ�������ڻ�ͼ
HandleMouseMove proc wParam:DWORD, lParam:DWORD
  local nowCursor : POINT
  ; ������û�а��£���û����
  ; ������û�а��£���û����
  .if !(wParam & MK_LBUTTON)
    jmp final
  .endif
  invoke ShowCursorPosition ; ��ʾ��ǰ����
  
  invoke GetCursorPosition, addr nowCursor; ���µ�ǰ���λ��

  ; ���������仯��Ҳ���ǿ����������ƵĲ���
  ; ���ڱʺ���Ƥ����Ҫ���¡����µ�����λ�á�
  ; ���ڱʺ���Ƥ��������Ϊ���� MouseMove ֮���ʱ��̣ܶ����ֱ����ֱ��
  invoke GetMenuState, hMenu, ID_PEN, MF_BYCOMMAND  
  .if eax & MF_CHECKED ; ѡ����� PEN
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
  .if eax & MF_CHECKED ; ѡ����� ERASER
    invoke MoveToEx, drawDCBuf, lastCursorPosition.x, lastCursorPosition.y, NULL
    invoke GetEraserWidth
    invoke CreatePen, PS_SOLID, eax, backgroundColor
    invoke SelectObject, drawDCBuf, eax
    invoke LineTo, drawDCBuf, nowCursor.x, nowCursor.y
    m2m lastCursorPosition.x, nowCursor.x
    m2m lastCursorPosition.y, nowCursor.y
    jmp final
  .endif
  ; TODO: �ж�һ���Ƿ����϶� Ŀǰ��Ϊ����ûѡ�еĶ����϶�
  invoke GetMenuState, hMenu, ID_DRAG, MF_BYCOMMAND  
  .if eax & MF_CHECKED
    m2m nowCanvasOffsetX, startCanvasOffsetX
    m2m nowCanvasOffsetY, startCanvasOffsetY
    invoke GetCursorPosition, addr nowCursor; �ھ������¼��㵱ǰ���λ��
    mov eax, nowCursor.x
    sub eax, startCursorPosition.x
    invoke modifyWithBound, addr nowCanvasOffsetX, eax, 0, nowCanvasWidth
    mov eax, nowCursor.y
    sub eax, startCursorPosition.y
    invoke modifyWithBound, addr nowCanvasOffsetY, eax, 0, nowCanvasHeight 
    
    jmp final
  .endif
  invoke UpdateDrawBufFromHistoryBitmap    
  ; ������Ǳʺ���Ƥ���������ģ������¸��� HistoryBitmap �� Buffer ��
  ; ��ȡ��ǰ�����λ�ã����ڵ��߼����꣩����Ҫ��������ϵ�任ת�����������߼�����
  ; Ȼ���������ȥ�����Ρ�Բ�Ǿ���֮���


final:
  invoke InvalidateRect, hCanvas,NULL,FALSE
  xor eax, eax
  ret
HandleMouseMove endp

; ��������ƶ������壬Ŀǰû�뵽ûʲôҪ���ģ�
HandleMouseLeave proc wParam:DWORD, lParam:DWORD
  mov TextBuffer, 0
  invoke SendMessage, hWinStatusBar, SB_SETTEXT, 0, addr TextBuffer ; �������꣬��û���ã�
  
  xor eax,eax
  ret
HandleMouseLeave endp

;����������
; ���� Ctrl ʱ�򣬶�Ӧ���Ų���
; û�� Ctrl ��ʱ�򣬶�Ӧ�����ƶ�����
HandleMouseWheel proc wParam:DWORD, lParam:DWORD
  local dist: SDWORD

  mov ax, SWORD PTR [wParam+2] ; ȡ�������ֽ�
  movsx eax, ax
  cdq
  mov ecx, 120
  idiv ecx
  mov dist, eax
  ; invoke crt_printf, CTEXT("key state:%d",0Ah,0Dh), dist


  .if wParam & 08h
    ; control �������ˣ�����
    invoke modifyWithBound, addr nowCanvasZoomLevel, dist, 1, maxCanvasZoomLevel
    
  .else
    mov eax, dist
    mov ecx, canvasOffsetStep
    imul ecx
    cdq
    mov ecx, nowCanvasZoomLevel
    idiv ecx
    mov dist, eax
    ; control ��û�а��£��ƶ�
    invoke modifyWithBound, addr nowCanvasOffsetY, dist, 0, nowCanvasHeight
  .endif

  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect �������������� WM_PAINT ȥ����
  xor eax, eax
  ret
HandleMouseWheel endp


; ����Ϊ������������ʱ��
HandleScroll proc 
  local scrollInfo : SCROLLINFO
  ; ��ֱ
  mov scrollInfo.cbSize, SIZEOF SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL 
  invoke GetScrollInfo, hCanvas, SB_VERT, addr scrollInfo
  m2m nowCanvasOffsetY, scrollInfo.nTrackPos
  
  ; ˮƽ
  mov scrollInfo.cbSize, SIZEOF SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL 
  invoke GetScrollInfo, hCanvas, SB_HORZ, addr scrollInfo
  m2m nowCanvasOffsetX, scrollInfo.nTrackPos

  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
HandleScroll endp


; �� drawDCBuf ���պ��ʵı�����ƫ�Ƹ��Ƶ� hCanvas �� DC ����
; ͬʱҲ���»��ƹ����� & ����pos
RenderBitmap proc
  ; ���㷶Χ
  local tarRect : RECT
  local cRBP : POINT ; (canvas Right Bottom Point)
  local wRBP : POINT ; (window RIght Bottom Point)
  local hCanvasDC : HDC
  local hTempDC : HDC
  local hTempBrush : HBRUSH
  local hTempBitmap : HBITMAP
  local paintStruct : PAINTSTRUCT ; �ƺ���̫��Ҫ
  
  invoke GetDC, hCanvas ; ��ȡ DC 
  mov hCanvasDC, eax
  invoke CreateCompatibleDC, hCanvasDC ; �ʹ��� Buffer
  mov hTempDC, eax

  invoke GetClientRect, hCanvas, addr tarRect ; ��ȡ��ʾ��Χ
  invoke CreateCompatibleBitmap, hCanvasDC, tarRect.right, tarRect.bottom ;���� ������С�� Bitmap һ��Ҫ�� hCanvasDC
  mov hTempBitmap, eax
  invoke SelectObject, hTempDC, hTempBitmap
  invoke FillRect, hTempDC, addr tarRect, hBackgroundBrush ;����Ǵ��ڵı���
  invoke DeleteObject, hTempBrush
  invoke ReleaseDC, hCanvas, hCanvasDC

  ; ��������������������
  m2m cRBP.x, tarRect.right
  m2m cRBP.y, tarRect.bottom
  invoke CoordWindowToCanvas, addr cRBP ; ��û��Ʒ�Χ���߼�����
  ; ���Ʒ�Χ���ܳ�����������Ĵ�С
  mov eax, cRBP.x
  .if eax  >= nowCanvasWidth
    m2m cRBP.x, nowCanvasWidth
  .endif
  mov eax, cRBP.y
  .if eax >= nowCanvasHeight
    m2m cRBP.y, nowCanvasHeight
  .endif
  ; �ڻ�����ʵ��Ҫ���ķ�Χ���� (nowCanvasOffsetX, nowCanvasOfffsetY) �� cRBP(ԭ����
  m2m wRBP.x, cRBP.x
  m2m wRBP.y, cRBP.y
  
  invoke CoordCanvasToWindow, addr wRBP ;ת��Ϊ�ڻ���������ʵ�ʵ��߼�����
  sub wRBP.x, canvasMargin
  sub wRBP.y, canvasMargin ; �ٳ���Ե��Ϊ���

  mov ecx, cRBP.x
  mov edx, cRBP.y
  sub ecx, nowCanvasOffsetX 
  sub edx, nowCanvasOffsetY ; �ٳ���Ե��ɿ��

  ; �������ű�������
  invoke StretchBlt,  hTempDC,     canvasMargin,     canvasMargin, wRBP.x, wRBP.y,\
                    drawDCBuf, nowCanvasOffsetX, nowCanvasOffsetY,    ecx,    edx,\
                     SRCCOPY
  ; ����Ƥ
  .IF SetEraser == 1
    invoke GetEraserWidth
	mov EraserSize, eax
	invoke UpdateEraser
	invoke DrawEraser, hTempDC
  .ENDIF 
  
  ; ����
  invoke BeginPaint, hCanvas, addr paintStruct
  mov hCanvasDC, eax
  invoke BitBlt, hCanvasDC, 0, 0, tarRect.right, tarRect.bottom,\
                 hTempDC, 0, 0, \
                 SRCCOPY 
  invoke EndPaint, hCanvas, addr paintStruct
  invoke ShowCursorPosition ;�����������
  ; �ͷ� / ɾ�������� DC �� hDC 
  invoke DeleteDC, hTempDC
  invoke DeleteObject, hTempBitmap
  invoke UpdateCanvasScrollBar ; ��Ϊ������ Offset/��С�ĸı䶼��Ҫ���»���
  xor eax,eax
  ret 
RenderBitmap endp

; ������ proc
ProcWinCanvas proc hWnd, uMsg, wParam, lParam
  ;invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺���
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
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺���
    ret ; ����ط�����Ҫ ret ����ΪҪ���� DefWindowProc �ķ���ֵ
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

; ���»�����λ��
UpdateCanvasPos proc uses ecx edx ebx
  local mWinRect:RECT
  local StatusBarRect:RECT
  local ToolBarRect:RECT
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

  invoke SetWindowPos,hCanvas,HWND_TOP,mWinRect.left,ebx,ecx,edx,SWP_NOREDRAW
  invoke InvalidateRect, hCanvas, NULL, FALSE ; invalidaterect �������������� WM_PAINT ȥ����

  ret  
UpdateCanvasPos endp


; �ڻ����ķ�Χ�ʹ�С�ı�֮�󣬸��¹������ĺ��ݷ�Χ��λ��
UpdateCanvasScrollBar proc
  local canvasRect: RECT
  local scrollInfo: SCROLLINFO 

  ; ��ֱ
  mov scrollInfo.cbSize, sizeof SCROLLINFO
  mov scrollInfo.fMask, SIF_ALL
  m2m scrollInfo.nMin, 0
  m2m scrollInfo.nPage, 5

  m2m scrollInfo.nMax, nowCanvasHeight
  m2m scrollInfo.nPos, nowCanvasOffsetY
  invoke SetScrollInfo , hCanvas, SB_VERT, addr scrollInfo, TRUE
  ; ˮƽ
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

  ; ��ֱ
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
  ; ˮƽ
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


; ����������������ʱ��
SetCanvasOffsetFromScrollBar proc
  local scrollInfo: SCROLLINFO 
  invoke InvalidateRect, hCanvas, NULL, FALSE
  ret
SetCanvasOffsetFromScrollBar endp

ResizeCanvas proc tempWidth:DWORD, tempHeight:DWORD
;TODO:����������С
;����UpdateHistoryBitmapFromDrawBuf�������������ſ�������ʷ��¼��
;���ӳ�������
;����UpdateDrawBufFromHistoryBitmap�ٽ�Bitmap������������
;���µ�hCanvas
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
    ; ���ƹ������ϵİ�ťλͼ
    ; �ú�������index(ǰ/����ɫ)��color��ɫ
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
  ;TODO:�ú�������index����ǰ��ɫ������ɫ
  ;index=0,����ǰ��ɫ
  ;index=1,���ñ���ɫ
  local @stcc:CHOOSECOLOR

  invoke RtlZeroMemory,addr @stcc,sizeof @stcc;��0���stcc�ڴ�����
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
;TODO:������һ������
;������ָ���historyBitmapIndex-1��״̬
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

;�Ի���� proc
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
;TODO:��ջ���Ϊ����ɫ
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
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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
  mov ebx, SIZEOF mBitmap ; ����ṹ����ֽ���
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
;TODO:�½�һ������
;��ԭ����·����ΪĬ��
;��existFilePath��0
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
;TODO:�����ڵ�proc 
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP

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
     invoke DeleteObject,@hBmp
     invoke SetColorInTool,0,foregroundColor        ; ��ɫ
     invoke SetColorInTool,1,backgroundColor        ; ��ɫ
     invoke SendMessage, hWinToolBar, TB_SETIMAGELIST, 0, hImageListControl
     invoke SendMessage, hWinToolBar, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
     invoke SendMessage, hWinToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
     invoke SendMessage, hWinToolBar, TB_ADDBUTTONS, ControlButtonNum, offset stToolBar
     invoke SendMessage, hWinToolBar, TB_AUTOSIZE, 0, 0
   ;--------------------װ�ع��-------------------
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
  ;-----------------������������--------------------
     invoke CreateCanvasWin
	 
	 invoke ShowCursorPosition
   .elseif eax == WM_SIZE
     ;ʹ״̬���͹����������Ŷ�����
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
     ;����������λ��
     invoke UpdateCanvasPos
     ;invoke SendMessage,hCanvas,uMsg,wParam,lParam
  .elseif eax == WM_COMMAND
     mov eax,wParam
     movzx eax,ax
     ;�˵���/���������Ǧ��/��Ƥ��ť������ѡ�в��ı���
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
     ;�˵���/������ѡ����Ͱ
     .elseif eax == ID_BUCKET
		mov SetEraser, 0
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_DRAG,eax,MF_BYCOMMAND
        invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurBucket
     .elseif eax == ID_DRAG
		mov SetEraser, 0
        invoke CheckMenuRadioItem,hMenu,ID_PEN,ID_DRAG,eax,MF_BYCOMMAND
        invoke SetClassLong,hCanvas,GCL_HCURSOR,hCurGrab
     ;�˵����ı��/��Ƥ�����ش�С������ѡ��
     .elseif eax>=ID_ONE_PIXEL && eax<=ID_FOUR_PIXEL
         invoke CheckMenuRadioItem,hMenu,ID_ONE_PIXEL,ID_FOUR_PIXEL,eax,MF_BYCOMMAND
     .elseif eax>=ID_ERA_TWO_PIXEL && eax<=ID_ERA_SIXTEEN_PIXEL
         mov ebx,eax
         push ebx
         invoke CheckMenuRadioItem,hMenu,ID_ERA_TWO_PIXEL,ID_ERA_SIXTEEN_PIXEL,eax,MF_BYCOMMAND
         pop ebx
         mov eax,ebx
     ;�˵����˳�����
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
  mov @stWndClass.hIconSm,eax                      ;Сͼ��
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
  invoke CreateSolidBrush, 0abababh
  mov hBackgroundBrush,eax
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