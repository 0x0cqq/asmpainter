程序采用 Win32 API 进行绘图，主要运用 GDI 模块。这个模块颇为复杂，在下面做一点微小 的说明。

---

GDI 模块中画图的关键概念是 [Device Contexts](https://docs.microsoft.com/en-us/windows/win32/gdi/device-contexts) [^1]。微软官方文档中说：

> A DC is a structure that defines a set of graphic objects and their associated attributes, and the graphic modes that affect output. The graphic objects include a pen for line drawing, a brush for painting and filling, a bitmap for copying or scrolling parts of the screen, a palette for defining the set of available colors, a region for clipping and other operations, and a path for painting and drawing operations. Unlike most of the structures, an application never has direct access to the DC; instead, it operates on the structure indirectly by calling various functions.[^2]

简单理解的话，Device Contexts 是 GDI 在**可以画图的对象**上 1) 画的“图形“，2) 调用其他函数（[LineTo](https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-lineto)，[Rectangle](https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-rectangle)）在对象上画图时的默认设置，这两者的结合体。例如画图需要在一块画布上画，就是对应 Device Contexts 中的 Bitmap 元素；例如画图需要笔（Pen），画图形需要填充（Brush），这些也在 Device Contexts 中有所体现。这些”默认配置“一般也是可以在具体画图的时候进行覆盖的，除 Bitmap 外。

具体实现上，Device Context 保存了各一个指向 Bitmap，Pen，Brush，Region ( Windows 称之为图形对象，Graphics Objects) 等的 Handle，并采用 SelectObject 将一个某类的图形对象选入 Device Contexts ，同时返回之前 Device Contexts 中的（，在这次选择后被踢走的）该类对象。

---

Device Context 出现的动机是把编程者（用户）的操作和物理的设备之间加上一层隔离，让用户可控地操控硬件，事实上是一层缓冲区。[^3]

GDI 绝大部分的画图函数的第一个参数即为 hDC，是 Device Contexts 的 Handle；

创建 Device Contexts 时需要指出定义中所说的可以画图的（表现画图操作结果的）对象是什么，在下面双重缓冲的策略中用到的是显示器和内存【如果是内存的话，就是 Compatible  Device Context】。

[^1]: 中文直接翻译为“设备上下文”，但事实上 Contexts 很难找到一个完全对应的中文概念，因此下面就不做翻译。
[^2]: [About Device Contexts - Win32 apps | Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/gdi/about-device-contexts)

[^3 ]: 但既然可以搭一层缓冲区，那么如果把”绘图的目的地“换成内存，就构成了双重缓冲

---

画图策略上，程序采用双缓冲的方法进行绘图。具体来说，在画布窗口的 [Display Device Contexts](https://docs.microsoft.com/en-us/windows/win32/gdi/display-device-contexts) 之外，保存一个与之 [Compatible](https://docs.microsoft.com/en-us/windows/desktop/api/Wingdi/nf-wingdi-createcompatibledc) 的，内容一致的 [Memory Device Contexts](https://docs.microsoft.com/en-us/windows/win32/gdi/memory-device-contexts) 于内存之中 。在用户使用鼠标在画布上开始绘画（ButtonDown or ButtonMove）时，我们复制一份当前窗口在内存中存储的 Memory Device Contexts 作为缓冲区，将用户的行为绘制到缓冲区中，随后将缓冲区复制到窗口的 Display Device Contexts 之中，并且禁用背景重绘，得到重新绘制的画布。在用户结束绘画（ButtonUp）时，我们将缓冲区的内容复制回窗口对应的 Memory Device Contexts 和窗口自身的 Display Device Contexts；并清除缓冲区。这样的双缓冲绘图方法可以减少窗口的闪烁，加快窗口的响应速度。



从 HDC 到 HBITMAP：GetDC（canvas），CreateCompatibleDC（新CDC） ，CreateCompatibleBitmap（新CDC通过SelectObject绑到其上），BitBlt  复制老 DC 到新 DC

从 HBITMAP 到 HDC：CreateCompatiableBitmap（新建一个HBITMAP），（目标HDC）SelectObject 中 Select HBITMAP 【不再需要复制了，已经载入了】

从 HDC 到 HDC：采用 [BitBlt](https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-bitblt) 复制

从 HBITMAP 到 HBITMAP：不需要这一环节，或可直接复制内存





似乎有些地方不是很清楚，CompatibleDC 的 hbitmap就是目标存储位置，但是普通 DC 的hbitmap仅仅是一个bitmap的画布？并不会修改传入的 hbitmap吗？