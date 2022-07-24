## 数据审计（对账）

👉 [mybatis-mate-audit](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-audit)

对比两对象属性差异，例如：银行流水对账。主要是对[javers](https://javers.org/documentation/getting-started/#getting-started-audit)进行了封装。

- Pom依赖

```java
<dependencies>
    <dependency>
        <groupId>org.javers</groupId>
        <artifactId>javers-core</artifactId>
        <version>6.5.3</version>
    </dependency>
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-mate-audit</artifactId>
    </dependency>
</dependencies>
```

- DataAuditor(**比较两个实体差异**)

  ​	提供了静态方法compare，调用Javers的compare方法**返回Change对象集合**。

  ​	Change对象主要有三个子类:	NewObject 、ObjectRemoved 、PropertyChange（最常见的更改的属性）。

  ​	其中PropertyChange又有具有以下子类型:

  ​			1.ContainerChange — Set、List 或 Array 中已更改项目的列表。

  ​			2.MapChange — 更改的 Map 条目列表。

  ​			3.ReferenceChange — 更改的实体引用。

  ​			4.ValueChange — 更改了 Primitive 或 Value。

  比较两实体属性差异，可以将Change对象强转为ValueChange对象。使用ValueChange我们可以获取到两个对象属性间的差异。	

```java
		List<Change> changes = DataAuditor.compare(obj1, obj2);
		for(Change valueChange : changes) {
				ValueChange change = (ValueChange) valueChange;
				System.err.println(String.format("%s不匹配，期望值 %s 实际值 %s", change.getPropertyName(), change.getLeft(), change.getRight()));
           }
      }));
```
- DataAuditEvent(**发布数据审计事件**)

​		通过ApplicationEventPublisher发布DataAuditEvent事件，进行异步回调，最终也是调用的DataAuditor的compare方法。	

```java
		applicationEventPublisher.publishEvent(new DataAuditEvent((t) -> {

		List<Change> changes = t.apply(newVersion, oldVersion);
		for(Change valueChange : changes) {
				ValueChange change = (ValueChange) valueChange;
				System.err.println(String.format("%s不匹配，期望值 %s 实际值 %s", change.getPropertyName(), change.getLeft(), change.getRight()));
            }
        }));
```



## 数据敏感词过滤

👉 [mybatis-mate-sensitive-words](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sensitive-words)

- pom依赖

```java
	 <dependencies>
        <dependency>
            <groupId>org.ahocorasick</groupId>
            <artifactId>ahocorasick</artifactId>
            <version>0.6.3</version>
        </dependency>
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-mate-sensitive-words</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>
    </dependencies>
```

- 配置敏感词处理逻辑

```java
@Configuration
public class ParamsConfig {

    @Bean
    public IParamsProcessor paramsProcessor() {
        return new SensitiveWordsProcessor() {

            /**
             * 加载敏感词
             */
            @Override
            public List<String> loadSensitiveWords() {
                // 这里的敏感词可以从数据库中读取，也可以本文方式获取，加载只会执行一次
                return Collections.singletonList("王安石");
            }

            /**
             * 处理敏感词
             * @param fieldName 字段名
             * @param fieldValue 字段值
             * @param emits 敏感词信息
             */
            @Override
            public String handle(String fieldName, String fieldValue, Collection<Emit> emits) {
                if (CollectionUtils.isNotEmpty(emits)) {
                    try {
                        // 这里可以过滤直接删除敏感词，也可以返回错误，提示界面删除敏感词
                        System.err.println("发现敏感词（" + fieldName + " = " + fieldValue + "）" +
                                "存在敏感词：" + toJson(emits));
                        String fv = fieldValue;
                        for (Emit emit : emits) {
                            fv = fv.replaceAll(emit.getKeyword(), "");
                        }
                        return fv;
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                return fieldValue;
            }
        };
    }

    private static ObjectMapper OBJECT_MAPPER;

    public static String toJson(Object object) throws Exception {
        if (null == OBJECT_MAPPER) {
            OBJECT_MAPPER = new ObjectMapper();
        }
        return OBJECT_MAPPER.writeValueAsString(object);
    }
}

```

- 定义接口请求敏感词处理切点

```java
@RestControllerAdvice
public class SensitiveRequestBodyAdvice extends RequestBodyAdviceAdapter {
    private final IParamsProcessor paramsProcessor;

    public SensitiveRequestBodyAdvice(IParamsProcessor paramsProcessor) {
        this.paramsProcessor = paramsProcessor;
    }

    /**
     * 该方法用于判断当前请求，是否要执行beforeBodyRead方法
     *
     * @param methodParameter 方法的参数对象
     * @param targetType      方法的参数类型
     * @param converterType   将会使用到的Http消息转换器类类型
     * @return 返回true则会执行beforeBodyRead
     */
    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType,
                            Class<? extends HttpMessageConverter<?>> converterType) {
        Class<?> clazz;
        if (targetType instanceof ParameterizedTypeImpl) {
            clazz = ((ParameterizedTypeImpl) targetType).getRawType();
        } else {
            clazz = (Class) targetType;
        }
      	// 返回true则会执行beforeBodyRead
        return Sensitived.class.isAssignableFrom(clazz);
    }

    /**
     * 在Http消息转换器执转换，之前执行
     *
     * @param inputMessage  客户端的请求数据
     * @param parameter     方法的参数对象
     * @param targetType    方法的参数类型
     * @param converterType 将会使用到的Http消息转换器类类型
     * @return 返回一个自定义的HttpInputMessage
     */
    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, MethodParameter parameter, Type targetType,
                                           Class<? extends HttpMessageConverter<?>> converterType) {
        try {
            String content = StreamUtils.copyToString(inputMessage.getBody(), StandardCharsets.UTF_8);
            ByteArrayInputStream inputStream = new ByteArrayInputStream(paramsProcessor.execute("json",
                    content).getBytes(StandardCharsets.UTF_8));
            return new MappingJacksonInputMessage(inputStream, inputMessage.getHeaders());
        } catch (IOException e) {
            e.printStackTrace();
        }
        return inputMessage;
    }
}
```

- 定义实体

```java
/**
 * 敏感词接口,实现此接口的将被过滤
 */
public interface Sensitived {

}
```

```java
@Getter
@Setter
public class ArticleNoneSensitive {
    private String content;
    private Integer see;
    private Long size;

}
```

```java
@Getter
@Setter
public class Article implements Sensitived {
    // 内容
    private String content;
    // 阅读数
    private Integer see;
    // 字数
    private Long size;

}
```

- 测试

```java
@RestController
public class ArticleController {

    // 测试访问下面地址观察控制台（ 请求json参数 ）
    @PostMapping("/json")
    public String json(@RequestBody Article article) throws Exception {
        return ParamsConfig.toJson(article);
    }
  
    // 这里未实现 Sensitived 接口 SensitiveRequestBodyAdvice 不调用脱敏
    @PostMapping("/test")
    public String test(@RequestBody ArticleNoneSensitive article) throws Exception {
        return ParamsConfig.toJson(article);
    }

}
```



## 数据权限

👉 [mybatis-mate-datascope](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-datascope)

1. 注解 @DataScope

|  属性  |     类型     | 必须指定 | 默认值 | 描述                                   |
| :----: | :----------: | :------: | :----: | -------------------------------------- |
|  type  |    String    |    否    |   ""   | 范围类型，用于区分对于业务分类，默认空 |
| value  | DataColumn[] |    否    |   {}   | 数据权限字段，支持多字段组合           |
| ignore |   boolean    |    否    | false  | 忽略权限处理逻辑 true 是 false 否      |

2. 注解 @DataColumn

| 属性  |  类型  | 必须指定 | 默认值 | 描述       |
| :---: | :----: | :------: | :----: | ---------- |
| alias | String |    否    |   ""   | 关联表别名 |
| name  | String |    是    |        | 字段名     |

- 注入 IDataScopeProvider 实现类

  通过[JSqlParser](https://github.com/JSQLParser/JSqlParser)，实现数据权限处理的逻辑

```java
@Configuration
public class DataScopeConfig {
    public final static String TEST = "test";

  	/**
  	 * 处理数据权限逻辑 
  	 * @see <a href="https://github.com/JSQLParser/JSqlParser/wiki">sql解析器Api</a>
  	 */
    @Bean
    public IDataScopeProvider dataScopeProvider() {
        return new AbstractDataScopeProvider() {

            /**
             * 这里是 Select 查询 Where 条件
             * args 中包含 mapper 方法的请求参数，需要使用可以自行获取
             */
            @Override
            public void setWhere(PlainSelect plainSelect, Object[] args, DataScopeProperty dataScopeProperty) {               
                if (TEST.equals(dataScopeProperty.getType())) {
                    // 业务 test 类型
                    List<DataColumnProperty> dataColumns = dataScopeProperty.getColumns();
                    for (DataColumnProperty dataColumn : dataColumns) {
                        if ("department_id".equals(dataColumn.getName())) {
                            // 追加部门字段 IN 条件，也可以是 SQL 语句
                            ItemsList itemsList = new ExpressionList(Arrays.asList(
                                    new StringValue("1"),
                                    new StringValue("2"),
                                    new StringValue("3"),
                                    new StringValue("5")
                            ));
                            InExpression inExpression = new InExpression(new Column(dataColumn.getAliasDotName()), itemsList);
                            if (null == plainSelect.getWhere()) {
                                // 不存在 where 条件
                                plainSelect.setWhere(new Parenthesis(inExpression));
                            } else {
                                // 存在 where 条件 and 处理
                                plainSelect.setWhere(new AndExpression(plainSelect.getWhere(), inExpression));
                            }
                        } else if ("mobile".equals(dataColumn.getName())) {
                            // 支持一个自定义条件
                            LikeExpression likeExpression = new LikeExpression();
                            likeExpression.setLeftExpression(new Column(dataColumn.getAliasDotName()));
                            likeExpression.setRightExpression(new StringValue("%1533%"));
                            plainSelect.setWhere(new AndExpression(plainSelect.getWhere(), likeExpression));
                        }
                    }
                }

                else {
                    System.err.println("--------------------------------");
                }
            }

            @Override
            public void processInsert(Object[] args, MappedStatement mappedStatement, DataScopeProperty dataScopeProperty) {
                System.err.println("------------------  执行【插入】------------------  ");
            }

            @Override
            public void processDelete(Object[] args, MappedStatement mappedStatement, DataScopeProperty dataScopeProperty) {
                /**
                 * 这是删除自定义处理逻辑，插入更新需要限制条件可以参考这里
                 */
                if (TEST.equals(dataScopeProperty.getType())) {
                    processStatements(args, mappedStatement, (statement, index) -> {
                        Delete delete = (Delete) statement;
                        List<DataColumnProperty> dataColumns = dataScopeProperty.getColumns();
                        for (DataColumnProperty dataColumn : dataColumns) {
                            if ("department_id".equals(dataColumn.getName())) {
                                EqualsTo equalsTo = new EqualsTo();
                                equalsTo.setLeftExpression(new Column(dataColumn.getAliasDotName()));
                                equalsTo.setRightExpression(new StringValue("1"));
                                delete.setWhere(new AndExpression(delete.getWhere(), equalsTo));
                            }
                        }
                    });
                }
            }

            @Override
            public void processUpdate(Object[] args, MappedStatement mappedStatement, DataScopeProperty dataScopeProperty) {
                System.err.println("------------------  执行【更新】 ------------------");
            }
        };
    }
}
```

- 使用注解

```java
// 测试 test 类型数据权限范围，混合分页模式
@DataScope(type = "test", value = {
        // 关联表 user 别名 u 指定部门字段权限
        @DataColumn(alias = "u", name = "department_id"),
        // 关联表 user 别名 u 指定手机号字段（自己判断处理）
        @DataColumn(alias = "u", name = "mobile")
})
@Select("select u.* from user u")
List<User> selectTestList(IPage<User> page, Long id, @Param("name") String username);

// 测试数据权限，最终执行 SQL 语句
SELECT u.* FROM user u WHERE (u.department_id IN ('1', '2', '3', '5')) AND u.mobile LIKE '%1533%' LIMIT 1,10

```

  

## 表结构自动维护

👉 [mybatis-mate-ddl-mysql](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-mysql)👉 [mybatis-mate-ddl-postgres](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-ddl-postgres)

- 数据库 Schema 初始化，升级 SQL 自动维护，区别于 `flyway` 支持分表库、可控制代码执行 SQL 脚本
- 首次会在数据库中生成 ddl_history 表，每次执行SQL脚本会自动维护版本信息。

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



## 字段数据绑定（字典回写）

👉 [mybatis-mate-dict](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-dict)

- 注解 @FieldBind

|   属性   |  类型  | 必须指定 | 默认值 | 描述                                               |
| :------: | :----: | :------: | :----: | -------------------------------------------------- |
| sharding | String |    否    |   ""   | 分库分表数据源指定                                 |
|   type   | String |    是    |        | 类型（用于区分不同业务）                           |
|  target  | String |    是    |        | 目标显示属性（待绑定属性，注意非数据库字段请排除） |

- 数据库 `sex` 值 `0`、`1` 自动映射为 `男`、`女`
- 可以绑定映射为对象，例如：根据订单 ID 映射 订单对象或者编号

```java
@Getter
@Setter
@ToString
public class User {
    private Long id;
    private String username;

    /**
     * type 绑定类型 ，target 目标显示属性
     */
    @FieldBind(type = BindType.USER_SEX, target = "sexText")
    private Integer sex;

    // 绑定显示属性，非表字典（排除）
    @TableField(exist = false)
    private String sexText;

}
```

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

        System.err.println("字段类型：" + fieldBind.type() + "，绑定属性值：" + fieldValue);
        // 数据库中数据转换
        if (BindType.USER_SEX.equals(fieldBind.type())) {
            metaObject.setValue(fieldBind.target(), SEX_MAP.get(String.valueOf(fieldValue)));
        }
       
    }
}
```

## 虚拟属性绑定

👉 [mybatis-mate-jsonbind](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-jsonbind)

- 注解 @JsonBind

```java
@Getter
@Setter
@ToString
@JsonBind(JsonBindStrategy.Type.departmentRole)
public class User {
    private Long id;
    private String username;
    private Integer sex;
    private Integer status;

}
```

- 返回 Json 虚拟属性绑定策略

```java
@Component
public class JsonBindStrategy implements IJsonBindStrategy {
  
