## 适用场景

![1659276730](https://minio.pigx.vip/oss/1659276730.jpg)

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
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-actuator</artifactId>
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
          url: jdbc:mysql://127.0.0.1:3306/test?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
      mysql2:
        - key: node2
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://127.0.0.1:3306/test2?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
          password: root
```

#### ③ Mapper切换节点

```java
@Mapper
@Sharding("mysql1")
public interface UserMapper extends BaseMapper<User> {
}
```
#### ④ 手动切换节点

!> 切换指定 group+key

```java
ShardingKey.change("mysqlnode1");
```

- 示例:

```java
ShardingKey.change(db);
mapper.selectList(null);
```

#### ⑤ 进阶: 自动切换节点 IShardingProcessor 策略

```java
@Component
public class MyShardingProcessor implements IShardingProcessor {

    /**
     * 切换数据源，返回 false 使用默认数据源切换规则
     *
     * @param invocation      {@link Invocation}
     * @param mappedStatement {@link MappedStatement}
     * @param datasourceKey   数据源关键字
     * @return true 成功  false 失败
     */
    @Override
    public boolean changeDatasource(Invocation invocation, MappedStatement mappedStatement,
                                    String datasourceKey) {
        System.err.println(" 执行方法：" + mappedStatement.getId());
        System.err.println(" datasourceKey = " + datasourceKey);
        // 可以根据各种参数综合选择 datasourceKey , RequestContextHolder.currentRequestAttributes() 
        ShardingKey.change(datasourceKey);
        return true;
    }
}
```

#### ⑥ 进阶： 代码初始化数据源

```java
   @Primary
    @Bean(name = "dataSource")
    public ShardingDatasource shardingDatasource(IDataSourceProvider dataSourceProvider, ShardingProperties shardingProperties) {
        shardingProperties.setPrimary("mysql");
        DataSourceProperty mysqlT1 = new DataSourceProperty();
        mysqlT1.setKey("t1");
        mysqlT1.setDriverClassName("com.mysql.cj.jdbc.Driver");
        mysqlT1.setUrl("jdbc:mysql://localhost:3306/test?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC");
        mysqlT1.setUsername("root");
        mysqlT1.setSchema("test");
        shardingProperties.setDatasource(new HashMap<String, List<DataSourceProperty>>(16) {{
            put("mysql", Arrays.asList(mysqlT1));
        }});
        Map<String, DataSource> dataSources = new HashMap<>(16);
        shardingProperties.getDatasource().forEach((k, v) -> v.forEach(d -> {
            try {
                String datasourceKey = k + d.getKey();
                dataSources.put(datasourceKey, dataSourceProvider.createDataSource(k, d));
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }));
        if (null != shardingStrategy) {
            shardingProperties.setShardingStrategy(shardingStrategy);
        }
        return new ShardingDatasource(dataSourceProvider, dataSources, shardingProperties);
    }
```