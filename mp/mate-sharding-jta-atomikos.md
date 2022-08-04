## 适用场景

![](https://minio.pigx.vip/oss/1659278674.jpg)

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
<!--事务支持-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jta-atomikos</artifactId>
</dependency>
```

#### ②  配置分库分表

```yaml
mybatis-mate:
  cert:
    grant: XXX
    license: XXX
  sharding:
    health: true # 健康检测
    primary: mysql # 默认选择数据源
    datasource:
      mysql1:
        - key: node1
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://127.0.0.1:3306/mate?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
      mysql2:
        - key: node1
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://127.0.0.1:3306/mate?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
```

#### ③ 配置事务数据源支持

```java
    //@Bean
public IDataSourceProvider dataSourceProvider() {
    return new AtomikosDataSourceProvider() {

        /**
            * 创建 XADataSource 数据源
            *
            * @param group              数据库分组
            * @param dataSourceProperty 数据源配置
            * @return
            */
        @Override
        public XADataSource createXADataSource(String group, DataSourceProperty dataSourceProperty) throws SQLException {
            // 根据数据库类型可以创建指定 XA 数据源
            final String driverClassName = dataSourceProperty.getDriverClassName();
            // mysql xa
            MysqlXADataSource mysqlXaDataSource = new MysqlXADataSource();
            mysqlXaDataSource.setUrl(dataSourceProperty.getUrl());
            mysqlXaDataSource.setPinGlobalTxToPhysicalConnection(true);
            mysqlXaDataSource.setUser(dataSourceProperty.getUsername());
            mysqlXaDataSource.setPassword(dataSourceProperty.getPassword());
            mysqlXaDataSource.setPinGlobalTxToPhysicalConnection(true);
            return mysqlXaDataSource;
        }
    };
}
```

#### ④ 开启事务

```java
@EnableTransactionManagement
```

#### ⑤ 测试回显

```java
@GetMapping("/test")
@Transactional(rollbackFor = Exception.class)
public List<User> test(String db) throws Exception {
    User user = new User();
    mapper.insert(user);
    ShardingKey.change("mysqlt2");
    mapper.insert(user);
    int i = 1/0;
    return null;
}
```

