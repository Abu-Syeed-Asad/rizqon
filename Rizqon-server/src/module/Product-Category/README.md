# Product Category API

Base URL: `http://localhost:5000/api/v1/category`.

All routes require `Authorization: Bearer <accessToken>` and an active `RIZQON_CEO`, `RIZQON_MANAGER`, or `RIZQON_OWNER` user. These system-wide roles can manage categories across businesses, matching Brand and Branch.

| Method | Endpoint | Description |
| --- | --- | --- |
| POST | `/create-category` | Create a category |
| PATCH | `/update-category/:id` | Update a category |
| DELETE | `/delete-category/:id` | Permanently delete a category |
| GET | `/get-all-categories` | List all categories, newest first |
| GET | `/get-category/:id` | Find one category by its ID |

Replace `:id` with a real category CUID. POST and PATCH require `Content-Type: application/json`; GET and DELETE need no body.

Create example:

```json
{
  "businessId": "<existing-business-cuid>",
  "name": "Mobile Phones",
  "category_slug": "mobile-phones",
  "description": "Phones and smartphones",
  "parentId": null,
  "isActive": true
}
```

Required fields: `businessId`, `name`, `category_slug`. Description and parent ID are optional and nullable. `isActive` defaults to true. Names are trimmed, 2–150 characters, and cannot contain control characters. Slugs are trimmed, 1–100 characters, and allow lowercase letters/numbers separated by single hyphens. Slugs are unique per business. Description is limited to 2,000 characters.

Update example: `{"name":"Smartphones","category_slug":"smartphones"}`. At least one editable field is required. Omitted fields stay unchanged; use `parentId: null` to remove the parent and `description: null` to clear the description. Business ID cannot be changed. Unknown fields, invalid types, malformed IDs and empty updates return 400.

Parent categories must belong to the same business. Self-parenting and circular ancestor relationships return 409. Reparenting uses a serializable transaction; concurrent transaction conflicts return 409 and can be retried. The database foreign key also enforces the parent/business relationship.

Create returns 201; all other successful operations return 200. Success responses use `{ "success": true, "message": "...", "data": ... }`. Empty lists return `data: []`; missing individual categories and businesses return 404. A missing or wrong-business parent returns 404.

Duplicate slugs and deletion blocked by products or child categories return 409 through the central error handler. Database outages return 503; unexpected internal failures return sanitized 500 responses. No module-specific Prisma error handler is used.

Routes handle authentication, authorization and Zod request validation. Controllers use `catchAsync` and `send_Response`. Services validate inputs and check record existence.

Verification: `node --import tsx --test tests/category.test.ts`. Database operations and transactions are mocked; these tests do not modify live records or prove live concurrent transaction behavior.
