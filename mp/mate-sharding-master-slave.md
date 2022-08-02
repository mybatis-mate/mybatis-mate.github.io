## 适用场景

![](https://minio.pigx.vip/oss/1659275395.jpg)

读写分离，基本的原理是让主数据库处理事务性增、改、删操作（INSERT、UPDATE、DELETE），而从数据库处理SELECT查询操作。数据库复制被用来把事务性操作导致的变更同步到集群中的从数据库。

!> 👉 [mybatis-mate-sharding-dynamic](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sharding-dynamic)


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

#### ② 搭建 mysql 主从分离

- 启动主节点
```
docker run -p 3316:3306 --name mysql_master -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -e REPLICATION_USER=lengleng -e REPLICATION_PASSWORD=lengleng -d pig4cloud/mysql-master-slave:5.7
```

- 启动从节点
```
docker run --name mysql_slave -p 3317:3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -e REPLICATION_USER=lengleng -e REPLICATION_PASSWORD=lengleng --link mysql_master:master -d pig4cloud/mysql-master-slave:5.7
```

#### ③ 配置读写分离

```yaml
spring:
  main:
    allow-bean-definition-overriding: true

#  方便调试
logging:
  level:
    mybatis.mate: debug

mybatis-mate:
  cert:
    grant: XXX
    license: XXX
  sharding:
    health: true # 健康检测
    primary: mysql # 默认选择数据源
    datasource:
      mysql:
        - key: node1
          cluster: master
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://172.27.0.236:3316/test?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
        - key: node2
          cluster: slave
          driver-class-name: com.mysql.cj.jdbc.Driver
          url: jdbc:mysql://172.27.0.236:3317/test?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
          username: root
```

#### ④ Mapper 配置 Sharding

```java
@Mapper
@Sharding("mysql")
public interface UserMapper extends BaseMapper<User> {
}
```

- 注解 @Sharding


![](https://minio.pigx.vip/oss/1659276135.png)

#### ⑤ 调用测试

```java
@GetMapping("/test")
public boolean testSharding() throws Exception {
    User user = new User();
    // 插入自动路由至主库
    mapper.insert(user);
    // 查询自动路由至从库
    User query = mapper.selectById(user.getId());
    return true;
}
```
![](https://minio.pigx.vip/oss/1659275897.png)

