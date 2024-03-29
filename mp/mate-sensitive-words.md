## 使用场景

![](https://minio.pigx.top/oss/1659250878.jpg)

!> 配套源码: 👉 [mybatis-mate-sensitive-words](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sensitive-words)

## 快速开始

#### ① jar 包依赖

```java
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
<!--多模式匹配算法-->
<dependency>
    <groupId>org.ahocorasick</groupId>
    <artifactId>ahocorasick</artifactId>
    <version>0.6.3</version>
</dependency>
```

#### ② 配置敏感词加载处理逻辑

```java
@Bean
public IParamsProcessor paramsProcessor() {
return new SensitiveWordsProcessor() {

    /**
        // 可以指定你需要拦截处理的请求地址，默认 /* 所有请求
        @Override public Collection<String> getUrlPatterns() {
        return super.getUrlPatterns();
        }
        */

    @Override
    public List<String> loadSensitiveWords() {
        List<String> list = new ArrayList<>();
        list.add("王安石");
        return list;
    }

    @Override
    public String handle(String fieldName, String fieldValue, Collection<Emit> emits) {

        if (CollectionUtils.isEmpty(emits)) {
            return fieldValue;

        }
        String fv = fieldValue;
        for (Emit emit : emits) {
            // 发现敏感词 替换
            fv = fv.replaceAll(emit.getKeyword(), "");
        }
        return fv;
    }
};
}
```


#### ③ 测试运行

请求中包含的敏感字的数据，都会被脱敏接受

![](https://minio.pigx.top/oss/1659251421.png)


#### ④进阶： 处理post body

```java
@RestControllerAdvice
@RequiredArgsConstructor
public class SensitiveRequestBodyAdvice extends RequestBodyAdviceAdapter {

    private final IParamsProcessor paramsProcessor;


    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }


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