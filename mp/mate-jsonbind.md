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
