## 使用场景

![1659253222](https://minio.pigx.top/oss/1659253222.jpg)

!> 配套源码 👉 [mybatis-mate-dict](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-dict)


## 快速开始

#### ① Jar 依赖

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

#### ② ORM 实体注解 @JsonBind

- 注解 @FieldBind


```java
@Getter
@Setter
@ToString
public class User {
    /**
     * type 绑定类型 ，target 目标显示属性
     */
    @FieldBind(type = BindType.USER_SEX, target = "sexText")
    private Integer sex;
}
```

|   属性   |  类型  | 必须指定 | 默认值 | 描述                                               |
| :------: | :----: | :------: | :----: | -------------------------------------------------- |
| sharding | String |    否    |   ""   | 分库分表数据源指定                                 |
|   type   | String |    是    |        | 类型（用于区分不同业务）                           |
|  target  | String |    是    |        | 目标显示属性（待绑定属性，注意非数据库字段请排除） |

- 数据库 `sex` 值 `0`、`1` 自动映射为 `男`、`女`
- 可以绑定映射为对象，例如：根据订单 ID 映射 订单对象或者编号

#### ③ 指定绑定规则

- 绑定业务处理类需要实现 IDataBind 接口，注入 spring 容器

```java
@Component
public class DataBind implements IDataBind {

    /**
     * 从数据库或缓存中获取
     */
    private Map<String, String> SEX_MAP = new ConcurrentHashMap<String, String>() {{
        put("0", "女");
        put("1", "男");
    }};

    /**
     * 设置元数据对象<br>
     * 根据源对象映射绑定指定属性（自行处理缓存逻辑）
     *
     * @param fieldBind  数据绑定注解
     * @param fieldValue 属性值
     * @param metaObject 元数据对象 {@link MetaObject}
     * @return
     */
    @Override
    public void setMetaObject(FieldBind fieldBind, Object fieldValue, MetaObject metaObject) {
        // 数据库中数据转换
        if (BindType.USER_SEX.equals(fieldBind.type())) {
            metaObject.setValue(fieldBind.target(), SEX_MAP.get(String.valueOf(fieldValue)));
        }

    }
}
```
