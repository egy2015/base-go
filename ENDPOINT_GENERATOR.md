# Endpoint Code Generation

This boilerplate includes a powerful code generation system to scaffold new API endpoints quickly.

## Quick Start

### Generate a Full CRUD endpoint

```bash
make create-endpoint NAME=products METHODS=c,r,u,d
```

This creates:
- `models/products.go` - Data model with full struct
- `controllers/products.go` - All CRUD handlers
- `scripts/products_routes.txt` - Route definitions to add to your router
- `database/migrations/[timestamp]_create_products_table.sql` - Database migration

### Generate a Read-only endpoint

```bash
make create-endpoint NAME=dashboard METHODS=r
```

Creates only GET handlers (list and by ID).

### Generate Custom operations

```bash
make create-endpoint NAME=reports METHODS=r,c,u
```

Supported operations:
- `c` - Create (POST)
- `r` - Read (GET)
- `u` - Update (PUT)
- `d` - Delete (DELETE)

## Managing Endpoints

### List all generated endpoints

```bash
bash scripts/list-endpoints.sh
```

Shows all endpoints tracked in the registry with their status.

### Rollback an endpoint

```bash
make rollback NAME=products
```

Removes:
- ✓ Model file (`models/products.go`)
- ✓ Controller file (`controllers/products.go`)
- ✓ Routes snippet (`scripts/products_routes.txt`)
- ✓ Migration file
- ✓ Registry entry

**Note:** You must manually remove route registrations from `routes/routes.go` if they were added.

## Generated Files

### 1. Model (`models/[name].go`)

Contains the GORM model struct with:
- Auto-incrementing ID
- Name field (customize as needed)
- Timestamps (created_at, updated_at)
- Soft delete support (deleted_at)

**What you need to do:** Customize the fields to match your data structure.

```go
type Product struct {
    ID    uint   `gorm:"primaryKey" json:"id"`
    Name  string `gorm:"not null" json:"name"`
    Price float64 `json:"price"`  // Add your fields
    // ...
}
```

### 2. Controller (`controllers/[name].go`)

Generated handlers for each selected operation:
- `GetAll[Name]()` - List all items
- `Get[Name]ByID()` - Get single item
- `Create[Name]()` - Create new item
- `Update[Name]()` - Update existing item
- `Delete[Name]()` - Delete item

All handlers follow the same patterns:
- Proper error handling
- GORM integration
- JSON response formatting
- Appropriate HTTP status codes

### 3. Routes (`scripts/[name]_routes.txt`)

Contains the exact route definitions to add to `routes/routes.go`:

```go
// Copy these lines into SetupRoutes()
protectedRoutes.GET("/products", controllers.GetAllProducts(db))
protectedRoutes.GET("/products/:id", controllers.GetProductByID(db))
protectedRoutes.POST("/products", controllers.CreateProducts(db))
protectedRoutes.PUT("/products/:id", controllers.UpdateProducts(db))
protectedRoutes.DELETE("/products/:id", controllers.DeleteProducts(db))
```

### 4. Migration (`database/migrations/[timestamp]_create_[name]_table.sql`)

SQL migration file for your database table. Customize the schema as needed:

```sql
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
```

## Integration Steps

After generating an endpoint, follow these steps:

1. **Customize the Model**
   ```go
   // models/products.go
   type Product struct {
       ID    uint    `gorm:"primaryKey" json:"id"`
       Name  string  `gorm:"not null" json:"name"`
       Price float64 `json:"price"`        // Add fields
       Stock int     `gorm:"default:0" json:"stock"`
   }
   ```

2. **Update the Migration**
   ```sql
   -- Add columns to match your model
   CREATE TABLE products (
       id SERIAL PRIMARY KEY,
       name VARCHAR(255) NOT NULL,
       price DECIMAL(10, 2) NOT NULL,
       stock INT DEFAULT 0,
       created_at TIMESTAMP,
       updated_at TIMESTAMP,
       deleted_at TIMESTAMP NULL
   );
   ```

3. **Add Routes to your Router**
   ```go
   // routes/routes.go - Copy from scripts/[name]_routes.txt
   protectedRoutes.GET("/products", controllers.GetAllProducts(db))
   protectedRoutes.POST("/products", controllers.CreateProducts(db))
   // ... other routes
   ```

4. **Register the Model with GORM**
   ```go
   // database/migrations.go - Add to AutoMigrate()
   db.AutoMigrate(&models.Product{})
   ```

5. **Run your application**
   ```bash
   make run
   ```

## Example: Creating a Roles endpoint

```bash
make create-endpoint NAME=roles METHODS=c,r,u,d
```

This generates:
- Full CRUD endpoints at `/api/v1/roles`
- Model with ID, Name, timestamps
- Database table `roles`

Then customize:

```go
// models/roles.go - Add permissions field
type Role struct {
    ID          uint      `gorm:"primaryKey" json:"id"`
    Name        string    `gorm:"not null;unique" json:"name"`
    Permissions string    `json:"permissions"` // Add custom fields
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}
```

## Advanced Usage

### Multiple Methods

Generate with multiple operations in one command:

```bash
# CRUD operations
make create-endpoint NAME=users METHODS=c,r,u,d

# Read + Create only
make create-endpoint NAME=logs METHODS=r,c

# Read-only
make create-endpoint NAME=analytics METHODS=r
```

### File Organization

The generator maintains clean separation:

```
api/
├── models/
│   ├── user.go          (existing)
│   └── products.go      (new)
├── controllers/
│   ├── auth.go          (existing)
│   └── products.go      (new)
├── routes/
│   └── routes.go        (edit to add)
└── database/
    └── migrations/
        ├── user_migrations.sql
        └── [timestamp]_create_products_table.sql
```

## Rollback Workflow

Accidentally created an endpoint? No problem:

```bash
# Create an endpoint
make create-endpoint NAME=temp_endpoint METHODS=c,r,u,d

# Realize you don't need it
make rollback NAME=temp_endpoint

# All generated files removed, registry updated
```

The rollback feature safely cleans up all generated artifacts while preserving your existing code.

## Tips

- Always customize generated fields to match your domain model
- Review migrations before running them
- The scaffolded code follows Go best practices and project conventions
- All endpoints are protected by default (JWT required)
- Change routes to public if needed: `router.GET(...)` instead of `protectedRoutes.GET(...)`
- Use `bash scripts/list-endpoints.sh` to see what you've generated
- Rollback is safe and non-destructive for existing code
