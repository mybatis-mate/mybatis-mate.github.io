## 字段脱敏

👉 [mybatis-mate-sensitive-jackson](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sensitive-jackson)

- 注解 @FieldSensitive

```java
@Getter
@Setter
public class User {
    private Long id;
    /**
     * 这里是一个自定义的策略 {@link SensitiveStrategyConfig} 初始化注入
     */
    @FieldSensitive("testStrategy")
    private String username;
    /**
     * 默认支持策略 {@link SensitiveType }
     */
    @FieldSensitive(SensitiveType.mobile)
    private String mobile;
    @FieldSensitive(SensitiveType.email)
    private String email;

}
```

- 注解 `FieldSensitive` 实现数据脱敏，内置 `手机号`、`邮箱`、`银行卡号` 等 9 种常用脱敏规则

```java
@Configuration
public class SensitiveStrategyConfig {

    /**
     * 注入脱敏策略
     */
    @Bean
    public ISensitiveStrategy sensitiveStrategy() {
        // 自定义 testStrategy 类型脱敏处理
        return new SensitiveStrategy().addStrategy("testStrategy", t -> t + "***test***");
    }
}

// 跳过脱密处理，用于编辑场景
RequestDataTransfer.skipSensitive();
```