     // 绑定类型
     public interface Type {
        String departmentRole = "departmentRole";
    }

    @Override
    public Map<String, Function<Object, Map<String, Object>>> getStrategyFunctionMap() {
        return new HashMap<String, Function<Object, Map<String, Object>>>(16) {
            {
                // 注入虚拟节点
                put(Type.departmentRole, (obj) -> new HashMap(2) {{
                    User user = (User) obj;
                    // 可调用数据库查询角色信息
                    put("roleName", "经理");
                }});
            }
        };
    }
}
```

## 字段加密解密

👉 [mybatis-mate-encrypt](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-encrypt)

- 注解 @FieldEncrypt

|   属性    |   类型    | 必须指定 |      默认值      | 描述                 |
| :-------: | :-------: | :------: | :--------------: | -------------------- |
| password  |  String   |    否    |        ""        | 加密密码             |
| algorithm | Algorithm |    否    | PBEWithMD5AndDES | PBE MD5 DES 混合算法 |
| encryptor |   Class   |    否    |    IEncryptor    | 加密处理器           |

- 算法 Algorithm

|            算法             |                        描述                         |
| :-------------------------: | :-------------------------------------------------: |
|           MD5_32            |                   32 位 md5 算法                    |
|           MD5_16            |                   16 位 md5 算法                    |
|           BASE64            |          64 个字符来表示任意二进制数据算法          |
|             AES             |                    AES 对称算法                     |
|             RSA             |                   非对称加密算法                    |
|             SM2             |          国密 SM2 非对称加密算法，基于 ECC          |
|             SM3             |   国密 SM3 消息摘要算法，可以用 MD5 作为对比理解    |
|             SM4             | 国密 SM4 对称加密算法，无线局域网标准的分组数据算法 |
|      PBEWithMD5AndDES       |                      混合算法                       |
|   PBEWithMD5AndTripleDES    |                      混合算法                       |
| PBEWithHMACSHA512AndAES_256 |                      混合算法                       |
|    PBEWithSHA1AndDESede     |                      混合算法                       |
|    PBEWithSHA1AndRC2_40     |                      混合算法                       |



👉 [国密 SM2.3.4 算法使用规范](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/国密SM2.3.4算法使用规范)

- 注解 `FieldEncrypt` 实现数据加解密，支持多种加密算法

```java
@FieldEncrypt
private String email;
```

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

## 多数据源事务（ jta atomikos）

👉 [mybatis-mate-sharding-jta-atomikos](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sharding-jta-atomikos)
