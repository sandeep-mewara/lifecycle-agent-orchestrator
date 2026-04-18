# Java Testing — Checklist

## When Writing Unit Tests

- [ ] Test class named `<ClassName>Test` in matching package under `src/test/java/`
- [ ] JUnit 5 `@Test` annotation on all test methods
- [ ] `@ExtendWith(MockitoExtension.class)` for mock injection
- [ ] `@Mock` for dependencies, `@InjectMocks` for the class under test
- [ ] AssertJ assertions preferred (`assertThat(...).isEqualTo(...)`)
- [ ] `assertThatThrownBy()` for exception assertions — check type and message
- [ ] `@DisplayName` for complex test scenarios
- [ ] `@ParameterizedTest` with `@ValueSource` / `@CsvSource` for data-driven tests

## When Writing Integration Tests

- [ ] `@SpringBootTest` for full context integration tests
- [ ] `@WebMvcTest` for controller-only tests (lighter than full context)
- [ ] `@Testcontainers` for database/infrastructure dependencies
- [ ] `@ActiveProfiles("test")` for test configuration
- [ ] `MockMvc` or `WebTestClient` for HTTP endpoint testing
- [ ] `@DirtiesContext` only when test mutates shared state (avoid where possible)
- [ ] Tests marked with `@Tag("integration")`

## Maven / Gradle

- [ ] Surefire plugin for unit tests, Failsafe plugin for integration tests
- [ ] JaCoCo configured with >=85% line coverage threshold
- [ ] Test reports in standard location (`target/surefire-reports/`)
- [ ] Spotless or Checkstyle in verify phase

## Agent Evaluation Tests

- [ ] Tests tagged with `@Tag("agent-evaluation")`
- [ ] Excluded from default test phase (`-DexcludedGroups=agent-evaluation`)
- [ ] Separate CI stage for evaluation runs
