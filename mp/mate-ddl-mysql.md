## 适用场景

👉 [mybatis-mate-ddl-mysql](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-mysql)👉 [mybatis-mate-ddl-postgres](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-postgres)

- 数据库 Schema 初始化，升级 SQL 自动维护，区别于 `flyway` 支持分表库、可控制代码执行 SQL 脚本 

!> 首次会在数据库中生成 ddl_history 表，每次执行 SQL 脚本会自动维护版本信息。


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

####   ② 指定文件加载规则

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
```

## 进阶: 代码层手动控制执行脚本

> 注入脚本执行类，支持自定义执行脚本

```java
@Bean
public DdlScript ddlScript(DataSource dataSource) {
    return new DdlScript(dataSource);
}
```

```java
//  注入 DDL 脚本
@Resource
private DdlScript ddlScript;

ddlScript.run(new StringReader("DELETE FROM user;\n" +
        "INSERT INTO user (id, username, password, sex, email) VALUES\n" +
        "(20, 'Duo', '123456', 0, 'Duo@baomidou.com');"));
```