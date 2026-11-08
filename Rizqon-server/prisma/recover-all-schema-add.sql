-- One-time recovery for the partially applied 20261107092358_all_schema_add.
-- Preserve existing values and indexes; invalid UUIDs abort the transaction.
BEGIN;
ALTER TABLE "commerce"."Employee"
ALTER COLUMN "userId" TYPE UUID USING "userId"::uuid;

-- AlterTable
ALTER TABLE "commerce"."Notification"
ALTER COLUMN "recipientId" TYPE UUID USING "recipientId"::uuid;

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

COMMIT;
