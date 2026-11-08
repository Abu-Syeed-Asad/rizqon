-- CreateEnum
CREATE TYPE "commerce"."EMPLOYEE_JOB_TITLE" AS ENUM ('OWNER', 'CO_OWNER', 'MANAGING_DIRECTOR', 'GENERAL_MANAGER', 'OPERATIONS_MANAGER', 'BRANCH_MANAGER', 'ASSISTANT_MANAGER', 'SUPERVISOR', 'HR_MANAGER', 'HR_OFFICER', 'FINANCE_MANAGER', 'SENIOR_ACCOUNTANT', 'ACCOUNTANT', 'JUNIOR_ACCOUNTANT', 'ACCOUNTS_ASSISTANT', 'INVENTORY_MANAGER', 'INVENTORY_OFFICER', 'WAREHOUSE_MANAGER', 'STOREKEEPER', 'STOCK_ASSISTANT', 'PURCHASE_MANAGER', 'PURCHASE_OFFICER', 'SALES_MANAGER', 'SALES_EXECUTIVE', 'SALES_ASSOCIATE', 'CASHIER', 'MARKETING_MANAGER', 'MARKETING_EXECUTIVE', 'CUSTOMER_SERVICE_MANAGER', 'CUSTOMER_SERVICE_REPRESENTATIVE', 'DELIVERY_SUPERVISOR', 'DELIVERY_PERSON', 'DRIVER', 'PACKER', 'IT_MANAGER', 'IT_SUPPORT', 'DATA_ENTRY_OPERATOR', 'SECURITY_SUPERVISOR', 'SECURITY_GUARD', 'CLEANER', 'OFFICE_ASSISTANT', 'INTERN', 'OTHER');

-- CreateEnum
CREATE TYPE "commerce"."PAYMENT_METHOD" AS ENUM ('CASH', 'CARD', 'MOBILE_BANKING', 'BANK_TRANSFER');

-- CreateEnum
CREATE TYPE "commerce"."BUSINESS_STATUS" AS ENUM ('ACTIVE', 'SUSPENDED', 'CLOSED');

-- CreateEnum
CREATE TYPE "commerce"."CART_STATUS" AS ENUM ('ACTIVE', 'CHECKED_OUT', 'ABANDONED');

-- CreateEnum
CREATE TYPE "commerce"."COMMISSION_EVENT_TYPE" AS ENUM ('SALE', 'RETURN');

