# Products

Create, update, and delete requests require `Authorization: Bearer <access-token>`. The authenticated database user's email is used to find employee records, also constrained by the authenticated user ID. The body businessId must match an active employee record with job title `INVENTORY_MANAGER`, `INVENTORY_OFFICER`, or `WAREHOUSE_MANAGER`, and an assignment to an active branch in that business. The employee ID is derived from stored records. The branchId URL parameter must match an assignment for that employee in the body businessId, and the referenced branch must be active and belong to the same business. Assignment to a different branch does not authorize the requested branch. No system-role or owner bypass applies.

Base path: `/api/v1/product`

| Method | Path |
| --- | --- |
| GET | /get-all-products |
| GET | /get-product/:id |
| POST | /create-product/:branchId |
| PATCH | /update-product/:branchId/:id |
| DELETE | /delete-product/:branchId/:id |

GET endpoints are public and require no Authorization header. They return active products only; a missing or inactive product returns 404. The list returns an empty array when no active products exist.

IDs must be CUIDs. The final `id` is the product ID.

Create body:

```json
{
  "businessId": "<business CUID>",
  "name": "Cotton T-shirt",
  "slug": "cotton-t-shirt",
  "description": "Blue cotton T-shirt",
  "unit": "piece",
  "price": "450.00",
  "categoryId": "<category CUID>",
  "brandId": null
}
```

BusinessId, name, slug, price, and categoryId are required. Unit defaults to piece; description and brandId are optional. isActive is optional. Prices must be nonnegative with at most 16 integer digits and 2 decimal places; strings preserve decimal precision.

PATCH requires businessId plus any nonempty subset of product fields. DELETE requires a JSON body containing businessId only. The businessId authorizes the request and cannot move the product to another business. Client-supplied branchId, employeeId, userId, email, and id are rejected in request bodies. Set brandId or description to null to clear them. Categories and brands must belong to the same business; categories must be active. Slugs are unique per business.

Products are business-wide in the existing schema. Stored active branch membership authorizes the operation; it does not limit the product to a branch. DELETE permanently removes a product when database relationships allow it; dependent variants cause a conflict. To retain a product, PATCH with `{ "isActive": false }`.

Success returns the existing API response envelope with the product in data (201 for create, 200 for update/delete). Authentication failures return 401, authorization failures 403, missing products 404, and unique/foreign-key conflicts 409.



