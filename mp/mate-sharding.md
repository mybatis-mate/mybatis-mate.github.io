## 多数据源分库分表（读写分离）

👉 [mybatis-mate-sharding](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sharding)

- 注解 @Sharding

|   属性   |  类型  | 必须指定 |         默认值         | 描述                         |
| :------: | :----: | :------: | :--------------------: | ---------------------------- |
|  value   | String |    是    |           ""           | 分库组名，空使用默认主数据源 |
| strategy | Class  |    否    | RandomShardingStrategy | 分库&分表策略                |

- 配置

```yaml
mybatis-mate:
  sharding:
    health: true # 健康检测
    primary: mysql # 默认选择数据源
    datasource:
      mysql: # 数据库组
        - key: node1
          ...
        - key: node2
          cluster: slave # 从库读写分离时候负责 sql 查询操作，主库 master 默认可以不写
          ...
      postgres:
        - key: node1 # 数据节点
          ...
```

- 注解 `Sharding` 切换数据源，组内节点默认随机选择（查从写主）

```java
@Mapper
@Sharding("mysql")
public interface UserMapper extends BaseMapper<User> {

    @Sharding("postgres")
    Long selectByUsername(String username);

}
```

- 切换指定数据库节点

```java
// 切换到 mysql 从库 node2 节点
ShardingKey.change("mysqlnode2");
```
