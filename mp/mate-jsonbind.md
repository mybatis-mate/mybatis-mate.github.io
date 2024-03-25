## 适用场景

![](https://minio.pigx.top/oss/1659250082.jpg)


!> 配套源码:  👉 [mybatis-mate-jsonbind](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-jsonbind)



## 快速开始

#### ① Jar 依赖

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.5</version>
</dependency>
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-mate-starter</artifactId>
    <version>1.3.4</version>
</dependency>
```

#### ② ORM 实体注解 @JsonBind

```java
@Getter
@Setter
@ToString
// 虚拟属性绑定策略
@JsonBind(JsonBindStrategy.Type.departmentRole)
public class User {
    private Long id;
    private String username;
    private Integer sex;
    private Integer status;

}
```
#### ③ 创建 Json 虚拟属性绑定策略

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
