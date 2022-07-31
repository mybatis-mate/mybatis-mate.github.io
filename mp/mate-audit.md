## 数据审计（对账）

![](https://minio.pigx.vip/oss/1658646303.jpg)

👉 [mybatis-mate-audit](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-audit)

对比两对象属性差异，例如：银行流水对账。主要是对[javers](https://javers.org/documentation/getting-started/#getting-started-audit)进行了封装。

- Pom 依赖

```java
<dependencies>
    <dependency>
        <groupId>org.javers</groupId>
        <artifactId>javers-core</artifactId>
        <version>6.5.3</version>
    </dependency>
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-mate-audit</artifactId>
    </dependency>
</dependencies>
```

- DataAuditor(**比较两个实体差异**)

  ​ 提供了静态方法 compare，调用 Javers 的 compare 方法**返回 Change 对象集合**。

  ​ Change 对象主要有三个子类: NewObject 、ObjectRemoved 、PropertyChange（最常见的更改的属性）。

  ​ 其中 PropertyChange 又有具有以下子类型:

  ​ 1.ContainerChange — Set、List 或 Array 中已更改项目的列表。

  ​ 2.MapChange — 更改的 Map 条目列表。

  ​ 3.ReferenceChange — 更改的实体引用。

  ​ 4.ValueChange — 更改了 Primitive 或 Value。

  比较两实体属性差异，可以将 Change 对象强转为 ValueChange 对象。使用 ValueChange 我们可以获取到两个对象属性间的差异。

```java
		List<Change> changes = DataAuditor.compare(obj1, obj2);
		for(Change valueChange : changes) {
				ValueChange change = (ValueChange) valueChange;
				System.err.println(String.format("%s不匹配，期望值 %s 实际值 %s", change.getPropertyName(), change.getLeft(), change.getRight()));
           }
      }));
```

- DataAuditEvent(**发布数据审计事件**)

​ 通过 ApplicationEventPublisher 发布 DataAuditEvent 事件，进行异步回调，最终也是调用的 DataAuditor 的 compare 方法。

```java
		applicationEventPublisher.publishEvent(new DataAuditEvent((t) -> {

		List<Change> changes = t.apply(newVersion, oldVersion);
		for(Change valueChange : changes) {
				ValueChange change = (ValueChange) valueChange;
				System.err.println(String.format("%s不匹配，期望值 %s 实际值 %s", change.getPropertyName(), change.getLeft(), change.getRight()));
            }
        }));
```
