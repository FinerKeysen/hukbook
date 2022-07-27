# Bcache

**推荐参考**

> [Bcache浅析](http://blog.chinaunix.net/uid-27714502-id-5772320.html)：简介、总体结构、关键结构（bucket、Bkey、Bset、B+树、overlapping、journal）等
>
> [linux块设备加速缓存之bcache](https://blog.csdn.net/liumangxiong/article/details/17839797)：



**额外补充参考**

>[bcache配置使用](https://blog.csdn.net/axw2013/article/details/84837830)：侧重安装
>
>[bcache的使用](https://www.cnblogs.com/sunhaohao/p/sunhaohao.html)：讲安装使用
>
>[MaxIO智能缓存加速技术](https://blog.csdn.net/liuaigui/article/details/54882935)：关注缓存策略的图示





bcache是linux内核块设备层cache

- 3.10版本之后进入内核主线
- 支持策略：writeback、writethrough（默认方式）、writerround
- 缓存替换方式：LRU、FIFO、Random

