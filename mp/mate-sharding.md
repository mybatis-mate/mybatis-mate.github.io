## 适用场景

![](https://minio.pigx.top/oss/1659257873.jpg)

👉 [mybatis-mate-sharding](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sharding)


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

#### ② 配置数据源信息

```yaml
mybatis-mate:
  cert:
    grant: XXX
    license: XX
  sharding:
    datasource:
      mysql:
        - key: node1
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://localhost:3306/test?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
      mysql2:
        - key: node1
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://localhost:3306/datav?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
```

####   ③ Mapper 注解切换数据源

- 注解 @Sharding

|   属性   |  类型  | 必须指定 |         默认值         | 描述                         |
| :------: | :----: | :------: | :--------------------: | ---------------------------- |
|  value   | String |    是    |           ""           | 分库组名，空使用默认主数据源 |
| strategy | Class  |    否    | RandomShardingStrategy | 分库&分表策略                |
- 注解 `Sharding` 切换数据源，组内节点默认随机选择（查从写主）

```java
@Mapper
public interface UserMapper extends BaseMapper<User> {

    @Sharding("mysql")
    Long selectByUsername(String username);

}
```