-- CreateEnum
CREATE TYPE "commerce"."COMMISSION_SETTLEMENT_STATUS" AS ENUM ('DRAFT', 'FINALIZED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "commerce"."COMPANY_EXPENSE_TYPE" AS ENUM ('SALARY', 'RENT', 'UTILITIES', 'TRANSPORT', 'MAINTENANCE', 'OTHER');

-- CreateEnum
CREATE TYPE "commerce"."NOTIFICATION_TYPE" AS ENUM ('PAYMENT', 'ROLE_UPDATED', 'PRODUCT_ADDED', 'LOW_STOCK', 'RETURN', 'COMMISSION');

-- CreateEnum
CREATE TYPE "commerce"."PARTNER_KIND" AS ENUM ('SUPPLIER', 'COMMISSION_PARTNER', 'BOTH');

-- CreateEnum
CREATE TYPE "commerce"."PAYMENT_DIRECTION" AS ENUM ('IN', 'OUT');

-- CreateEnum
CREATE TYPE "commerce"."SALE_STATUS" AS ENUM ('DRAFT', 'COMPLETED', 'VOID');

-- CreateEnum
CREATE TYPE "commerce"."SALE_RETURN_STATUS" AS ENUM ('REQUESTED', 'APPROVED', 'REJECTED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "commerce"."STOCK_MOVEMENT_TYPE" AS ENUM ('OPENING', 'PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT', 'CONSIGNMENT_IN', 'CONSIGNMENT_OUT');

-- CreateEnum
CREATE TYPE "commerce"."PURCHASE_STATUS" AS ENUM ('DRAFT', 'RECEIVED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "commerce"."AUDIT_LOG_TYPE" AS ENUM ('CREATED', 'UPDATED', 'DELETED', 'ACTIVATED', 'DEACTIVATED', 'BUSINESS_SUSPENDED', 'BUSINESS_REACTIVATED', 'BUSINESS_CLOSED', 'OWNERSHIP_TRANSFERRED', 'EMPLOYEE_ROLE_CHANGED', 'EMPLOYEE_BRANCH_ASSIGNED', 'EMPLOYEE_BRANCH_REMOVED', 'PERMISSION_GRANTED', 'PERMISSION_REVOKED', 'PRODUCT_PRICE_CHANGED', 'PRODUCT_COST_CHANGED', 'OPENING_STOCK_RECORDED', 'STOCK_ADJUSTED', 'STOCK_TRANSFERRED', 'CONSIGNMENT_RECEIVED', 'CONSIGNMENT_RETURNED', 'CART_CHECKED_OUT', 'CART_ABANDONED', 'SALE_COMPLETED', 'SALE_VOIDED', 'INVOICE_GENERATED', 'PURCHASE_RECEIVED', 'PURCHASE_CANCELLED', 'PAYMENT_INITIATED', 'PAYMENT_SUCCEEDED', 'PAYMENT_FAILED', 'PAYMENT_CANCELLED', 'RETURN_REQUESTED', 'RETURN_APPROVED', 'RETURN_REJECTED', 'RETURN_COMPLETED', 'REFUND_INITIATED', 'REFUND_SUCCEEDED', 'REFUND_FAILED', 'REFUND_CANCELLED', 'EXPENSE_RECORDED', 'EXPENSE_UPDATED', 'COMMISSION_ACCRUED', 'COMMISSION_REVERSED', 'SETTLEMENT_FINALIZED', 'SETTLEMENT_CANCELLED', 'OUTBOX_RETRIED');

-- CreateEnum
CREATE TYPE "commerce"."ENTITY_TYPE" AS ENUM ('USER', 'BUSINESS', 'BRANCH', 'EMPLOYEE', 'EMPLOYEE_BRANCH', 'ROLE', 'PERMISSION', 'ROLE_PERMISSION', 'CUSTOMER', 'PARTNER', 'CATEGORY', 'BRAND', 'PRODUCT', 'PRODUCT_VARIANT', 'INVENTORY', 'STOCK_MOVEMENT', 'CART', 'CART_ITEM', 'SALE', 'SALE_ITEM', 'PURCHASE', 'PURCHASE_ITEM', 'PAYMENT', 'PAYMENT_EVENT', 'SALE_RETURN', 'RETURN_ITEM', 'REFUND', 'EXPENSE', 'COMMISSION_AGREEMENT', 'COMMISSION_ENTRY', 'COMMISSION_SETTLEMENT', 'NOTIFICATION', 'OUTBOX_EVENT');

-- DropEnum
DROP TYPE "commerce"."role_code";

-- CreateTable
CREATE TABLE "commerce"."Brand" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "brand_name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Brand_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Business" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "business_slug" TEXT NOT NULL,
    "legalName" TEXT,
    "registrationNumber" TEXT,
    "taxIdentificationNumber" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "address" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "status" "commerce"."BUSINESS_STATUS" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Business_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Cart" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "status" "commerce"."CART_STATUS" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "branchId" TEXT NOT NULL,
    "customerId" TEXT,
    "creatorId" TEXT NOT NULL,

    CONSTRAINT "Cart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."CartItem" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "cartId" TEXT NOT NULL,
    "variantId" TEXT NOT NULL,

    CONSTRAINT "CartItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Category" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category_slug" TEXT NOT NULL,
    "description" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "parentId" TEXT,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."CommissionAgreement" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "business_name" TEXT NOT NULL,
    "commissionPercent" DECIMAL(5,2) NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endsAt" TIMESTAMP(3),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "partnerId" TEXT NOT NULL,

    CONSTRAINT "CommissionAgreement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."CommissionEntry" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "eventKey" TEXT NOT NULL,
    "eventType" "commerce"."COMMISSION_EVENT_TYPE" NOT NULL,
    "grossBase" DECIMAL(18,2) NOT NULL,
    "commissionPercent" DECIMAL(5,2) NOT NULL,
    "commissionAmount" DECIMAL(18,2) NOT NULL,
    "partnerPayable" DECIMAL(18,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "agreementId" TEXT NOT NULL,
    "saleItemId" TEXT NOT NULL,
    "returnItemId" TEXT,
    "settlementId" TEXT,

    CONSTRAINT "CommissionEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."CommissionSettlement" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "settlement_reference" TEXT NOT NULL,
    "settlement_status" "commerce"."COMMISSION_SETTLEMENT_STATUS" NOT NULL DEFAULT 'DRAFT',
    "amount" DECIMAL(18,2) NOT NULL,
    "finalizedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "partnerId" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,

    CONSTRAINT "CommissionSettlement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Customer" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "address" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Employee" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "employeeCode" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "jobTitle" "commerce"."EMPLOYEE_JOB_TITLE" NOT NULL,
    "email" TEXT,
    "baseSalary" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "roleId" TEXT NOT NULL,
    "userId" UUID,

    CONSTRAINT "Employee_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."EmployeeBranch" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "employeeId" TEXT NOT NULL,
    "branchId" TEXT NOT NULL,

    CONSTRAINT "EmployeeBranch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Expense" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "category" "commerce"."COMPANY_EXPENSE_TYPE" NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "description" TEXT NOT NULL,
    "incurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "salaryPeriod" TEXT,
    "receiptUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "branchId" TEXT,
    "employeeId" TEXT,
    "creatorId" TEXT NOT NULL,

    CONSTRAINT "Expense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Inventory" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
    "reinstall_alert_level" DECIMAL(18,3) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "branchId" TEXT NOT NULL,
    "variantId" TEXT NOT NULL,

    CONSTRAINT "Inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Notification" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "type" "commerce"."NOTIFICATION_TYPE" NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "entityType" TEXT,
    "entityId" TEXT,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "recipientId" UUID NOT NULL,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."OutboxEvent" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "eventKey" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "availableAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lockedUntil" TIMESTAMP(3),
    "processedAt" TIMESTAMP(3),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OutboxEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Partner" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "kind" "commerce"."PARTNER_KIND" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "linkedBusinessId" TEXT,

    CONSTRAINT "Partner_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Payment" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "direction" "commerce"."PAYMENT_DIRECTION" NOT NULL,
    "method" "commerce"."PAYMENT_METHOD" NOT NULL,
    "status" "commerce"."payment_status" NOT NULL DEFAULT 'PENDING',
    "amount" DECIMAL(18,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "provider" TEXT,
    "providerReference" TEXT,
    "idempotencyKey" TEXT NOT NULL,
    "paidAt" TIMESTAMP(3),
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "saleId" TEXT,
    "purchaseId" TEXT,
    "expenseId" TEXT,
    "settlementId" TEXT,
    "recorderId" TEXT,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."PaymentEvent" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerEventId" TEXT NOT NULL,
    "payloadHash" TEXT NOT NULL,
    "processedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "paymentId" TEXT,
    "refundId" TEXT,

    CONSTRAINT "PaymentEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Product" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "unit" TEXT NOT NULL DEFAULT 'piece',
    "price" DECIMAL(18,2) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "categoryId" TEXT NOT NULL,
    "brandId" TEXT,

    CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."ProductVariant" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "barcode" TEXT,
    "size" TEXT,
    "color" TEXT,
    "attributes" JSONB,
    "sellingPrice" DECIMAL(18,2) NOT NULL,
    "costPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "productId" TEXT NOT NULL,
    "agreementId" TEXT,

    CONSTRAINT "ProductVariant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Purchase" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "invoiceNumber" TEXT NOT NULL,
    "supplierInvoiceNumber" TEXT,
    "status" "commerce"."PURCHASE_STATUS" NOT NULL DEFAULT 'DRAFT',
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "totalAmount" DECIMAL(18,2) NOT NULL,
    "receivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "branchId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,

    CONSTRAINT "Purchase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."PurchaseItem" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "unitCost" DECIMAL(18,2) NOT NULL,
    "lineTotal" DECIMAL(18,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "purchaseId" TEXT NOT NULL,
    "variantId" TEXT NOT NULL,

    CONSTRAINT "PurchaseItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Refund" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "method" "commerce"."PAYMENT_METHOD" NOT NULL,
    "status" "commerce"."payment_status" NOT NULL DEFAULT 'PENDING',
    "idempotencyKey" TEXT NOT NULL,
    "provider" TEXT,
    "providerReference" TEXT,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "paymentId" TEXT NOT NULL,
    "saleReturnId" TEXT NOT NULL,

    CONSTRAINT "Refund_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."ReturnItem" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "refundAmount" DECIMAL(18,2) NOT NULL,
    "commissionReversal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "restock" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "saleReturnId" TEXT NOT NULL,
    "saleItemId" TEXT NOT NULL,

    CONSTRAINT "ReturnItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Sale" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "invoiceNumber" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "requestHash" TEXT NOT NULL,
    "status" "commerce"."SALE_STATUS" NOT NULL DEFAULT 'DRAFT',
    "customerNameSnapshot" TEXT,
    "customerAddressSnapshot" TEXT,
    "sellerNameSnapshot" TEXT NOT NULL,
    "sellerAddressSnapshot" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "subtotal" DECIMAL(18,2) NOT NULL,
    "discountTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "taxTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "grandTotal" DECIMAL(18,2) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "branchId" TEXT NOT NULL,
    "customerId" TEXT,
    "cashierId" TEXT NOT NULL,
    "cartId" TEXT,

    CONSTRAINT "Sale_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."SaleItem" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "productName" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "unitPrice" DECIMAL(18,2) NOT NULL,
    "unitCost" DECIMAL(18,2) NOT NULL,
    "discountAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "taxAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "lineTotal" DECIMAL(18,2) NOT NULL,
    "commissionPercent" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "commissionAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "saleId" TEXT NOT NULL,
    "variantId" TEXT NOT NULL,
    "agreementId" TEXT,

    CONSTRAINT "SaleItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."SaleReturn" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "returnNumber" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "status" "commerce"."SALE_RETURN_STATUS" NOT NULL DEFAULT 'REQUESTED',
    "reason" TEXT NOT NULL,
    "totalAmount" DECIMAL(18,2) NOT NULL,
    "processedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "saleId" TEXT NOT NULL,
    "processorId" TEXT NOT NULL,

    CONSTRAINT "SaleReturn_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."StockMovement" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "delta" DECIMAL(18,3) NOT NULL,
    "kind" "commerce"."STOCK_MOVEMENT_TYPE" NOT NULL,
    "sourceType" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "eventKey" TEXT NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "inventoryId" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,

    CONSTRAINT "StockMovement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."AuditLog" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "action" "commerce"."AUDIT_LOG_TYPE" NOT NULL,
    "entityType" "commerce"."ENTITY_TYPE" NOT NULL,
    "entityId" TEXT NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "requestId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "actorId" TEXT,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."Branch" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "branch_code" TEXT NOT NULL,
    "address" TEXT,
    "phone" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Branch_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Brand_businessId_idx" ON "commerce"."Brand"("businessId");

-- CreateIndex
CREATE UNIQUE INDEX "Brand_businessId_id_key" ON "commerce"."Brand"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Brand_businessId_brand_name_key" ON "commerce"."Brand"("businessId", "brand_name");

-- CreateIndex
CREATE UNIQUE INDEX "Business_business_slug_key" ON "commerce"."Business"("business_slug");

-- CreateIndex
CREATE INDEX "Cart_businessId_idx" ON "commerce"."Cart"("businessId");

-- CreateIndex
CREATE INDEX "Cart_businessId_branchId_idx" ON "commerce"."Cart"("businessId", "branchId");

-- CreateIndex
CREATE INDEX "Cart_businessId_customerId_idx" ON "commerce"."Cart"("businessId", "customerId");

-- CreateIndex
CREATE INDEX "Cart_businessId_creatorId_idx" ON "commerce"."Cart"("businessId", "creatorId");

-- CreateIndex
CREATE UNIQUE INDEX "Cart_businessId_id_key" ON "commerce"."Cart"("businessId", "id");

-- CreateIndex
CREATE INDEX "CartItem_businessId_idx" ON "commerce"."CartItem"("businessId");

-- CreateIndex
CREATE INDEX "CartItem_businessId_cartId_idx" ON "commerce"."CartItem"("businessId", "cartId");

-- CreateIndex
CREATE INDEX "CartItem_businessId_variantId_idx" ON "commerce"."CartItem"("businessId", "variantId");

-- CreateIndex
CREATE UNIQUE INDEX "CartItem_businessId_id_key" ON "commerce"."CartItem"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "CartItem_businessId_cartId_variantId_key" ON "commerce"."CartItem"("businessId", "cartId", "variantId");

-- CreateIndex
CREATE INDEX "Category_businessId_idx" ON "commerce"."Category"("businessId");

-- CreateIndex
CREATE INDEX "Category_businessId_parentId_idx" ON "commerce"."Category"("businessId", "parentId");

-- CreateIndex
CREATE UNIQUE INDEX "Category_businessId_id_key" ON "commerce"."Category"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Category_businessId_category_slug_key" ON "commerce"."Category"("businessId", "category_slug");

-- CreateIndex
CREATE INDEX "CommissionAgreement_businessId_idx" ON "commerce"."CommissionAgreement"("businessId");

-- CreateIndex
CREATE INDEX "CommissionAgreement_businessId_partnerId_idx" ON "commerce"."CommissionAgreement"("businessId", "partnerId");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionAgreement_businessId_id_key" ON "commerce"."CommissionAgreement"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionEntry_eventKey_key" ON "commerce"."CommissionEntry"("eventKey");

-- CreateIndex
CREATE INDEX "CommissionEntry_businessId_idx" ON "commerce"."CommissionEntry"("businessId");

-- CreateIndex
CREATE INDEX "CommissionEntry_businessId_agreementId_idx" ON "commerce"."CommissionEntry"("businessId", "agreementId");

-- CreateIndex
CREATE INDEX "CommissionEntry_businessId_saleItemId_idx" ON "commerce"."CommissionEntry"("businessId", "saleItemId");

-- CreateIndex
CREATE INDEX "CommissionEntry_businessId_returnItemId_idx" ON "commerce"."CommissionEntry"("businessId", "returnItemId");

-- CreateIndex
CREATE INDEX "CommissionEntry_businessId_settlementId_idx" ON "commerce"."CommissionEntry"("businessId", "settlementId");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionEntry_businessId_id_key" ON "commerce"."CommissionEntry"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionEntry_businessId_eventKey_key" ON "commerce"."CommissionEntry"("businessId", "eventKey");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionSettlement_settlement_reference_key" ON "commerce"."CommissionSettlement"("settlement_reference");

-- CreateIndex
CREATE INDEX "CommissionSettlement_businessId_idx" ON "commerce"."CommissionSettlement"("businessId");

-- CreateIndex
CREATE INDEX "CommissionSettlement_businessId_partnerId_idx" ON "commerce"."CommissionSettlement"("businessId", "partnerId");

-- CreateIndex
CREATE INDEX "CommissionSettlement_businessId_creatorId_idx" ON "commerce"."CommissionSettlement"("businessId", "creatorId");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionSettlement_businessId_id_key" ON "commerce"."CommissionSettlement"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionSettlement_businessId_settlement_reference_key" ON "commerce"."CommissionSettlement"("businessId", "settlement_reference");

-- CreateIndex
CREATE INDEX "Customer_businessId_idx" ON "commerce"."Customer"("businessId");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_businessId_id_key" ON "commerce"."Customer"("businessId", "id");

-- CreateIndex
CREATE INDEX "Employee_businessId_idx" ON "commerce"."Employee"("businessId");

-- CreateIndex
CREATE INDEX "Employee_businessId_roleId_idx" ON "commerce"."Employee"("businessId", "roleId");

-- CreateIndex
CREATE INDEX "Employee_userId_idx" ON "commerce"."Employee"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Employee_businessId_id_key" ON "commerce"."Employee"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Employee_businessId_employeeCode_key" ON "commerce"."Employee"("businessId", "employeeCode");

-- CreateIndex
CREATE UNIQUE INDEX "Employee_businessId_userId_key" ON "commerce"."Employee"("businessId", "userId");

-- CreateIndex
CREATE INDEX "EmployeeBranch_businessId_idx" ON "commerce"."EmployeeBranch"("businessId");

-- CreateIndex
CREATE INDEX "EmployeeBranch_businessId_employeeId_idx" ON "commerce"."EmployeeBranch"("businessId", "employeeId");

-- CreateIndex
CREATE INDEX "EmployeeBranch_businessId_branchId_idx" ON "commerce"."EmployeeBranch"("businessId", "branchId");

-- CreateIndex
CREATE UNIQUE INDEX "EmployeeBranch_businessId_id_key" ON "commerce"."EmployeeBranch"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "EmployeeBranch_businessId_employeeId_branchId_key" ON "commerce"."EmployeeBranch"("businessId", "employeeId", "branchId");

-- CreateIndex
CREATE INDEX "Expense_businessId_idx" ON "commerce"."Expense"("businessId");

-- CreateIndex
CREATE INDEX "Expense_businessId_branchId_idx" ON "commerce"."Expense"("businessId", "branchId");

-- CreateIndex
CREATE INDEX "Expense_businessId_employeeId_idx" ON "commerce"."Expense"("businessId", "employeeId");

-- CreateIndex
CREATE INDEX "Expense_businessId_creatorId_idx" ON "commerce"."Expense"("businessId", "creatorId");

-- CreateIndex
CREATE UNIQUE INDEX "Expense_businessId_id_key" ON "commerce"."Expense"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Expense_businessId_employeeId_salaryPeriod_key" ON "commerce"."Expense"("businessId", "employeeId", "salaryPeriod");

-- CreateIndex
CREATE INDEX "Inventory_businessId_idx" ON "commerce"."Inventory"("businessId");

-- CreateIndex
CREATE INDEX "Inventory_businessId_branchId_idx" ON "commerce"."Inventory"("businessId", "branchId");

-- CreateIndex
CREATE INDEX "Inventory_businessId_variantId_idx" ON "commerce"."Inventory"("businessId", "variantId");

-- CreateIndex
CREATE UNIQUE INDEX "Inventory_businessId_id_key" ON "commerce"."Inventory"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Inventory_businessId_branchId_variantId_key" ON "commerce"."Inventory"("businessId", "branchId", "variantId");

-- CreateIndex
CREATE INDEX "Notification_businessId_idx" ON "commerce"."Notification"("businessId");

-- CreateIndex
CREATE INDEX "Notification_recipientId_idx" ON "commerce"."Notification"("recipientId");

-- CreateIndex
CREATE UNIQUE INDEX "Notification_businessId_id_key" ON "commerce"."Notification"("businessId", "id");

-- CreateIndex
CREATE INDEX "OutboxEvent_processedAt_availableAt_idx" ON "commerce"."OutboxEvent"("processedAt", "availableAt");

-- CreateIndex
CREATE INDEX "OutboxEvent_businessId_idx" ON "commerce"."OutboxEvent"("businessId");

-- CreateIndex
CREATE UNIQUE INDEX "OutboxEvent_businessId_id_key" ON "commerce"."OutboxEvent"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "OutboxEvent_businessId_eventKey_key" ON "commerce"."OutboxEvent"("businessId", "eventKey");

-- CreateIndex
CREATE INDEX "Partner_businessId_idx" ON "commerce"."Partner"("businessId");

-- CreateIndex
CREATE INDEX "Partner_linkedBusinessId_idx" ON "commerce"."Partner"("linkedBusinessId");

-- CreateIndex
CREATE UNIQUE INDEX "Partner_businessId_id_key" ON "commerce"."Partner"("businessId", "id");

-- CreateIndex
CREATE INDEX "Payment_businessId_idx" ON "commerce"."Payment"("businessId");

-- CreateIndex
CREATE INDEX "Payment_businessId_saleId_idx" ON "commerce"."Payment"("businessId", "saleId");

-- CreateIndex
CREATE INDEX "Payment_businessId_purchaseId_idx" ON "commerce"."Payment"("businessId", "purchaseId");

-- CreateIndex
CREATE INDEX "Payment_businessId_expenseId_idx" ON "commerce"."Payment"("businessId", "expenseId");

-- CreateIndex
CREATE INDEX "Payment_businessId_settlementId_idx" ON "commerce"."Payment"("businessId", "settlementId");

-- CreateIndex
CREATE INDEX "Payment_businessId_recorderId_idx" ON "commerce"."Payment"("businessId", "recorderId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_businessId_id_key" ON "commerce"."Payment"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_businessId_idempotencyKey_key" ON "commerce"."Payment"("businessId", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_provider_providerReference_key" ON "commerce"."Payment"("provider", "providerReference");

-- CreateIndex
CREATE INDEX "PaymentEvent_businessId_idx" ON "commerce"."PaymentEvent"("businessId");

-- CreateIndex
CREATE INDEX "PaymentEvent_businessId_paymentId_idx" ON "commerce"."PaymentEvent"("businessId", "paymentId");

-- CreateIndex
CREATE INDEX "PaymentEvent_businessId_refundId_idx" ON "commerce"."PaymentEvent"("businessId", "refundId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentEvent_businessId_id_key" ON "commerce"."PaymentEvent"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentEvent_provider_providerEventId_key" ON "commerce"."PaymentEvent"("provider", "providerEventId");

-- CreateIndex
CREATE INDEX "Product_businessId_idx" ON "commerce"."Product"("businessId");

-- CreateIndex
CREATE INDEX "Product_businessId_categoryId_idx" ON "commerce"."Product"("businessId", "categoryId");

-- CreateIndex
CREATE INDEX "Product_businessId_brandId_idx" ON "commerce"."Product"("businessId", "brandId");

-- CreateIndex
CREATE UNIQUE INDEX "Product_businessId_id_key" ON "commerce"."Product"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Product_businessId_slug_key" ON "commerce"."Product"("businessId", "slug");

-- CreateIndex
CREATE INDEX "ProductVariant_businessId_idx" ON "commerce"."ProductVariant"("businessId");

-- CreateIndex
CREATE INDEX "ProductVariant_businessId_productId_idx" ON "commerce"."ProductVariant"("businessId", "productId");

-- CreateIndex
CREATE INDEX "ProductVariant_businessId_agreementId_idx" ON "commerce"."ProductVariant"("businessId", "agreementId");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_businessId_id_key" ON "commerce"."ProductVariant"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_businessId_sku_key" ON "commerce"."ProductVariant"("businessId", "sku");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_businessId_barcode_key" ON "commerce"."ProductVariant"("businessId", "barcode");

-- CreateIndex
CREATE INDEX "Purchase_businessId_idx" ON "commerce"."Purchase"("businessId");

-- CreateIndex
CREATE INDEX "Purchase_businessId_branchId_idx" ON "commerce"."Purchase"("businessId", "branchId");

-- CreateIndex
CREATE INDEX "Purchase_businessId_supplierId_idx" ON "commerce"."Purchase"("businessId", "supplierId");

-- CreateIndex
CREATE INDEX "Purchase_businessId_creatorId_idx" ON "commerce"."Purchase"("businessId", "creatorId");

-- CreateIndex
CREATE UNIQUE INDEX "Purchase_businessId_id_key" ON "commerce"."Purchase"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Purchase_businessId_invoiceNumber_key" ON "commerce"."Purchase"("businessId", "invoiceNumber");

-- CreateIndex
CREATE INDEX "PurchaseItem_businessId_idx" ON "commerce"."PurchaseItem"("businessId");

-- CreateIndex
CREATE INDEX "PurchaseItem_businessId_purchaseId_idx" ON "commerce"."PurchaseItem"("businessId", "purchaseId");

-- CreateIndex
CREATE INDEX "PurchaseItem_businessId_variantId_idx" ON "commerce"."PurchaseItem"("businessId", "variantId");

-- CreateIndex
CREATE UNIQUE INDEX "PurchaseItem_businessId_id_key" ON "commerce"."PurchaseItem"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "PurchaseItem_businessId_purchaseId_variantId_key" ON "commerce"."PurchaseItem"("businessId", "purchaseId", "variantId");

-- CreateIndex
CREATE INDEX "Refund_businessId_idx" ON "commerce"."Refund"("businessId");

-- CreateIndex
CREATE INDEX "Refund_businessId_paymentId_idx" ON "commerce"."Refund"("businessId", "paymentId");

-- CreateIndex
CREATE INDEX "Refund_businessId_saleReturnId_idx" ON "commerce"."Refund"("businessId", "saleReturnId");

-- CreateIndex
CREATE UNIQUE INDEX "Refund_businessId_id_key" ON "commerce"."Refund"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Refund_businessId_idempotencyKey_key" ON "commerce"."Refund"("businessId", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Refund_provider_providerReference_key" ON "commerce"."Refund"("provider", "providerReference");

-- CreateIndex
CREATE INDEX "ReturnItem_businessId_idx" ON "commerce"."ReturnItem"("businessId");

-- CreateIndex
CREATE INDEX "ReturnItem_businessId_saleReturnId_idx" ON "commerce"."ReturnItem"("businessId", "saleReturnId");

-- CreateIndex
CREATE INDEX "ReturnItem_businessId_saleItemId_idx" ON "commerce"."ReturnItem"("businessId", "saleItemId");

-- CreateIndex
CREATE UNIQUE INDEX "ReturnItem_businessId_id_key" ON "commerce"."ReturnItem"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ReturnItem_businessId_saleReturnId_saleItemId_key" ON "commerce"."ReturnItem"("businessId", "saleReturnId", "saleItemId");

-- CreateIndex
CREATE INDEX "Sale_businessId_idx" ON "commerce"."Sale"("businessId");

-- CreateIndex
CREATE INDEX "Sale_businessId_branchId_idx" ON "commerce"."Sale"("businessId", "branchId");

-- CreateIndex
CREATE INDEX "Sale_businessId_customerId_idx" ON "commerce"."Sale"("businessId", "customerId");

-- CreateIndex
CREATE INDEX "Sale_businessId_cashierId_idx" ON "commerce"."Sale"("businessId", "cashierId");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_businessId_id_key" ON "commerce"."Sale"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_businessId_invoiceNumber_key" ON "commerce"."Sale"("businessId", "invoiceNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_businessId_idempotencyKey_key" ON "commerce"."Sale"("businessId", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_businessId_cartId_key" ON "commerce"."Sale"("businessId", "cartId");

-- CreateIndex
CREATE INDEX "SaleItem_businessId_idx" ON "commerce"."SaleItem"("businessId");

-- CreateIndex
CREATE INDEX "SaleItem_businessId_saleId_idx" ON "commerce"."SaleItem"("businessId", "saleId");

-- CreateIndex
CREATE INDEX "SaleItem_businessId_variantId_idx" ON "commerce"."SaleItem"("businessId", "variantId");

-- CreateIndex
CREATE INDEX "SaleItem_businessId_agreementId_idx" ON "commerce"."SaleItem"("businessId", "agreementId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleItem_businessId_id_key" ON "commerce"."SaleItem"("businessId", "id");

-- CreateIndex
CREATE INDEX "SaleReturn_businessId_idx" ON "commerce"."SaleReturn"("businessId");

-- CreateIndex
CREATE INDEX "SaleReturn_businessId_saleId_idx" ON "commerce"."SaleReturn"("businessId", "saleId");

-- CreateIndex
CREATE INDEX "SaleReturn_businessId_processorId_idx" ON "commerce"."SaleReturn"("businessId", "processorId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturn_businessId_id_key" ON "commerce"."SaleReturn"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturn_businessId_returnNumber_key" ON "commerce"."SaleReturn"("businessId", "returnNumber");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturn_businessId_idempotencyKey_key" ON "commerce"."SaleReturn"("businessId", "idempotencyKey");

-- CreateIndex
CREATE INDEX "StockMovement_businessId_idx" ON "commerce"."StockMovement"("businessId");

-- CreateIndex
CREATE INDEX "StockMovement_businessId_inventoryId_idx" ON "commerce"."StockMovement"("businessId", "inventoryId");

-- CreateIndex
CREATE INDEX "StockMovement_businessId_actorId_idx" ON "commerce"."StockMovement"("businessId", "actorId");

-- CreateIndex
CREATE UNIQUE INDEX "StockMovement_businessId_id_key" ON "commerce"."StockMovement"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "StockMovement_businessId_eventKey_key" ON "commerce"."StockMovement"("businessId", "eventKey");

-- CreateIndex
CREATE INDEX "AuditLog_businessId_idx" ON "commerce"."AuditLog"("businessId");

-- CreateIndex
CREATE INDEX "AuditLog_businessId_actorId_idx" ON "commerce"."AuditLog"("businessId", "actorId");

-- CreateIndex
CREATE UNIQUE INDEX "AuditLog_businessId_id_key" ON "commerce"."AuditLog"("businessId", "id");

-- CreateIndex
CREATE INDEX "Branch_businessId_idx" ON "commerce"."Branch"("businessId");

-- CreateIndex
CREATE UNIQUE INDEX "Branch_businessId_id_key" ON "commerce"."Branch"("businessId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Branch_businessId_branch_code_key" ON "commerce"."Branch"("businessId", "branch_code");

-- AddForeignKey
ALTER TABLE "commerce"."Brand" ADD CONSTRAINT "Brand_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Cart" ADD CONSTRAINT "Cart_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Cart" ADD CONSTRAINT "Cart_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Cart" ADD CONSTRAINT "Cart_businessId_customerId_fkey" FOREIGN KEY ("businessId", "customerId") REFERENCES "commerce"."Customer"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Cart" ADD CONSTRAINT "Cart_businessId_creatorId_fkey" FOREIGN KEY ("businessId", "creatorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CartItem" ADD CONSTRAINT "CartItem_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CartItem" ADD CONSTRAINT "CartItem_businessId_cartId_fkey" FOREIGN KEY ("businessId", "cartId") REFERENCES "commerce"."Cart"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CartItem" ADD CONSTRAINT "CartItem_businessId_variantId_fkey" FOREIGN KEY ("businessId", "variantId") REFERENCES "commerce"."ProductVariant"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Category" ADD CONSTRAINT "Category_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Category" ADD CONSTRAINT "Category_businessId_parentId_fkey" FOREIGN KEY ("businessId", "parentId") REFERENCES "commerce"."Category"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionAgreement" ADD CONSTRAINT "CommissionAgreement_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionAgreement" ADD CONSTRAINT "CommissionAgreement_businessId_partnerId_fkey" FOREIGN KEY ("businessId", "partnerId") REFERENCES "commerce"."Partner"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionEntry" ADD CONSTRAINT "CommissionEntry_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionEntry" ADD CONSTRAINT "CommissionEntry_businessId_agreementId_fkey" FOREIGN KEY ("businessId", "agreementId") REFERENCES "commerce"."CommissionAgreement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionEntry" ADD CONSTRAINT "CommissionEntry_businessId_saleItemId_fkey" FOREIGN KEY ("businessId", "saleItemId") REFERENCES "commerce"."SaleItem"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionEntry" ADD CONSTRAINT "CommissionEntry_businessId_returnItemId_fkey" FOREIGN KEY ("businessId", "returnItemId") REFERENCES "commerce"."ReturnItem"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionEntry" ADD CONSTRAINT "CommissionEntry_businessId_settlementId_fkey" FOREIGN KEY ("businessId", "settlementId") REFERENCES "commerce"."CommissionSettlement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionSettlement" ADD CONSTRAINT "CommissionSettlement_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionSettlement" ADD CONSTRAINT "CommissionSettlement_businessId_partnerId_fkey" FOREIGN KEY ("businessId", "partnerId") REFERENCES "commerce"."Partner"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionSettlement" ADD CONSTRAINT "CommissionSettlement_businessId_creatorId_fkey" FOREIGN KEY ("businessId", "creatorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Customer" ADD CONSTRAINT "Customer_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Employee" ADD CONSTRAINT "Employee_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Employee" ADD CONSTRAINT "Employee_userId_fkey" FOREIGN KEY ("userId") REFERENCES "commerce"."user"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."EmployeeBranch" ADD CONSTRAINT "EmployeeBranch_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."EmployeeBranch" ADD CONSTRAINT "EmployeeBranch_businessId_employeeId_fkey" FOREIGN KEY ("businessId", "employeeId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."EmployeeBranch" ADD CONSTRAINT "EmployeeBranch_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Expense" ADD CONSTRAINT "Expense_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Expense" ADD CONSTRAINT "Expense_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Expense" ADD CONSTRAINT "Expense_businessId_employeeId_fkey" FOREIGN KEY ("businessId", "employeeId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Expense" ADD CONSTRAINT "Expense_businessId_creatorId_fkey" FOREIGN KEY ("businessId", "creatorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Inventory" ADD CONSTRAINT "Inventory_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Inventory" ADD CONSTRAINT "Inventory_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Inventory" ADD CONSTRAINT "Inventory_businessId_variantId_fkey" FOREIGN KEY ("businessId", "variantId") REFERENCES "commerce"."ProductVariant"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Notification" ADD CONSTRAINT "Notification_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Notification" ADD CONSTRAINT "Notification_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "commerce"."user"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."OutboxEvent" ADD CONSTRAINT "OutboxEvent_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Partner" ADD CONSTRAINT "Partner_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Partner" ADD CONSTRAINT "Partner_linkedBusinessId_fkey" FOREIGN KEY ("linkedBusinessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_saleId_fkey" FOREIGN KEY ("businessId", "saleId") REFERENCES "commerce"."Sale"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_purchaseId_fkey" FOREIGN KEY ("businessId", "purchaseId") REFERENCES "commerce"."Purchase"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_expenseId_fkey" FOREIGN KEY ("businessId", "expenseId") REFERENCES "commerce"."Expense"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_settlementId_fkey" FOREIGN KEY ("businessId", "settlementId") REFERENCES "commerce"."CommissionSettlement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Payment" ADD CONSTRAINT "Payment_businessId_recorderId_fkey" FOREIGN KEY ("businessId", "recorderId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PaymentEvent" ADD CONSTRAINT "PaymentEvent_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PaymentEvent" ADD CONSTRAINT "PaymentEvent_businessId_paymentId_fkey" FOREIGN KEY ("businessId", "paymentId") REFERENCES "commerce"."Payment"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PaymentEvent" ADD CONSTRAINT "PaymentEvent_businessId_refundId_fkey" FOREIGN KEY ("businessId", "refundId") REFERENCES "commerce"."Refund"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Product" ADD CONSTRAINT "Product_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Product" ADD CONSTRAINT "Product_businessId_categoryId_fkey" FOREIGN KEY ("businessId", "categoryId") REFERENCES "commerce"."Category"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Product" ADD CONSTRAINT "Product_businessId_brandId_fkey" FOREIGN KEY ("businessId", "brandId") REFERENCES "commerce"."Brand"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ProductVariant" ADD CONSTRAINT "ProductVariant_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ProductVariant" ADD CONSTRAINT "ProductVariant_businessId_productId_fkey" FOREIGN KEY ("businessId", "productId") REFERENCES "commerce"."Product"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ProductVariant" ADD CONSTRAINT "ProductVariant_businessId_agreementId_fkey" FOREIGN KEY ("businessId", "agreementId") REFERENCES "commerce"."CommissionAgreement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Purchase" ADD CONSTRAINT "Purchase_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Purchase" ADD CONSTRAINT "Purchase_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Purchase" ADD CONSTRAINT "Purchase_businessId_supplierId_fkey" FOREIGN KEY ("businessId", "supplierId") REFERENCES "commerce"."Partner"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Purchase" ADD CONSTRAINT "Purchase_businessId_creatorId_fkey" FOREIGN KEY ("businessId", "creatorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PurchaseItem" ADD CONSTRAINT "PurchaseItem_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PurchaseItem" ADD CONSTRAINT "PurchaseItem_businessId_purchaseId_fkey" FOREIGN KEY ("businessId", "purchaseId") REFERENCES "commerce"."Purchase"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."PurchaseItem" ADD CONSTRAINT "PurchaseItem_businessId_variantId_fkey" FOREIGN KEY ("businessId", "variantId") REFERENCES "commerce"."ProductVariant"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Refund" ADD CONSTRAINT "Refund_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Refund" ADD CONSTRAINT "Refund_businessId_paymentId_fkey" FOREIGN KEY ("businessId", "paymentId") REFERENCES "commerce"."Payment"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Refund" ADD CONSTRAINT "Refund_businessId_saleReturnId_fkey" FOREIGN KEY ("businessId", "saleReturnId") REFERENCES "commerce"."SaleReturn"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ReturnItem" ADD CONSTRAINT "ReturnItem_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ReturnItem" ADD CONSTRAINT "ReturnItem_businessId_saleReturnId_fkey" FOREIGN KEY ("businessId", "saleReturnId") REFERENCES "commerce"."SaleReturn"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."ReturnItem" ADD CONSTRAINT "ReturnItem_businessId_saleItemId_fkey" FOREIGN KEY ("businessId", "saleItemId") REFERENCES "commerce"."SaleItem"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Sale" ADD CONSTRAINT "Sale_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Sale" ADD CONSTRAINT "Sale_businessId_branchId_fkey" FOREIGN KEY ("businessId", "branchId") REFERENCES "commerce"."Branch"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Sale" ADD CONSTRAINT "Sale_businessId_customerId_fkey" FOREIGN KEY ("businessId", "customerId") REFERENCES "commerce"."Customer"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Sale" ADD CONSTRAINT "Sale_businessId_cashierId_fkey" FOREIGN KEY ("businessId", "cashierId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Sale" ADD CONSTRAINT "Sale_businessId_cartId_fkey" FOREIGN KEY ("businessId", "cartId") REFERENCES "commerce"."Cart"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleItem" ADD CONSTRAINT "SaleItem_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleItem" ADD CONSTRAINT "SaleItem_businessId_saleId_fkey" FOREIGN KEY ("businessId", "saleId") REFERENCES "commerce"."Sale"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleItem" ADD CONSTRAINT "SaleItem_businessId_variantId_fkey" FOREIGN KEY ("businessId", "variantId") REFERENCES "commerce"."ProductVariant"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleItem" ADD CONSTRAINT "SaleItem_businessId_agreementId_fkey" FOREIGN KEY ("businessId", "agreementId") REFERENCES "commerce"."CommissionAgreement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleReturn" ADD CONSTRAINT "SaleReturn_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleReturn" ADD CONSTRAINT "SaleReturn_businessId_saleId_fkey" FOREIGN KEY ("businessId", "saleId") REFERENCES "commerce"."Sale"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."SaleReturn" ADD CONSTRAINT "SaleReturn_businessId_processorId_fkey" FOREIGN KEY ("businessId", "processorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."StockMovement" ADD CONSTRAINT "StockMovement_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."StockMovement" ADD CONSTRAINT "StockMovement_businessId_inventoryId_fkey" FOREIGN KEY ("businessId", "inventoryId") REFERENCES "commerce"."Inventory"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."StockMovement" ADD CONSTRAINT "StockMovement_businessId_actorId_fkey" FOREIGN KEY ("businessId", "actorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."AuditLog" ADD CONSTRAINT "AuditLog_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."AuditLog" ADD CONSTRAINT "AuditLog_businessId_actorId_fkey" FOREIGN KEY ("businessId", "actorId") REFERENCES "commerce"."Employee"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."Branch" ADD CONSTRAINT "Branch_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "commerce"."Business"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;
