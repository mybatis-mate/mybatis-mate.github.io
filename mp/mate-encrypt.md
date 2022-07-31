## 字段加密解密

![1659239409](https://minio.pigx.vip/oss/1659239409.jpg)

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
