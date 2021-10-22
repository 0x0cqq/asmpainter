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
;---------------EUQ��ֵ����-----------------
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

.data
  hInstance         dd ?                   ;��ģ��ľ��
  hWinMain          dd ?                   ;���ھ��
  hMenu             dd ?                   ;�˵����
  hWinToolBar       dd ?                   ;������
  hWndStatusBar     dd ?                   ;״̬��
  hImageListControl dd ?
  hCurPen           dd ?                   ;�����
  hCurEraser_2      dd ?                   ;��Ƥ��� 2����
  hCurEraser_4      dd ?
  hCurEraser_8      dd ?
  hCurEraser_16     dd ?
  
  foregroundColor       dd ?               ;ǰ��ɫ
  backgroundColor       dd ?               ;����ɫ
  customColorBuffer     dd 16 dup(?)       ;��ɫ�������������Զ�����ɫ

  stToolBar  equ   this byte  ;���幤������ť
    TBBUTTON <0,ID_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;�½�
    TBBUTTON <1,ID_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;��
    TBBUTTON <2,ID_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����
    TBBUTTON <7,ID_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����
    TBBUTTON <4,ID_PEN,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;����
    TBBUTTON <5,ID_ERASER,TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>;��Ƥ
    TBBUTTON <10,ID_FOR_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;ǰ��ɫ
    TBBUTTON <11,ID_BACK_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,NULL>;����ɫ
  ControlButtonNum=($-stToolBar)/sizeof TBBUTTON

.const
  szMainWindowTitle            db "��ͼ",0         ;�����ڱ���
  szWindowClassName            db "MainWindow",0      ;�˵�������
  szToolBarClassName           db "ToolbarWindow32",0         
  szStatusBarClassName         db "msctls_statusbar32",0       

  lptbab                       TBADDBITMAP  <NULL,?>
.code
Quit proc
  invoke DestroyWindow,hWinMain           ;ɾ������
  invoke PostQuitMessage,NULL             ;����Ϣ�����в���һ��WM_QUIT��Ϣ
  ret
Quit endp

SetColorInTool proc index:DWORD, color:DWORD
    ;TODO:�ú�������index(ǰ/����ɫ)��color��ɫ
    ;     ���ƹ������ϵİ�ťλͼ
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
  ret
SetColor endp

ProcWinMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam
  local @stPos:POINT
  local @hSysMenu
  local @hBmp:HBITMAP

  mov eax,uMsg   ;��Ϣ
  .if eax==WM_CLOSE
     call Quit
  .elseif eax==WM_CREATE
  ;-----------------����״̬��-------------------
     invoke  CreateStatusWindow,WS_CHILD OR WS_VISIBLE OR \
        SBS_SIZEGRIP,NULL,hWnd,ID_STATUSBAR
     mov hWndStatusBar,eax
  ;-----------------����������-------------------
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
     ;�ڹ����������ǰ��ɫ�ͱ���ɫ��ѡ��

   ;------------------װ�ع��-------------------
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
     invoke SendMessage,hWndStatusBar,uMsg,wParam,lParam
     invoke SendMessage,hWinToolBar,uMsg,wParam,lParam
  
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
     .elseif eax == ID_QUIT
         call Quit
     .elseif eax == ID_FOR_COLOR
         invoke SetColor,0
     .elseif eax == ID_BACK_COLOR
         invoke SetColor,1
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
  local @stMsg:MSG
  local @hAccelerator

  invoke GetModuleHandle,NULL                      ;��ȡ��ģ����
  mov hInstance,eax
  invoke LoadMenu,hInstance,IDR_MENU1              ;װ�����˵���ģ������������˵���ID
  mov hMenu,eax
  invoke LoadAccelerators,hInstance,IDR_MENU1      ;װ�ؼ��ټ�
  mov @hAccelerator,eax
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
  mov hWinMain,eax                                 ;���ش��ڵľ��
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