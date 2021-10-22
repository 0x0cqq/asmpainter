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
;-----------------����ԭ������-------------------
WinMain PROTO                                     ;������
ProcWinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD     ;���������е���Ϣ�������
ProcWinCanvas PROTO :DWORD,:DWORD,:DWORD,:DWORD   ;�������������е���Ϣ�������
CreateCanvasWin PROTO
UpdateCanvasPos PROTO
printf PROTO C :PTR BYTE, :VARARG

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

  ;��ҪΪ������ʹ�õı���
  ; ���µĴ�С��Ϊ�߼����أ�������Ļ��ʵ����ʾ�ĵ�������
  defaultCanvasWidth      equ 800
  defaultCanvasHeight     equ 600
  nowCanvasWidth          dd ?
  nowCanvasHeight         dd ? 
  nowCanvasOffsetX        dd ?
  nowCanvasOffsetY        dd ?
  nowCanvasZoomLevel      dd 1 ; һ���߼���������Ļ��ռ�ݼ���ʵ�����صĿ��

  historyNums       equ 50                             ;�洢 50 ����ʷ��¼
  historyBitmap     mBitmap historyNums DUP(<>)  ;��ʷ��¼��λͼ
  ; baseDCBuf        HDC ? ; ĳ�λ���λͼ�Ļ�������
  drawDCBuf        HDC ?   ; �����˵�ǰ���ƵĻ���


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

; ������� Canvas Windows Client Area ����������ת����Ϊ Canvas ���߼�����
CoordWindowToCanvas proc coordWindows:POINT, coordCanvas: PTR POINT
  ;TODO
CoordWindowToCanvas endp

; �� Canvas ���߼���������� Canvas Windows Client Area ����������ת����Ϊ 
CoordCanvasToWindow proc coordCanvas:POINT, coordWindow : PTR POINT
  ;TODO
CoordCanvasToWindow endp

Quit proc
  invoke DestroyWindow,hWinMain           ;ɾ������
  invoke PostQuitMessage,NULL             ;����Ϣ�����в���һ��WM_QUIT��Ϣ
  ret
Quit endp

; ���� HistoryBitmap ����һ����DrawBuf
UpdateDrawBufFromHistoryBitmap proc

UpdateDrawBufFromHistoryBitmap endp

; ����������ʷ�����ҰѲ����� bitmap �ŵ���һ��λ����
InitHistory proc bitmap: HBITMAP

InitHistory endp

; ����������
; �������ʼ��ʱ�����һ��
HandleCanvasCreate proc
  invoke UpdateCanvasPos ; ����λ��
  ;�� HistoryBitmap �в���һ�����հ�Bitmap�� InitHistory
  ; UpdateDrawBufFromHistoryBitmap
  ; invalidaterect ���������Σ�������취��һ�� WM_PAINT
  ; ������Ҫ���� RenderBitmap����������ñ�ֱ�ӵ���
HandleCanvasCreate endp

; ���ļ�����
LoadBitmapFromFile proc

LoadBitmapFromFile endp

;���浽�ļ�
SaveBitmapToFile proc

SaveBitmapToFile endp

; ����������£�Ҳ���ǿ�ʼ��ͼ
HandleLButtonDown proc wParam:DWORD, lParam:DWORD
  ;TODO
  ; ����������
  ; ���� HistoryBitmap �� Buffer ��
  ; ��Ҫ��¼�ʼ�ĵ�
  xor eax, eax
  ret
HandleLButtonDown endp

; �������̧��Ҳ���ǽ�����ͼ
HandleLButtonUp proc wParam:DWORD, lParam:DWORD
  ; ������̧��
  ; �� DrawBuf �� Bitmap ���õ� HistoryBitmap �� 
  ; Repaint 
  xor eax, eax
  ret
HandleLButtonUp endp

; ��������ƶ���Ҳ�������ڻ�ͼ
HandleMouseMove proc wParam:DWORD, lParam:DWORD
  ; �ж�һ�µ�ǰ��ʲô�ƶ�����Ҫ��һ��ȫ�ֱ���ά��һ��״̬�������ѡȡ��
  ; ������Ǳʺ���Ƥ���������ģ������¸��� HistoryBitmap �� Buffer ��
  ; ��ȡ��ǰ�����λ�ã����ڵ��߼����꣩����Ҫ��������ϵ�任ת�����������߼�����
  ; Ȼ���������ȥ�����Ρ�Բ�Ǿ���֮���
  ; ���ڱʺ���Ƥ����Ҫ���¡����µ�����λ�á�
  ; ���ڱʺ���Ƥ��������Ϊ���� MouseMove ֮���ʱ��̣ܶ����ֱ����ֱ��
  xor eax, eax
  ret
HandleMouseMove endp

; ��������ƶ������壬Ŀǰû�뵽ûʲôҪ���ģ�
HandleMouseLeave proc wParam:DWORD, lParam:DWORD
  xor eax,eax
  ret
HandleMouseLeave endp


; �� drawDCBuf ���պ��ʵı�����ƫ�Ƹ��Ƶ� hCanvas �� DC ����
RenderBitmap proc
  ; ���㷶Χ
  ; �������ķ�Χ���� StretchBlt ���Ƶ� һ��temp ��buffer����
  ; �� tempbuffer �ƶ��� Buffer ����
RenderBitmap endp

; ������ proc
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
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam  ;���ڹ����в��账�����Ϣ�����ݸ��˺���
    ret
  .elseif uMsg == WM_SIZE
    invoke UpdateCanvasPos
  .elseif uMsg == WM_PAINT
    invoke RenderBitmap
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

  invoke SetWindowPos,hCanvas,HWND_TOP,mWinRect.left,ebx,ecx,edx,SWP_SHOWWINDOW

  ;invoke DrawTextonCanvas
  ret  
UpdateCanvasPos endp


;������ �� proc 
ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
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
  ;-----------------������������-------------------
     invoke CreateCanvasWin
   invoke DeleteObject,@hBmp
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

   .elseif eax == WM_SIZE
     ;ʹ״̬���͹����������Ŷ�����
     invoke SendMessage,hWinStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
     ;����������λ��
     invoke SendMessage,hCanvas,uMsg,wParam,lParam
  .elseif eax == WM_COMMAND
     mov eax,wParam
     movzx eax,ax
     ;�˵���/���������Ǧ��/��Ƥ��ť������ѡ�в��ı���
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
     ;�˵����ı��/��Ƥ�����ش�С������ѡ��
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
     ;�˵����˳�����
     .elseif eax ==ID_QUIT
         call Quit
     .endif  
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