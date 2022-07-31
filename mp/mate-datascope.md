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
