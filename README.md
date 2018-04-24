# mobius
## 0x0
Kindle 很好用，可惜没有听书功能，所以想尝试写个支持 Kindle 格式的 iOS app 。

先完成如下功能：

- 读取 mobi 文件，解析出资源文件。
- 用 webview 显示书籍内容，不过在设备上出现无法加载同目录资源的问题，以及字符编码问题。（之后考虑用 native 实现）
- 用百度 TTS SDK 播放语音。
- git tag: step-0

用到的第三方如下：
- [libmobi](https://github.com/bfabiszewski/libmobi)
- [BDSDK](http://yuyin.baidu.com/)



