# Employee Command Service

A Spring Boot REST application that creates employees, updates employee email addresses, and deletes employees in PostgreSQL. This project demonstrates the command side of a CQRS-oriented design using a controller, service, and Spring Data JPA repository.

## Project documentation

- [Detailed project notes (Markdown)](PROJECT_NOTES.md)
- [Detailed project notes (Word)](PROJECT_NOTES.docx)

The notes explain CQRS, the employee use case, Spring Data JPA, `JpaRepository` versus `CrudRepository`, PostgreSQL properties, request and response DTOs, all three API execution flows, and the annotations used in the project.

## Technology

- Java 17 and Spring Boot 4.1.1, as declared in `pom.xml`
- Spring MVC for REST endpoints
- Spring Data JPA with Hibernate for persistence
- PostgreSQL with its JDBC driver
- Maven wrapper for builds and application startup

The POM adds `spring-boot-starter-jetty` and excludes `spring-boot-tomcat` from the MVC starter. The resolved runtime server has not been verified with a dependency tree or application startup.

## Architecture

```text
HTTP request
    -> EmployeeController
    -> EmployeeService / EmployeeServiceImpl
    -> EmployeeRepository
    -> JPA / Hibernate
    -> PostgreSQL
```

The application exposes write operations only. A separate query service, read model, event publisher, and event sourcing are not implemented. Reading an existing employee inside an update is part of processing that command.

## Local setup

1. Install JDK 17 and start PostgreSQL.
2. Create the database using a PostgreSQL client:

   ```sql
   CREATE DATABASE employee_db;
   ```

3. Configure [application.properties](src/main/resources/application.properties) or override the connection settings with environment variables. For example, in PowerShell:

   ```powershell
   $env:SPRING_DATASOURCE_URL = 'jdbc:postgresql://localhost:5432/employee_db'
   $env:SPRING_DATASOURCE_USERNAME = 'postgres'
   $env:SPRING_DATASOURCE_PASSWORD = '<your-local-database-password>'
   ```

4. Start the application from the project directory:

   ```powershell
   .\mvnw.cmd spring-boot:run
   ```

The examples use `http://localhost:8080`, the default port unless overridden. The Maven wrapper may download Maven and dependencies on first use.

The current `spring.jpa.hibernate.ddl-auto=update` setting lets Hibernate attempt to create or update tables in the existing database. It does not create `employee_db`. SQL logging and formatting are enabled in the supplied configuration.

## API endpoints

| Method | Path | Behavior | Successful response |
| --- | --- | --- | --- |
| POST | `/api/v1/employees` | Creates an employee with first name, last name, and email | `201 Created`, JSON employee details without ID |
| PUT | `/api/v1/employees/{id}` | Updates only the existing employee's email | Normally `200 OK`, empty body |
| DELETE | `/api/v1/employees/{id}` | Finds and deletes an existing employee | Normally `200 OK`, empty body |

### Create an employee

```powershell
$createBody = @{
    firstName = 'Anita'
    lastName = 'Rao'
    email = 'anita.rao@example.com'
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
    -Uri 'http://localhost:8080/api/v1/employees' `
    -ContentType 'application/json' `
    -Body $createBody
```

The POST response contains an `EmployeeResponse`:

```json
{
  "firstName": "Anita",
  "lastName": "Rao",
  "email": "anita.rao@example.com"
}
```

The database generates the employee ID, but the response does not include it and no `Location` header is set. There is no GET endpoint. Find the ID using a database client connected to `employee_db`:

```sql
SELECT id, first_name, last_name, email
FROM employees
WHERE email = 'anita.rao@example.com';
```

### Update an employee's email

Replace `1` with the actual generated ID:

```powershell
$employeeId = 1
$updateBody = @{ email = 'anita.updated@example.com' } | ConvertTo-Json

Invoke-RestMethod -Method Put `
    -Uri "http://localhost:8080/api/v1/employees/$employeeId" `
    -ContentType 'application/json' `
    -Body $updateBody
```

The update implementation ignores first and last names, even if supplied. Omitting email sets it to null if the database permits it.

### Delete an employee

Use the actual employee ID; this removes the stored row:

```powershell
Invoke-RestMethod -Method Delete `
    -Uri "http://localhost:8080/api/v1/employees/$employeeId"
```

The service first looks up the employee, then calls `delete(employee)`. Success normally returns `200 OK` with no body, rather than an explicitly configured `204 No Content`. A missing ID, including a repeated deletion, throws the same generic exception as an update.

## Current behavior and limitations

- First name is mapped as non-null, and email is mapped as unique. There is no DTO validation for blank names or email format.
- Missing employee IDs throw a generic exception, normally producing HTTP 500 rather than a custom 404 response.
- No custom error mapping exists for duplicate emails or other database constraints.
- Repository methods provide transaction behavior, but no service-level transaction spans the complete update or delete operation.
- The project has no GET endpoint.

These behaviors are documented from source inspection; the documentation does not claim that live API verification has been performed.

## Tests

```powershell
.\mvnw.cmd test
```

The existing `contextLoads()` test verifies application context startup only. With the current configuration it can require a running PostgreSQL database. It does not test the create, update, or delete API behavior.

## Refresh the Word notes

After editing `PROJECT_NOTES.md`, regenerate the Word document using the included PowerShell script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Export-ProjectNotes.ps1
```

The execution-policy option applies only to this PowerShell process; it does not change the machine's policy. The exporter uses .NET ZIP APIs and does not require Microsoft Word. It preserves the notes as Word headings, tables, lists, and code blocks; the two Mermaid diagrams become readable text flow diagrams.
