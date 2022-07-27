参考文献：

[Java map 详解 - 用法、遍历、排序、常用API等](https://www.cnblogs.com/lzq198754/p/5780165.html)



键值对形式，可重复



基本用法

- 初始化

```java
Map<String, String> map = new Map<String, String>();
```

- 插入

```java
map.put("key1", "value1");
```

- 获取

```java
String value = map.get("key1");
```

- 移除

```java
map.remove("key1");
```

- 清空

```java
map.clear();
```



几种常用遍历方式

- 增强型 for 循环遍历—使用 keySet()

```java
/**
* 使用 keySet() 遍历
*/
for(String key : map.keySet()){
	System.out.println(key + " : " + map.get(key));
}
```

- 增强型 for 循环遍历—使用 entrySet()

```java
/**
* 使用 entrySet() 遍历
*/
for(Map.Entry<String, String> entry : map.entrySet()) {
	System.out.println(entry.getKey() + " : " + entry.getValue());
}
```

- 迭代器遍历—使用 keySet()

```java
/**
* 使用 keySet() 遍历
*/
Iterator<String> iteratorKey = map.keySet().iterator();
while (iteratorKey.hasNext()) {
	String key = iteratorKey.next();
	System.out.println(key + " : " + map.get(key));
}
```

- 迭代器遍历—使用 entrySet()

```java
/**
* 使用 entrySet() 遍历
*/
Iterator<Map.Entry<String, String>> iteratorEntry = map.entrySet().iterator();
while (iteratorEntry.hasNext()) {
	Map.Entry<String, String> entry = iteratorEntry.next();
	System.out.println(entry.getKey() + " : " + entry.getValue());
}
```

