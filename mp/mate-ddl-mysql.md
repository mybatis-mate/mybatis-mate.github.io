## 表结构自动维护

👉 [mybatis-mate-ddl-mysql](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-mysql)👉 [mybatis-mate-ddl-postgres](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-postgres)

- 数据库 Schema 初始化，升级 SQL 自动维护，区别于 `flyway` 支持分表库、可控制代码执行 SQL 脚本
- 首次会在数据库中生成 ddl_history 表，每次执行 SQL 脚本会自动维护版本信息。

```java
@Component
public class MysqlDdl implements IDdl {

    /**
     * 执行 SQL 脚本方式
     */
    @Override
    public List<String> getSqlFiles() {
        return Arrays.asList(
                "db/tag-schema.sql",
                "D:\\db\\tag-data.sql"
        );
    }
}

// 切换到 mysql 从库，执行 SQL 脚本
ShardingKey.change("mysqlt2");
ddlScript.run(new StringReader("DELETE FROM user;\n" +
        "INSERT INTO user (id, username, password, sex, email) VALUES\n" +
        "(20, 'Duo', '123456', 0, 'Duo@baomidou.com');"));
```
