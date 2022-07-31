## 适用场景

![1659256612](https://minio.pigx.vip/oss/1659256612.jpg)

数据权限管理主要控制某条数据记录对用户是否可见，结合功能权限可以更灵活的配置业务过程中每一位员工的功能操作权限及数据可见范围，全面保障企业数据的安全性。


👉 [mybatis-mate-datascope](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-datascope)


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
```

#### ② 配置数据权限拦截策略

- 注入 IDataScopeProvider 实现类

通过[JSqlParser](https://github.com/JSQLParser/JSqlParser)，实现数据权限处理的逻辑

```java
    @Bean
public IDataScopeProvider dataScopeProvider() {
    return new AbstractDataScopeProvider() {

        /**
            * 这里是 Select 查询 Where 条件
            */
        @Override
        public void setWhere(PlainSelect plainSelect, Object[] args, DataScopeProperty dataScopeProperty) {
            // 可根据 Mapper DataScope 指定不同的规则
            String type = dataScopeProperty.getType();
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
    };
}
```

#### ③ Mapper 调用增加相关数据权限范围

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
