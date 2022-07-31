## 适用场景

![](https://minio.pigx.vip/oss/1658646303.jpg)

!> 配套源码: 👉 [mybatis-mate-audit](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-audit)。 对比两对象属性差异，例如：银行流水对账。主要是对[javers](https://javers.org/documentation/getting-started/#getting-started-audit)进行了封装。

## 快速开始

#### ① jar 包依赖

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-boot-starter</artifactId>
    <version>3.5.2</version>
</dependency>
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-mate-starter</artifactId>
    <version>1.2.5</version>
</dependency>
```

#### ② 目标 ORM 实体配置审计相关注解

```java
@Getter
@Setter
@ToString
public class User {
    private Long id;
    private String username;
    // 该注解可以指定数据审计输入字段内容
    @DiffInclude
    // 该注解可以指定数据审计输出内容
    @PropertyName("手机号码")
    private String mobile;
    private String email;
    private BigDecimal wallet;
    private BigDecimal amount;
}
```

#### ③ 调用 DataAuditor 审计

```java
@Transactional(rollbackFor = Exception.class)
public void dataAudit(User frontInput) {
    // 执行数据库操作
    DataAuditor.compare(frontInput, userMapper.selectById(frontInput.getId())).forEach(this::printChange);
}

private void printChange(Change change) {
    ValueChange vc = (ValueChange) change;
    System.err.printf("%s不匹配，期望值 %s 实际值 %s%n", vc.getPropertyName(), vc.getLeft(), vc.getRight());
}
```

## 进阶 异步处理审计事件 DataAuditEvent

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
