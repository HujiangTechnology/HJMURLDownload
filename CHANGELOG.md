1.1.0

---
- 添加 ```- (id<HJMURLDownloadExItem>)getAURLDownloadWithIdentifier:(NSString *)identifier ``` 接口，根据 identifier 获取当然任务的下载信息
- 解决下载完成后移动文件因目标文件存在导致失败的问题
- (待验证)解决第二次启动后恢复上次下载任务，但实际上次下载任务未成功但未报Error的问题

1.0.3

---
- @import 改为 #import
- 解决删除下载未清除数据库记录的问题

1.0.2

---
- 解决离线和在线状态来回切换时导致下载队列错误的问题
- 解决恢复上次下载时同时又新添加了相同任务引起的没有正确回调的问题
- 遗留问题: 第二次打开后下载模块不会主动恢复下载，需要外部重新添加上次的下载任务，如果没有重新添加会导致暂停的状态显示为等待中等错误状态
- 待改进: 添加回调参数显示当前任务是否在下载还是因为离线或者网络限制等原因暂停

1.0.1

---
- 解决app在各种情况下退出(crash，主动杀死，被系统在后台清理)，第二次启动app恢复上次未完成下载任务时遇到的各种错误
- 注:第二次启动后延迟1s下载上一次等待状态的任务，解决数据库读写不同步的问题，当前可能还存在因为异常情况状态和UI不匹配的情况。待优化，需要和小玉讨论下....

1.0.0

---

- 增加新的init方法，废弃原有老方法，新init方法创建backgroud下载器时可以设定网络要求
- 返回当前平均速度

0.4.1

---

- 解决 iOS 9 断点续传无效的问题
- 解决 iOS 9 之前 count 统计错误的问题

0.4.0

---

待补充



0.3.0 

---

- 调整 Core Data Stack 结构，防止 Core Data 频繁写入磁盘，取消`HJMDownloadCoreDataManagerMainManagedObjectContextDidMergedNotification`，防止监测此通知造成的不必要的系统资源开支（之前会根据这个通知来读取未读下载，过度频繁的查询，消耗很多 CPU 资源导致 UI 卡顿甚至应用崩溃），新增`HJMCDDownloadItemDidInsertedNotification`，`HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification` 和 `HJMCDDownloadItemDidDeletedNotification`

__本次优化参考了：[MARCUS ZARRA](http://twitter.com/mzarra) 的 [MY CORE DATA STACK](http://martiancraft.com/blog/2015/03/core-data-stack/)，之前的参考了：[Concurrent Core Data Stacks – Performance Shootout](http://floriankugler.com/2013/04/29/concurrent-core-data-stack-performance-shootout/)，也可能用法不对，导致频繁的磁盘写入，不过看来也不太适合下载模块__
