## 适用场景


![1659252133](https://minio.pigx.top/oss/1659252133.jpg)


!> 配套源码: 👉 [mybatis-mate-sensitive-jackson](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sensitive-jackson)


## 快速开始

#### ①  注解 @FieldSensitive 实现现数据脱敏

- 内置 `手机号`、`邮箱`、`银行卡号` 等 9 种常用脱敏规则

```java
@Getter
@Setter
public class User {
    private Long id;

    /**
     * 默认支持策略 {@link SensitiveType }
     */
    @FieldSensitive(SensitiveType.mobile)
    private String mobile;
    @FieldSensitive(SensitiveType.email)
    private String email;

}
```

#### ② 测试运行

![](https://minio.pigx.top/oss/1659252548.png)


- 数据库实际存储的数据

![](https://minio.pigx.top/oss/1659252565.png)

## 进阶

#### ① 自定义脱敏策略 

```java

/**
    * 注入脱敏策略
    */
@Bean
public ISensitiveStrategy sensitiveStrategy() {
    // 自定义 testStrategy 类型脱敏处理
    return new SensitiveStrategy().addStrategy("testStrategy", t -> t + "***test***");
}
```

```java
/**
    * 这里是一个自定义的策略 {@link SensitiveStrategyConfig} 初始化注入
    */
@FieldSensitive("testStrategy")
```


#### ② 跳过脱敏输出

```java
// 跳过脱密处理，用于编辑场景
RequestDataTransfer.skipSensitive();
```

- 示例如下

```java
@GetMapping("/list")
public List<User> list(HttpServletRequest request) {
    if ("1".equals(request.getParameter("skip"))) {
        // 跳过脱密处理
        RequestDataTransfer.skipSensitive();
    }
    return userMapper.selectList(null);
}
```