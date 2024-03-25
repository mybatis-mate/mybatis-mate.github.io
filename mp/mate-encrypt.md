## 适用场景

![](https://minio.pigx.top/oss/1659239409.jpg)

!> 配套源码👉 [mybatis-mate-encrypt](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-encrypt)

数据库敏感数据被拖库后，避免因明文存储导致的数据泄露。
通常情况下，数据库中的数据是以明文形式进行存储和使用的，一旦数据文件（或备份文件）丢失，可能引发严重的数据泄露问题。而在拖库攻击中，明文存储的数据对于攻击者同样没有任何秘密可言。此时您需要对数据进行加密，避免数据泄露。

对高权限用户，数据库敏感数据加密可以防范内部窃取数据造成的数据泄露。
数据库加密可以提供独立于数据库系统自身权限控制体系之外的增强权限控制的能力，由专用的加密系统为数据库中的敏感数据设置访问权限，从而有效限制数据库超级用户或其他高权限用户对敏感数据的访问行为，保障数据安全。


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


#### ② 配置加密参数

```yaml
mybatis-mate:
  cert:
    grant: 
    license: 
  encryptor:
    # 对称算法密钥，随机字符串作为密钥即可（有些算法长度有要求，注意）
    password: 
    # 非对称加密 RSA 公钥私钥
    publicKey: 
    privateKey: 

```

#### ③ 实体字段 注解 @FieldEncrypt

```java
@Getter
@Setter
@ToString
public class User {
    private Long id;
    private String username;
    // 指定加密算法
    @FieldEncrypt(algorithm = Algorithm.PBEWithMD5AndDES)
    private String password;
    @FieldEncrypt
    private String email;
    @FieldEncrypt(algorithm = Algorithm.MD5_32)
    private String md5;
    @FieldEncrypt(algorithm = Algorithm.RSA)
    private String rsa;
}
```

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


## 进阶 IEncryptor手动执行加解密

```java
@Resource
private IEncryptor encryptor;
```

```java
String encryptEmail = encryptor.encrypt(algorithm, encryptorProperties.getPassword(), encryptorProperties.getPublicKey(), email, null);
System.err.println("加密内容：" + encryptEmail);
String decryptEmail = encryptor.decrypt(algorithm, encryptorProperties.getPassword(), encryptorProperties.getPrivateKey(), encryptEmail, null);
```