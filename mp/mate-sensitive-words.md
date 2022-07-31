## 数据敏感词过滤

👉 [mybatis-mate-sensitive-words](https://gitee.com/baomidou/mybatis-mate-examples/tree/master/mybatis-mate-sensitive-words)

- pom 依赖

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
