## 适用场景

![](https://minio.pigx.vip/oss/1659273751.jpg)

## 多数据源动态加载卸载

👉 [mybatis-mate-sharding-dynamic](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sharding-dynamic)

- 配置切换数据源规则

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
        // 如果想自定义控制切换那个数据源可以在此方法中处理
        // ShardingKey.change(数据源Key)
        // 返回 true 则按照你的切换方案执行 false 默认规则切换 @Sharding 注解才有效
        // datasourceKey = null 时候 mate 底层依然会使用默认数据源
        return true;
    }
}
```

- 测试

```java
 @GetMapping("/test")
    public List<User> test(String db) throws Exception {
        // 这里始终使用默认数据源切换规则，更多细节可以查看 MyShardingProcessor 处理器打印信息
        System.err.println("~~~ count =  " + mapper.selectCount(null));
        if ("test2".equals(db)) {
            // 切换到指定数据源，如果数据源之前不存在会装载配置源
            // 数据源的装载可以放到初始化或者添加新数据源的逻辑里面执行
            shardingDatasource.change(db, key -> DataSourceProperty.of(
                    "com.mysql.cj.jdbc.Driver",
                    "jdbc:mysql://localhost:3306/" + db + "?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC",
                    "root",
                    "root"
            ));
            // 卸载数据源
            // shardingDatasource.removeDataSource(db);
        }
        // 请求地址 db=test2 这里会切换到数据源 test2 界面显示数据会发生变好
        return mapper.selectList(null);
    }
```
